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

package Array::IntSpan;

our $VERSION = sprintf "%d.%03d", q$Revision$ =~ /(\d+)\.(\d+)/;

sub new {
  my $class = shift;

  my $self = [@_];
  bless $self, $class;
  $self->_check_structure;
  return $self;
}

sub search {
  my ($self,$start,$end,$index) = @_ ;

  while ($start < $end) {
    my $mid = int(($start+$end)/2);
    if ($self->[$mid]->[1] < $index) {
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
  @_ == 3 or croak("Array::IntSpan::set_range should be called with three values.");
  $_[0] <= $_[1] or
      croak("Array::IntSpan::set_range called with bad indices: $_[0] and $_[1].");

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

sub clobbered_items {
  my $self = shift;
  my($new_elem) = [@_];

  my $end_set = $#$self;

  #Before we binary search, we'll first check to see if this is an append operation
  if ($self->[$end_set][1] < $new_elem->[0]) {
    return () ;
  }

  #Binary search for the first element after the last element that is entirely
  #before the element to be inserted (say that ten times fast)
  my $start_elem = $self->search(0,$end_set,$new_elem->[0]) ;

  # now $start contains the index of the element to create or the
  # first element that will be displaced

  #If there is no conflict between this element and the new element, we are home free
  if ($start_elem > $end_set || $new_elem->[1] < $self->[$start_elem][0]) {
    return ();
  }

  my @clobbered ;

  # check if new element is a subset of start_elem
  if ($self->[$start_elem][0] <= $new_elem->[0] 
      and $new_elem->[1] <= $self->[$start_elem][1]
      and $self->[$start_elem][2] ne $new_elem->[2] ) {
    return ([@$new_elem[0,1],$self->[$start_elem][2]]) ;
  }

  #If we are here, we need to test for whether we need to frag the conflicting element
  if ($self->[$start_elem][0] < $new_elem->[0] 
      and $self->[$start_elem][2] ne $new_elem->[2] ) {
    # split the old element in 2. The 2nd part starts at the same
    # place than the start of new_elem
    push @clobbered, [$new_elem->[0], $self->[$start_elem][1], $self->[$start_elem][2]];
    $start_elem ++ ;
  }

  return @clobbered if $start_elem > $end_set;

  #Then we go a searching for where to end this insert

  my $end_elem =  $self->search($start_elem,$end_set+1,$new_elem->[1]) ;
  my $value = $new_elem->[2] ;

  #Do a fragmentation check
  my $end_frag ;
  if (defined $self->[$end_elem] 
      and $self->[$end_elem][0] <= $new_elem->[1]
      and $self->[$end_elem][1] > $new_elem->[1]
      and $self->[$end_elem][2] ne $value) {
      # split the old element in 2. The 1st part ends at the same
      # place than the end of new_elem
    $end_frag = [$self->[$end_elem][0],$new_elem->[1], $self->[$end_elem][2]];
    $end_elem -- ;
  }

  # if new element does not go over end_elem, skip this one
  $end_elem -- if $self->[$end_elem][0] > $new_elem->[1] ;

  push @clobbered, grep {$_->[2] ne $value} @$self[$start_elem .. $end_elem] ;

  push @clobbered, $end_frag if defined $end_frag ;

  # this is a string comparison. We may want to use a deep data
  # structure comparison like Struct::Compare.
  return @clobbered ;
}

sub consolidate {
  my $self = shift;

  my @old = @$self;  # backup
  @$self = () ; # fresh start

  my $oldv ;
  map {
    if (not defined $oldv or $oldv ne $_->[2])
      {
        push @$self, $_ ;
        $oldv = $_->[2] ;
      }
    else
      {
        $self->[$#$self][1]=$_->[1] ;
      }
  } @old ;

}

sub set_consolidate_range {
  my $self = shift;
  my ($start,$end,$value, $clobber) = @_ ;
  $clobber = 1 unless defined $clobber ;

  my ($offset,$length,@list) = $self -> get_splice_parms($start,$end,$value) ;

  my @clobbered = grep {defined $_}
    @$self[$offset .. $offset+$length-1] if $length ;

  if (@clobbered and not $clobber)
    {
      my $str = join("\t\n", map ("will clobber @$_ with $start,$end,$value\n" ,
                                  @clobbered )) ;
      die "error :".$str ;
    }

  splice @$self, $offset,$length,@list ;

  # merge above
  my $above = $offset+ scalar(@list) - 1 ;
  #print "offset $offset length $length  above $above\n";
  if ($above < $#$self  # substitution occured before last element
      and $self->[$above][1] == $self->[$above+1][0] -1 # check for adjacent ranges
      and $self->[$above][2] eq $self->[$above+1][2])
    {
      splice @$self, $above , 2, 
        [$self->[$above][0], $self->[$above+1][1], $self->[$above][2] ] ;
    }

  # merge below
  if ($offset  # there was a subsitution after element 0
      and $self->[$offset-1][1]+1 == $self->[$offset][0] # check for adjacent ranges
      and $self->[$offset-1][2] eq $self->[$offset][2])  # check for equal values
    {
      splice @$self, $offset-1 , 2, 
        [$self->[$offset-1][0], $self->[$offset][1], $self->[$offset][2] ] ;
    }

  return $length ? 1 : 0 ;

}

sub get_splice_parms {
  my $self = shift;
  my($new_elem) = [@_];

  my($start, $end) = (0, $#{$self});

  #Before we binary search, we'll first check to see if this is an append operation
  if ($self->[$end]->[1] < $new_elem->[0]) {
    $start = $end+1;
  } else {
    #Binary search for the first element after the last element that is entirely
    #before the element to be inserted (say that ten times fast)
    $start = $self->search($start,$end,$new_elem->[0]) ;
  }

  # now $start contains the index of the element to create or the
  # first element that will be displaced

  #If there is no conflict between this element and the new element, we are home free
  if ($start > $#{$self} || $new_elem->[1] < $self->[$start]->[0]) {
    # we should compare value between $new_elem->[2] and $self->[$start]->[2]

    return ( $start, 0, $new_elem);

  } else {
    #If we are here, we need to test for whether we need to frag the conflicting element
    if ($self->[$start]->[0] < $new_elem->[0]) {
      # split the old element in 2. The 2nd part starts at the same
      # place than the start of new_elem
      splice(@{$self}, $start, 1,
          [$self->[$start]->[0], $new_elem->[0]-1, $self->[$start]->[2]],
          [$new_elem->[0], $self->[$start]->[1], $self->[$start]->[2]]);
      $start++;
    }

    #Then we go a searching for where to end this insert
    my $start_elem = $start;

    $start =  $self->search($start,$#{$self}+1,$new_elem->[1]) ;

    #Do a fragmentation check
    if (defined $self->[$start] and $self->[$start]->[0] <= $new_elem->[1]) {
      if ($self->[$start]->[1] > $new_elem->[1]) {
        # split the old element in 2. The 1st part ends at the same
        # place than the end of new_elem
        splice(@{$self}, $start, 1,
            [$self->[$start]->[0], $new_elem->[1], $self->[$start]->[2]],
            [$new_elem->[1]+1, $self->[$start]->[1], $self->[$start]->[2]]);
      }
      $start++;
    }

    #Then we splice in the new element.  If the value is undef, we just remove the old stuff
    if (defined $new_elem->[2]) {
      return ($start_elem, $start-$start_elem, $new_elem);
    } else {
      return ($start_elem, $start-$start_elem);
    }
  }
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

  foreach my $i (0..$#{$self}) {
    @{$self->[$i]} == 3 or
        croak("Array::IntSpan::_check_structure failed - element $i lacks 3 entries.");
    $self->[$i]->[0] <= $self->[$i]->[1] or
        croak("Array::IntSpan::_check_structure failed - element $i has bad indices.");
    if ($i > 0) {
      $self->[$i-1]->[1] < $self->[$i]->[0] or
          croak("Array::IntSpan::_check_structure failed - element $i doesn't come after previous element.");
    }
  }
}

#The following code is courtesy of Mark Jacob-Dominus,

sub croak {
  require Carp;
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

C<Array::IntSpan> brings the speed advantages of C<Set::IntSpan> (written by Steven McDougall) to
arrays.  Uses include manipulating grades, routing tables, or any other situation where you have
mutually exclusive ranges of integers that map to given values.

C<Array::IntSpan::IP> is also provided with the distribution.  It lets you use IP addresses in any
of three forms (dotted decimal, network string, and integer) for the indices into the array.  See
the POD for that module for more information.

=head2 Installation instructions

Standard C<Make::Maker> approach or just copy C<Array/IntSpan.pm> into
C<site/lib/Array/IntSpan.pm> and C<Array/IntSpan/IP.pm> into C<site/lib/Array/IntSpan/IP.pm>.

=head1 METHODS

=head2 new

The C<new> method takes an optional list of array elements.  The elements should be in the form
C<[start_index, end_index, value]>.  They should be in sorted order and there should be no
overlaps.  The internal method C<_check_structure> will be called to verify the data is correct.
If you wish to avoid the performance penalties of checking the structure, you can use
C<Data::Dumper> to dump an object and use that code to reconstitute it.

=head2 set_range

This method takes three parameters - the C<start_index>, the C<end_index>, and the C<value>.  If
you wish to erase a range, specify C<undef> for the C<value>.  It properly deals with overlapping
ranges and will replace existing data as appropriate.  If the new range lies after the last
existing range, the method will execute in O(1) time.  If the new range lies within the existing
ranges, the method executes in O(n) time, where n is the number of ranges.  The code is not
completely optimized and will make up to three calls to C<splice> if the new range intersects with
existing ranges.  It does not consolidate contiguous ranges that have the same C<value>.

If you have a large number of inserts to do, it would be beneficial to sort them first.  Sorting
is O(n lg(n)), and since appending is O(1), that will be considerably faster than the O(n^2) time
for inserting n unsorted elements.

The method returns C<0> if there were no overlapping ranges and C<1> if there were.

=head2 lookup

This method takes as a single parameter the C<index> to look up.  If there is an appropriate range,
the method will return the associated value.  Otherwise, it returns C<undef>.

=head1 AUTHOR

Toby Everett, teverett@alascom.att.com

=cut

