##########################################################################
#
# Array::IntSpan::IP - a Module for arrays using IP addresses as indices
#
# Author: Toby Everett
# Revision: 1.01
# Last Change: Makefile.PL
##########################################################################
# Copyright 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
##########################################################################

use strict;
use warnings; 

package Array::IntSpan::Fields;

our $VERSION = sprintf "%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/;

use Array::IntSpan;
use Carp ;

use overload 
  # this emulate the usage of Intspan
  '@{}' => sub { return shift->{range} ;} ,
  # fallback on default behavior for all other operators
  fallback => 1 ;

sub new {
  my $proto = shift ;
  my $class = ref($proto) || $proto;
  my $format = shift ;

  if (ref $format)
    {
      # in fact the user want a regular IntSpan
      return Array::IntSpan->new($format,@_);
    }

  my @temp = @_ ;
  my $self = {};
  bless $self, $class;
  $self->set_format($format) ;

  foreach my $i (@temp) {
    $i->[0] = $self->field_to_int($i->[0]);
    $i->[1] = $self->field_to_int($i->[1]);
  }

  $self->{range}= Array::IntSpan->new(@temp) ;

  return $self;
}

sub set_format
  {
    my ($self,$format) = @_ ;
    croak "Unexpected format : $format" unless 
      $format =~ /^[\d\.]+$/ ;

    $self->{format} = $format ;

    my @array = split /\./, $self->{format} ;
    # store nb of bit and corresponding bit mask
    $self->{fields} = [map { [$_, (1<<$_) -1 ]} @array ] ;
  }

sub int_to_field
  {
    my ($self, $int ) = @_;
    return undef unless defined $int ;
    my @res ;
    foreach my $f (reverse @{$self->{fields}})
      {
        unshift @res, ($f->[0] < 32 ? ($int & $f->[1]) : $int ) ;
        $int >>= $f->[0] ;
      }

    return join('.',@res) ;
  }

sub field_to_int
  {
    my ($self, $field ) = @_;
    return undef unless defined $field ;

    my $f = $self->{fields};
    my @array = split /\./,$field ;

    croak "Expected ",scalar @$f, " fields for format $self->{format}, got ",
      scalar @array," in '$field'\n" unless @array == @$f ;

    my $res = 0 ;

    my $i =0 ;

    while ($i <= $#array)
      {
        my $shift = $f->[$i][0] ;
        croak "Field value $array[$i] too great. Max is $f->[$i][1] (bit width is $shift)"
          if $shift<32 and $array[$i] >> $shift ;

        $res = ($res << $shift) + $array[$i++] ;
      }

    #print "field_to_int: changed $field to $res for format $self->{format}\n";

    return $res ;
  }

sub get_range 
  {
    my $self = shift;
    my $got = $self->{range}->get_range
      (
       $self->field_to_int(shift),
       $self->field_to_int(shift),
       $self->adapt_range_in_cb(@_)
      );

    my $ret = bless {range => $got }, ref($self) ;
    $ret->set_format($self->{format}) ;
    return $ret ;
  }

sub lookup
  {
    my $self = shift;
    my @keys = map {$self->field_to_int($_) } @_ ;
    $self->{range}->lookup(@keys) ;
  }

sub consolidate
  {
    my $self = shift;
    return $self->{range}->consolidate
      (
       $self->field_to_int(shift),
       $self->field_to_int(shift),
       $self->adapt_range_in_cb(@_)
      );
  }


foreach my $method (qw/set_range set_consolidate_range/)
  {
    no strict 'refs' ;
    *$method = sub 
      {
        my $self = shift;

        return $self->{range}->$method
          (
           $self->field_to_int(shift),
           $self->field_to_int(shift),
           shift,
           $self->adapt_range_in_cb(@_)
          );
      };
  }

sub adapt_range_in_cb
  {
    my $self = shift;

    # the callbacks will be called with ($start, $end,$payload) or ($start,$end)
    my @callbacks = @_ ; 

    return map
      {
        my $old_cb = $_; # required for closure to work
        sub
          {
            $old_cb->($self->int_to_field($_[0]),
                      $self->int_to_field($_[1]),
                      $_[2]);
          }
      } @callbacks ;
  }

sub get_element
  {
    my ($self,$idx) = @_;
    my $elt = $self->{range}[$idx] || return () ;
    return ($self->int_to_field($elt->[0]),
            $self->int_to_field($elt->[1]),
            $elt->[2]) ;
  }

1;

__END__

=head1 NAME

Array::IntSpan::IP - a Module for arrays using IP addresses as indices

=head1 SYNOPSIS

  use Array::IntSpan::IP;

  my $foo = Array::IntSpan::IP->new(['123.45.67.0',   '123.45.67.255', 'Network 1'],
                                    ['123.45.68.0',   '123.45.68.127', 'Network 2'],
                                    ['123.45.68.128', '123.45.68.255', 'Network 3']);

  print "The address 123.45.68.37 is on network ".$foo->lookup("\173\105\150\45").".\n";
  unless (defined($foo->lookup(((123*256+45)*256+65)*256+67))) {
    print "The address 123.45.65.67 is not on a known network.\n";
  }

  print "The address 123.45.68.177 is on network ".$foo->lookup("123.45.68.177").".\n";

  $foo->set_range('123.45.68.128', '123.45.68.255', 'Network 4');
  print "The address 123.45.68.177 is now on network ".$foo->lookup("123.45.68.177").".\n";

=head1 DESCRIPTION

C<Array::IntSpan::IP> brings the advantages of C<Array::IntSpan> to IP address indices.  Anywhere
you use an index in C<Array::IntSpan>, you can use an IP address in one of three forms in
C<Array::IntSpan::IP>.  The three accepted forms are:

=over 4

=item Dotted decimal

This is the standard human-readable format for IP addresses.  The conversion checks that the
octets are in the range 0-255.  Example: C<'123.45.67.89'>.

=item Network string

A four character string representing the octets in network order. Example: C<"\173\105\150\131">.

=item Integer

A integer value representing the IP address. Example: C<((123*256+45)*256+67)*256+89> or
C<2066563929>.

=back

Note that the algorithm has no way of distinguishing between the integer values 1000 through 9999
and the network string format.  It will presume network string format in these instances.  For
instance, the integer C<1234> (representing the address C<'0.0.4.210'>) will be interpreted as
C<"\61\62\63\64">, or the IP address C<'49.50.51.52'>.  This is unavoidable since Perl does not
strongly type integers and strings separately and there is no other information available to
distinguish between the two in this situation.  I do not expect that this will be a problem in
most situations. Most users will probably use dotted decimal or network string notations, and even
if they do use the integer notation the likelyhood that they will be using the addresses
C<'0.0.3.232'> through C<'0.0.39.15'> as indices is relatively low.

=head1 METHODS

=head2 ip_as_int

The class method C<Array::IntSpan::IP::ip_as_int> takes as its one parameter the IP address in one
of the three formats mentioned above and returns the integer notation.

=head1 AUTHOR

Toby Everett, teverett@alascom.att.com

=cut

