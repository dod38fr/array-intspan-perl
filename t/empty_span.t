
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 6 ;
use Data::Dumper ;

use Array::IntSpan;

my $trace = shift || 0 ;

my $r2 = Array::IntSpan->new() ;

ok($r2, 'empty span created') ;

is(@{$r2->get_range(1,10)}, 0 , 'get on empty set works');
is(@{$r2->set_range(1,10,'ab')}, 0 , 'set on empty set works');
is(@{$r2->set_range(1,10,undef)}, 0 , 'go back to empty set');
is(@$r2, 0 , 'set is empty');
is(@{$r2->set_consolidate_range(1,10,'ab')}, 0 , 'set_consolidate_range on empty set works');
