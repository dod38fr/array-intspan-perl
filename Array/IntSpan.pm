##########################################################################
#
# Array::IntSpan - a Module for handling arrays using IntSpan techniques
#
# Author: Toby Everett
# Revision: 1.01
# Last Change: Fixed Makefile.PL
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

# $Author$
# $Date$
# $Name$
# $Revision$


use strict;
use warnings ;

package Array::IntSpan;

our $VERSION = sprintf "%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/;

sub min { my @a = sort(@_) ; return $a[0] ; }
sub max { my @a = sort(@_) ; return $a[$#a] ; }

sub new {
  my $class = shift;

  my $self = [@_];
  bless $self, $class;
  $self->_check_structure;
  return $self;
}

sub search {
  my ($self,$start,$end,$index) = @_ ;

  # Binary search for the first element that is *entirely* before the
  # element to be inserted
  while ($start < $end) {
    my $mid = int(($start+$end)/2);
    if ($self->[$mid][1] < $index) {
      $start = $mid+1;
    } else {
      $end = $mid;
    }
  }
  return $start ;
}

sub set_range {
  my $self = shift;

  #Test that we were passed appropriate values
  @_ == 3 or @_ == 4 or 
    croak("Array::IntSpan::set_range should be called with 3 values and an optional code ref.");
  $_[0] <= $_[1] or
      croak("Array::IntSpan::set_range called with bad indices: $_[0] and $_[1].");

  not defined $_[3] or ref($_[3]) eq 'CODE' or
    croak("Array::IntSpan::set_range called without 4th parameter set as a sub ref");

  my ($offset,$length,@list) = $self -> get_splice_parms(@_) ;

  #print "splice $offset,$length,@list\n";
  splice @$self, $offset,$length,@list ;

  return $length ? 1 : 0 ;
}

sub check_clobber {
  my $self = shift;

  my @clobbered = $self->clobbered_items(@_) ;

  map {warn "will clobber @$_ with @_\n" ;} @clobbered ;

  return @clobbered ;
}

sub get_range {
  my $self = shift;
  #my($new_elem) = [@_];
  my ($start_elem,$end_elem,$filler) = @_ ;

  my $end_range = $#{$self};
  my $range_size = @$self ; # nb of elements

  # Before we binary search, first check if we fall outside the range
  if ($end_range < 0 or
      $self->[$end_range][1] < $start_elem 
     )
    {
      my @arg = ref($filler) ? ([$start_elem,$end_elem,&$filler]) :
        defined $filler ? ([@_]) : () ;
      push @$self, @arg if @arg;
      return ref($self)->new(@arg) ;
    }

  if ($end_elem < $self->[0][0]) 
    {
      my @arg = ref($filler) ? ([$start_elem,$end_elem,&$filler]) :
        defined $filler ? ([@_]) : () ;
      unshift @$self, @arg  if @arg;
      return ref($self)->new(@arg) ;
    }

  my $start = $self->search(0,     $range_size,  $start_elem) ;
  my $end   = $self->search($start,$range_size,  $end_elem) ;

  my $start_offset = $start_elem - $self->[$start][0] ;
  my $end_offset   = defined $self->[$end] ? 
    $end_elem - $self->[$end][0] : undef ;

#  print "get_range: start $start, end $end, start_offset $start_offset";
#  print ", end_offset $end_offset" if defined $end_offset ;
#  print "\n";

  my @extracted ; 
  my @replaced ;
  my $length = 0;

  # TBD. We may need to compute the length of the "covered" parts
  # and do a splice with the "extracted" part. THis will clobber
  # existing ranges with identical copies.

  # compute a "replaced" array that does not split elements

  # handle the start
  if (defined $filler and $start_offset < 0)
    {
      my $new = ref($filler) ? &$filler : $filler ;
      my $e = min ($end_elem, $self->[$start][0]-1) ;
      # factorize and duplicate array ????
      my @a = ($start_elem, $e, $new) ;
      # don't use \@a, as we don't want @extracted and @replaced to
      # point to the same memory area.
      push @extracted, [ @a ] ;
      push @replaced,  [ @a ] ; 
    }

  if ($self->[$start][0] <= $end_elem)
    {
      my $s = max ($start_elem,$self->[$start][0]) ;
      my $e = min ($end_elem, $self->[$start][1]) ;
      push @extracted, [$s, $e, $self->[$start][2]];
      # must duplicate the start, end variable
      push @replaced, [@{$self->[$start]}] ;
      $length ++ ;
    }

  # handle the middle if any
  if ($start + 1 <= $end -1 )
    {
      #print "adding " ;
      foreach my $idx ( $start+1 .. $end - 1)
        {
          #print "idx $idx," ;
          if (defined $filler)
            {
              my $new = ref($filler) ? &$filler : $filler ;
              my @a = ($self->[$idx-1][1]+1, $self->[$idx][0]-1, $new ) ;
              push @extracted, [@a] ;
              push @replaced,  [@a];
            }
          push @extracted, [@{$self->[$idx]}]; 
          push @replaced , [@{$self->[$idx]}]; 
          $length++ ;
        }
      #print "\n";
    }

  # handle the end
  if ($end > $start)
    {
      if (defined $filler)
        {
          # must add end element filler
          my $end_fill = (not defined $end_offset or $end_offset < 0) ?
            $end_elem :  $self->[$end][0]-1 ;

          my $new = ref($filler) ? &$filler : $filler ;
          my @a = ($self->[$end-1][1]+1, $end_fill, $new) ;
          push @extracted, [@a] ;
          push @replaced, [@a];
        }

      if (defined $end_offset and $end_offset >= 0) 
        {
          push @extracted, [$self->[$end][0],$end_elem, $self->[$end][2]];
          push @replaced , [@{$self->[$end]}]; 
          $length++ ;
        }
    }

  splice (@$self, $start,$length , @replaced) if defined $filler;

  return ref($self)->new(@extracted) ;
}

sub clobbered_items {
  my $self = shift;
  my($range_start,$range_stop,$range_value) = @_;

  my $item = $self->get_range($range_start,$range_stop) ;

  return   grep {$_->[2] ne $range_value} @$item ;
}

sub consolidate {
  my ($self,$bottom,$top) = @_;

  $bottom = 0 unless defined $bottom ;
  $top = $#$self unless defined $top;

  #print "consolidate from $top to $bottom\n";

  for (my $i= $top; $i>0; $i--)
    {
      if ($self->[$i][2] eq $self->[$i-1][2] and
          $self->[$i][0] == $self->[$i-1][1]+1 )
        {
          #print "consolidate splice ",$i-1,",2\n";
          splice @$self, $i-1, 2,
            [$self->[$i-1][0], $self->[$i][1], $self->[$i][2]] ;
        }
    }

}

sub set_consolidate_range {
  my $self = shift;

  #Test that we were passed appropriate values
  @_ == 3 or @_ == 4 or 
    croak("Array::IntSpan::set_range should be called with 3 values and an optional code ref.");
  $_[0] <= $_[1] or
      croak("Array::IntSpan::set_range called with bad indices: $_[0] and $_[1].");

  not defined $_[3] or ref($_[3]) eq 'CODE' or
    croak("Array::IntSpan::set_range called without 4th parameter set as a sub ref");

  my ($offset,$length,@list) = $self -> get_splice_parms(@_) ;

  #print "splice $offset,$length\n";
  splice @$self, $offset,$length,@list ;

  my $b = $offset > 0 ? $offset - 1 : 0 ;
  my $t = $offset+ @list ;
  $t = $#$self if $t > $#$self ;
  $self->consolidate($b , $t ) ;

  return $length ? 1 : 0 ;#($b , $t ) ;

}

sub get_splice_parms {
  my $self = shift;
  my ($start_elem,$end_elem,$value,$spawn) = @_ ;

  my $end_range = $#{$self};
  my $range_size = @$self ; # nb of elements

  #Before we binary search, we'll first check to see if this is an append operation
  if ( $end_range < 0 or 
      $self->[$end_range][1] < $start_elem
     ) {
    return ( $range_size, 0, [$start_elem,$end_elem,$value]);
  }

  # Check for prepend operation
  if ($end_elem < $self->[0][0] ) {
    return ( 0 , 0, [$start_elem,$end_elem,$value]);
  }

  #Binary search for the first element after the last element that is entirely
  #before the element to be inserted (say that ten times fast)
  my $start = $self->search(0,     $range_size,  $start_elem) ;
  my $end   = $self->search($start,$range_size,  $end_elem) ;

  my $start_offset = $start_elem - $self->[$start][0] ;
  my $end_offset   = defined $self->[$end] ? 
    $end_elem - $self->[$end][0] : undef ;

  #print "get_splice_parms: start $start, end $end, start_offset $start_offset";
  #print ", end_offset $end_offset" if defined $end_offset ;
  #print "\n";

  my @modified = () ;

  #If we are here, we need to test for whether we need to frag the
  #conflicting element
  if ($start_offset > 0) {
    my $item = $self->[$start][2] ;
    my $new = defined($spawn) ? $spawn->($item) : $item ;
    push @modified ,[$self->[$start][0], $start_elem-1, $new ];
  }

  push @modified, [$start_elem,$end_elem,$value] if defined $value ;

  #Do a fragmentation check
  if (defined $end_offset 
      and $end_offset >= 0 
      and $end_elem < $self->[$end][1]
     ) {
    my $item = $self->[$end][2] ;
    my $new = defined($spawn) ? $spawn->($item) : $item ;
    push @modified , [$end_elem+1, $self->[$end][1], $new] ;
  }

  my $extra =  (defined $end_offset and $end_offset >= 0) ? 1 : 0 ;

  return ($start, $end - $start + $extra , @modified);
}

sub lookup {
  my $self = shift;
  my($key) = @_;

  my($start, $end) = (0, $#{$self});
  while ($start < $end) {
    my $mid = int(($start+$end)/2);
    if ($self->[$mid]->[1] < $key) {
      $start = $mid+1;
    } else {
      $end = $mid;
    }
  }
  if ($self->[$start]->[0] <= $key && $self->[$start]->[1] >= $key) {
    return $self->[$start]->[2];
  }
  return undef;
}

sub _check_structure {
  my $self = shift;

  return unless $#$self >= 0;

  foreach my $i (0..$#$self) {
    @{$self->[$i]} == 3 or
        croak("Array::IntSpan::_check_structure failed - element $i lacks 3 entries.");
    $self->[$i][0] <= $self->[$i][1] or
        croak("Array::IntSpan::_check_structure failed - element $i has bad indices.");
    if ($i > 0) {
      $self->[$i-1][1] < $self->[$i][0] or
          croak("Array::IntSpan::_check_structure failed - element $i doesn't come after previous element.");
    }
  }
}

#The following code is courtesy of Mark Jacob-Dominus,
sub croak {
  require Carp;
  no warnings 'redefine' ;
  *croak = \&Carp::croak;
  goto &croak;
}

1;

__END__

=head1 NAME

Array::IntSpan - a Module for handling arrays using IntSpan techniques

=head1 SYNOPSIS

  use Array::IntSpan;

  my $foo = Array::IntSpan->new([0, 59, 'F'], [60, 69, 'D'], [80, 89, 'B']);

  print "A score of 84% results in a ".$foo->lookup(84).".\n";
  unless (defined($foo->lookup(70))) {
    print "The grade for the score 70% is currently undefined.\n";
  }

  $foo->set_range(70, 79, 'C');
  print "A score of 75% now results in a ".$foo->lookup(75).".\n";

  $foo->set_range(0, 59, undef);
  unless (defined($foo->lookup(40))) {
    print "The grade for the score 40% is now undefined.\n";
  }

  $foo->set_range(87, 89, 'B+');
  $foo->set_range(85, 100, 'A');
  $foo->set_range(100, 1_000_000, 'A+');

=head1 DESCRIPTION

C<Array::IntSpan> brings the speed advantages of C<Set::IntSpan>
(written by Steven McDougall) to arrays.  Uses include manipulating
grades, routing tables, or any other situation where you have mutually
exclusive ranges of integers that map to given values.

C<Array::IntSpan::IP> is also provided with the distribution.  It lets
you use IP addresses in any of three forms (dotted decimal, network
string, and integer) for the indices into the array.  See the POD for
that module for more information.

=head2 Installation instructions

Standard C<Make::Maker> approach or just copy C<Array/IntSpan.pm> into
C<site/lib/Array/IntSpan.pm> and C<Array/IntSpan/IP.pm> into
C<site/lib/Array/IntSpan/IP.pm>.

=head1 METHODS

=head2 new

The C<new> method takes an optional list of array elements.  The
elements should be in the form C<[start_index, end_index, value]>.
They should be in sorted order and there should be no overlaps.  The
internal method C<_check_structure> will be called to verify the data
is correct.  If you wish to avoid the performance penalties of
checking the structure, you can use C<Data::Dumper> to dump an object
and use that code to reconstitute it.

=head2 set_range

This method takes three parameters - the C<start_index>, the
C<end_index>, and the C<value>.  If you wish to erase a range, specify
C<undef> for the C<value>.  It properly deals with overlapping ranges
and will replace existing data as appropriate.  If the new range lies
after the last existing range, the method will execute in O(1) time.
If the new range lies within the existing ranges, the method executes
in O(n) time, where n is the number of ranges.  The code is not
completely optimized and will make up to three calls to C<splice> if
the new range intersects with existing ranges.  It does not
consolidate contiguous ranges that have the same C<value>.

If you have a large number of inserts to do, it would be beneficial to
sort them first.  Sorting is O(n lg(n)), and since appending is O(1),
that will be considerably faster than the O(n^2) time for inserting n
unsorted elements.

The method returns C<0> if there were no overlapping ranges and C<1>
if there were.

=head2 lookup

This method takes as a single parameter the C<index> to look up.  If there is an appropriate range,
the method will return the associated value.  Otherwise, it returns C<undef>.

=head1 AUTHOR

Toby Everett, teverett@alascom.att.com

=cut

