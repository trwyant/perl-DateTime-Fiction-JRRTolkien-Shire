package main;

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import();
	1;
    } or do {
	print <<eod;
1..0 # skip Test::Pod::Coverage 1.00 or greater required.
eod
	exit;
    };
}

{
    # all_pod_coverage_ok() will load the module for us, but we load it
    # explicitly because we want to tinker with its inheritance.
    require DateTime::Fiction::JRRTolkien::Shire;

    # This hack causes all methods documented by DateTime to be
    # considered documented by DateTime::Fiction::JRRTolkien::Shire.
    # Wish there was a cleaner way.
    local @DateTime::Fiction::JRRTolkien::Shire::ISA = qw{ DateTime };

    all_pod_coverage_ok ({
	    also_private => [
		qr{ \A [[:upper:]\d_]+ \z }smx,
	    ],
	    # The following are DateTime methods not documented by that
	    # module in any way that Pod::Coverage recognizes
	    trustme	=> [
		qr{ \A (?: doq | min | sec ) \z }smx,
		qr{ _0 \z }smx,
		qr{ \A utc_year \z }smx,
		qr{ \A local_rd_as_seconds \z }smx,
		qr{ \A STORABLE_ }smx,	# Storable interface
	    ],
	    coverage_class => 'Pod::Coverage::CountParents'
	});

}

=begin comment

all_pod_coverage_ok ({
	also_private => [ qr{^[[:upper:]\d_]+$}, ],
	coverage_class => 'Pod::Coverage::CountParents'
    });

=end comment

=cut

1;

# ex: set textwidth=72 :
