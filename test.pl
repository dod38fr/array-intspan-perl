
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 112 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my @expect= ([1,3,'ab'],[6,9,'cd']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;

foreach my $a ( [2,0], [3,0], [4,1], [4,1], [6,1], [9,1] , [10,2])
  {
    is($r->search(0,2,$a->[0]), $a->[1], "search(0,2,$a->[0], $a->[1] )");
  }

foreach my $a ( 
               [[0, 0,'bc'],[0,0,[0, 0,'bc']]],
               [[0, 1,'bc'],[0,1,[0, 1,'bc'],[2,3,'ab']]],
               [[0, 3,'bc'],[0,1,[0, 3,'bc']]],
               [[0, 4,'bc'],[0,1,[0, 4,'bc']]],
               [[0, 5,'bc'],[0,1,[0, 5,'bc']]],
               [[0, 6,'bc'],[0,2,[0, 6,'bc'],[7,9,'cd']]],
               [[0, 9,'bc'],[0,2,[0, 9,'bc']]],
               [[0,10,'bc'],[0,2,[0,10,'bc']]],
               [[1, 3,'bc'],[0,1,[1, 3,'bc']]],
               [[1, 2,'bc'],[0,1,[1, 2,'bc'],[3, 3,'ab']]],
               [[2, 2,'bc'],[0,1,[1, 1,'ab'],[2, 2,'bc'],[3,3,'ab']]],
               [[2, 3,'bc'],[0,1,[1, 1,'ab'],[2, 3,'bc']]],
               [[2, 5,'bc'],[0,1,[1, 1,'ab'],[2, 5,'bc']]],
               [[2, 8,'bc'],[0,2,[1, 1,'ab'],[2, 8,'bc'],[9,9,'cd']]],
               [[2, 9,'bc'],[0,2,[1, 1,'ab'],[2, 9,'bc']]],
               [[2,10,'bc'],[0,2,[1, 1,'ab'],[2,10,'bc']]],
               [[4, 4,'bc'],[1,0,[4, 4,'bc']]],
               [[5, 6,'bc'],[1,1,[5, 6,'bc'],[7,9,'cd']]],
               [[5, 9,'bc'],[1,1,[5, 9,'bc']]],
               [[5,11,'bc'],[1,1,[5,11,'bc']]],
               [[6, 6,'bc'],[1,1,[6, 6,'bc'],[7,9,'cd']]],
               [[6, 9,'bc'],[1,1,[6, 9,'bc']]],
               [[7, 9,'bc'],[1,1,[6, 6,'cd'],[7,9,'bc']]],
               [[9,11,'bc'],[1,1,[6, 8,'cd'],[9,11,'bc']]],
               [[10,11,'bc'],[2,0,[10,11,'bc']]],
              )
  {
    my @r = $r->get_splice_parms(@{$a->[0]}) ;
    is_deeply(\@r, $a->[1], "get_splice_parms @{$a->[0]}") || diag(Dumper \@r);
  }


my @range = (12,14,'ef') ;
is ($r->set_range(@range),0, 'set_range after') ;
push @expect, [@range] ;
is_deeply( $r , \@expect ) ;

is($r->lookup(13), 'ef', 'lookup 13') ;
diag(Dumper $r) if $trace ;

@range = (8,13,'ef') ;
is ($r->set_range(@range),1, "set_range @range") ;
is(@$r, 4) || diag(Dumper $r);
diag(Dumper $r) if $trace ;


diag(Dumper $r) if $trace ;

$r->consolidate ;


is(@$r, 3, 'consolidate') || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (5,5,'cd') ;
isnt ($r->set_consolidate_range(@range),1, "set_consolidate_range @range") ;

is(@$r, 3) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (13,16,'ef') ;
is ($r->set_consolidate_range(@range),1, "set_consolidate_range @range") ;

is(@$r, 3) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (24,26,'ef') ;
is ($r->set_consolidate_range(@range),0, "set_consolidate_range @range") ;

is(@$r, 4 ) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (19,22,'ef') ;
is ($r->set_consolidate_range(@range),0, "set_consolidate_range @range") ;

is(@$r, 5) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (23,23,'efa') ;
is ($r->set_consolidate_range(@range),0, "set_consolidate_range @range") ;

is(@$r,  6) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (23,23,'ef') ;
is ($r->set_consolidate_range(@range),1, "set_consolidate_range @range") ;

is(@$r, 4) || diag(Dumper $r);
is($r->lookup(26),'ef') ;
diag(Dumper $r) if $trace ;

@range = (17,18,'efb') ;
is ($r->set_consolidate_range(@range),0, "set_consolidate_range @range") ;

is(@$r, 5) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (17,18,'ef') ;
is ($r->set_consolidate_range(@range),1, "set_consolidate_range @range") ;

is(@$r, 3) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

@range = (8,12,undef) ;
is ($r->set_consolidate_range(@range),1, "set_consolidate_range 8 12 undef") ;

is(@$r, 3) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

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
    is(@$r, 3, 'check nb of items in range') || diag(Dumper $r);
    is_deeply($new, $t->[1], "get_range @{$t->[0]}") || 
      diag("From ".Dumper($r)."Got ".Dumper ($new)) ;
  }

foreach my $t (
               [[32,34,'oops'],[]],
               [[4,4,'oops'],[]],
               [[24,26,'oops'],[[24,26,'ef']]],
               [[24,29,'oops'],[[24,26,'ef']]],
               [[10,16,'oops'],[[13,16,'ef']]],
               [[20,24,'oops'],[[20,24,'ef']]],
               [[0,9,'oops'],[[1,3,'ab'],[5,7,'cd']]],
               [[0,6,'oops'],[[1,3,'ab'],[5,6,'cd']]],
              )
  {
    my @clobbered = $r->clobbered_items(@{$t->[0]}) ;
    is(@$r, 3, 'check nb of items in range') || diag(Dumper $r);
    is_deeply(\@clobbered, $t->[1], "clobbered_items @{$t->[0]}") || 
      diag(Dumper \@clobbered) ;
  }


foreach my $t (
               [[32,34,'oops'],[]],
               [[4,4,'oops'],[]],
               [[24,26,'oops'],[[24,26,'ef']]],
               [[24,29,'oops'],[[24,26,'ef']]],
               [[10,16,'oops'],[[13,16,'ef']]],
               [[20,24,'oops'],[[20,24,'ef']]],
               [[0,9,'oops'],[[1,3,'ab'],[5,7,'cd']]],
               [[0,6,'oops'],[[1,3,'ab'],[5,6,'cd']]],
              )
  {
    my @clobbered = $r->clobbered_items(@{$t->[0]}) ;
    is(@$r, 3, 'check nb of items in range') || diag(Dumper $r);
    is_deeply(\@clobbered, $t->[1], "clobbered_items @{$t->[0]}") || 
      diag(Dumper \@clobbered) ;
  }

my $r2 = Array::IntSpan->new() ;


is(@{$r2->get_range(1,10)}, 0 , 'get on empty set works');
is(@{$r2->set_range(1,10,'ab')}, 0 , 'set on empty set works');
is(@{$r2->set_range(1,10,undef)}, 0 , 'go back to empty set');
is(@$r2, 0 , 'set is empty');
is(@{$r2->set_consolidate_range(1,10,'ab')}, 0 , 'set_consolidate_range on empty set works');
