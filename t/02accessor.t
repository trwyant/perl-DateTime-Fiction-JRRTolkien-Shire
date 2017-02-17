use strict;
use warnings;

use Test::More tests => 36;
use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;

# A very important day
my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
						      month => 3,
						      day => 25,
						      locale => 'en-US',
						  );

# 1-2
is($shire->year, 1419);
is($shire->is_leap_year, 0);

# 3-4
is($shire->month, 3);
is($shire->month_name, 'Rethe');

# 5-10
is($shire->day, 25);
is($shire->mday, 25);
is($shire->day_of_month, 25);
is( $shire->day_0(), 24 );
is( $shire->mday_0(), 24 );
is( $shire->day_of_month_0(), 24 );

# 11-15
is($shire->wday, 2);
is($shire->dow, 2);
is($shire->day_of_week, 2);
is($shire->day_name, 'Sunday');
is($shire->day_name_trad, 'Sunnendei');

# 16-17
is($shire->holiday, 0);
is($shire->holiday_name, '');

# 18-19
is($shire->day_of_year, 86);
is($shire->doy, 86);

# 20-21
is($shire->week_year, 1419);
is($shire->week_number, 13);

# 22-27
is( $shire->quarter(), 1 );
is( $shire->quarter_0(), 0 );
is( $shire->quarter_name(), '1st quarter' );
is( $shire->quarter_abbr(), 'Q1' );
is( $shire->day_of_quarter(), 86 );
is( $shire->day_of_quarter_0(), 85 );

# 28-29
my $time = time;
my $shire2 = DateTime::Fiction::JRRTolkien::Shire->from_epoch(epoch => $time);
is($shire2->epoch, $time);
is(int($shire2->hires_epoch), $time);
# utc_rd_values and utc_rd_as_seconds were tested in the constructor tests

# 30
is( $shire->calendar_name(), 'Shire', q<Calendar name is 'Shire'> );

# Aliased to DateTime
# 31-33
is( $shire->time_zone()->name(), 'floating', q<Time zone is 'floating'> );
is( $shire->time_zone_long_name(),
    'floating', q<Time zone long name is 'floating'> );
is( $shire->time_zone_short_name(),
    'floating', q<Time zone short name is 'floating'> );

# Holidays

my $shire_h = DateTime::Fiction::JRRTolkien::Shire->new(
    year	=> 1419,
    holiday	=> 3,
);
# 34-36
is( $shire_h->holiday(), 3, q<Holiday number of Midyear's day> );
is( $shire_h->holiday_name(), q<Midyear's day>,
    q<Holiday name of Midyear's day> );
is( $shire_h->week_number(), 0, q<Week number of Midyear's day> );

# ex: set textwidth=72 :
