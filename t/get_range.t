
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 36 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my @expect= ([1,3,'ab'],[5, 7, 'cd'], [13, 26, 'ef']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;


foreach my $t (
               [[32,34],[]],
               [[4,4],[]],
               [[24,26],[[24,26,'ef']]],
               [[24,29],[[24,26,'ef']]],
               [[10,16],[[13,16,'ef']]],
               [[20,24],[[20,24,'ef']]],
               [[0,9],[[1,3,'ab'],[5,7,'cd']]],
               [[0,6],[[1,3,'ab'],[5,6,'cd']]],
              )
  {
    my $new = $r->get_range(@{$t->[0]}) ;
    is_deeply($new, $t->[1], "get_range @{$t->[0]}") || 
      diag("From ".Dumper($r)."Got ".Dumper ($new)) ;
    is(@$r, 3, 'check nb of items in range') || diag(Dumper $r);
  }

my $fill = 'fi' ;
foreach my $t (
               [[32,34],[[32,34,$fill]]],
               [[0,0],[[0,0,$fill]]],
               [[4,4],[[4,4,$fill]]],
               [[24,26],[[24,26,'ef']]],
               [[24,29],[[24,26,'ef'],[27,29,$fill]]],
               [[10,16],[[10,12,$fill],[13,16,'ef']]],
               [[20,24],[[20,24,'ef']]],
               [[0,9],[[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7,'cd'],[8,9,$fill]]],
               [[0,6],[[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,6,'cd']]],
              )
  {
    my $new = $r->get_range(@{$t->[0]}, $fill) ;
    is_deeply($new, $t->[1], "get_range with fill @{$t->[0]}") || 
      diag("From ".Dumper($r)."Got ".Dumper ($new)) ;
    is(@$r, 3, 'check nb of items in filled range') || diag(Dumper $r);
  }
