#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;

my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 7463, month => 1, day => 8);

is($shire->on_date, "Sunday 8 Afteryule 7463\n\nThe Company of the Ring reaches Holland, 1419.\n");
