use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'  => 'Array::IntSpan',
   'VERSION_FROM' => 'lib/Array/IntSpan.pm', # finds $VERSION
   ABSTRACT   => 'Handles arrays of scalars or objects using IntSpan techniques',
   AUTHOR     => 'Dominique Dumont (ddumont@cpan.org)',
);
