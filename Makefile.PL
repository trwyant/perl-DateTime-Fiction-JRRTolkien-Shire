use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME         => 'DateTime::Fiction::JRRTolkien::Shire',
	      VERSION_FROM => 'lib/DateTime/Fiction/JRRTolkien/Shire.pm',
	      PREREQ_PM    => { 'DateTime' => 0.14 },
	      ABSTRACT     => 'Implementation of the Shire Calendar from JRR Tolkien\'s classic, "Lord of the Rings".',
	      AUTHOR       => 'Tom Braun <tbraun@pobox.com>',
	      );
