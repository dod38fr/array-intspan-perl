
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 22 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my @expect= ([1,3,'ab'], [6, 7, 'cd'], [8, 13, 'ef'], [14, 14, 'ef']) ;
my $r = Array::IntSpan->new(@expect) ;

diag(Dumper $r) if $trace ;

ok ( defined($r) , 'Array::IntSpan new() works') ;
is_deeply( $r , \@expect, 'new content ok') ;

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
