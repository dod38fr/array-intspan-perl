use strict ;
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 40 ;
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
               [
                [32,34],
                [[32,34,$fill]],
                [@expect,[32,34,$fill]]
               ],
               [
                [0,0],
                [[ 0, 0,$fill]],
                [[0,0,$fill],@expect]
               ],
               [
                [4,4],
                [[ 4, 4,$fill]],
                [[1,3,'ab'],[4,4,$fill],[5, 7, 'cd'], [13, 26, 'ef']]
               ],
               [
                [24,26],
                [[24,26,'ef' ]],
                [@expect]
               ],
               [
                [24,29],
                [[24,26,'ef'],[27,29,$fill]],
                [[1,3,'ab'],[5, 7, 'cd'], [13, 26, 'ef'],[27,29,$fill]]
               ],
               [
                [10,16],
                [[10,12,$fill],[13,16,'ef']],
                [[1,3,'ab'],[5, 7, 'cd'], [10,12,$fill],[13, 26, 'ef']]
               ],
               [
                [20,24],
                [[20,24,'ef']],
                [@expect]
               ],
               [
                [0,9],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7,'cd'],[8,9,$fill]],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7,'cd'],[8,9,$fill], [13, 26, 'ef']]
               ],
               [
                [0,6],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,6,'cd']],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5, 7, 'cd'], [13, 26, 'ef']]
               ],
              )
  {
    my $r2 = Array::IntSpan->new(@expect) ;
    my $old = Dumper($r2) ;
    my $new = $r2->get_range(@{$t->[0]}, $fill) ;
    is_deeply($new, $t->[1], "get_range with fill @{$t->[0]}") || 
      diag("From ".$old."Got ".Dumper ($new)) ;
    is_deeply($r2, $t->[2], "range after get_range with fill") || 
      diag("From ".$old."Expected ".Dumper($t->[2])."Got ".Dumper ($r2)) ;
  }

my $sub = sub { "sfi"};
$fill = &$sub ;

foreach my $t (
               [[30,39],[[30,39,$fill]],[@expect,[30,39,$fill]]],
               [
                [0,9],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7,'cd'],[8,9,$fill]],
                [[0,0,$fill],[1,3,'ab'],[4,4,$fill],[5,7, 'cd'],[8,9,$fill], [13, 26, 'ef']]
               ],
              )
  {
    my $r2 = Array::IntSpan->new(@expect) ;
    my $old = Dumper($r2) ;
    my $new = $r2->get_range(@{$t->[0]}, $sub) ;
    is_deeply($new, $t->[1], "get_range with fill @{$t->[0]}") || 
      diag("From ".$old."Got ".Dumper ($new)) ;
    is_deeply($r2, $t->[2], "range after get_range with sub") || 
      diag("From ".$old."Expected ".Dumper($t->[2])."Got ".Dumper ($r2)) ;
  }
