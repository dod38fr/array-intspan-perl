
use warnings FATAL => qw(all);
use ExtUtils::testlib;
use Test::More tests => 7 ;
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
is(@$r, 4) || diag(Dumper $r);
diag(Dumper $r) if $trace ;

