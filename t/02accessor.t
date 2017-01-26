use strict;
use warnings;

use Test::More tests => 21;
use DateTime;
use DateTime::Fiction::JRRTolkien::Shire;

# A very important day
my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
						      month => 3,
						      day => 25);

# 1-2
is($shire->year, 1419);
is($shire->is_leap_year, 0);

# 3-4
is($shire->month, 3);
is($shire->month_name, 'Rethe');

# 5-7
is($shire->day, 25);
is($shire->mday, 25);
is($shire->day_of_month, 25);

# 8-12
is($shire->wday, 2);
is($shire->dow, 2);
is($shire->day_of_week, 2);
is($shire->day_name, 'Sunday');
is($shire->day_name_trad, 'Sunnendei');

# 13-14
is($shire->holiday, 0);
is($shire->holiday_name, '');

# 15-16
is($shire->day_of_year, 86);
is($shire->doy, 86);

# 17-18
is($shire->week_year, 1419);
is($shire->week_number, 13);

# 19-20
my $time = time;
my $shire2 = DateTime::Fiction::JRRTolkien::Shire->from_epoch(epoch => $time);
is($shire2->epoch, $time);
is(int($shire2->hires_epoch), $time);
# utc_rd_values and utc_rd_as_seconds were tested in the constructor tests

is( $shire->calendar_name(), 'Shire', q<Calendar name is 'Shire'> );
