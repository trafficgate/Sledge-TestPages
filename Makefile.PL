use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::TestPages',
    'VERSION_FROM' => 'lib/Sledge/TestPages.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
