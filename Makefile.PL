use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'  => 'Array::IntSpan',
  'VERSION_FROM' => 'Array/IntSpan.pm', # finds $VERSION
  'PM' => {
    'Array/IntSpan.pm' => '$(INST_LIBDIR)/IntSpan.pm',
    'Array/IntSpan/IP.pm' => '$(INST_LIBDIR)/IntSpan/IP.pm',
  },
);
