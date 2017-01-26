package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
    Test::Spelling->import();
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
Braun
dow
doy
durations
Houghton
mday
merchantability
Mifflin
Overlithe
Rolsky
rata
Sterday
th
wday
Wyant
