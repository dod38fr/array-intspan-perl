
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More qw/no_plan/; #tests => 3 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my @expect= ([1,3,'ab'],[6,9,'cd']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;


my @range = (12,14,'ef') ;
is ($r->set_range(@range),0, 'set_range after') ;
push @expect, [@range] ;
is_deeply( $r , \@expect ) ;

is($r->lookup(13), 'ef', 'lookup 13') ;
diag(Dumper $r) if $trace ;

@range = (8,13,'ef') ;
is ($r->set_range(@range),1, "set_range @range") ;

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

