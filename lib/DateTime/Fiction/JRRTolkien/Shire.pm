package DateTime::Fiction::JRRTolkien::Shire;

use 5.008004;

use strict;
use warnings;

use Carp ();
use Date::Tolkien::Shire::Data qw{
    __date_to_day_of_year
    __day_of_week
    __day_of_year_to_date
    __format
    __holiday_name
    __holiday_name_to_number
    __is_leap_year
    __month_name
    __month_name_to_number
    __rata_die_to_year_day
    __trad_weekday_name
    __weekday_name
    __year_day_to_rata_die
    GREGORIAN_RATA_DIE_TO_SHIRE
};
use DateTime 0.14;
use DateTime::Fiction::JRRTolkien::Shire::Types ();
use Params::ValidationCompiler ();

# This Conan The Barbarian-style import is because I am reluctant to use
# any magic more subtle than I myself posess; to wit
# namespace::autoclean.
*__t = \&DateTime::Fiction::JRRTolkien::Shire::Types::t;

our $VERSION = '0.22';

use constant DAY_NUMBER_MIDYEARS_DAY	=> 183;

my @delegate_to_dt = qw( hour minute second nanosecond locale );

# This assumes all the values in the info hashref are valid, and doesn't
# do validation However, the day and month parameters will be given
# defaults if not present
sub _recalc_DateTime {
    my ($self, %dt_args) = @_;

    my $shire_rd = __year_day_to_rata_die(
	$self->{year},
	__date_to_day_of_year(
	    $self->{year},
	    $self->{month},
	    $self->{day} || $self->{holiday},
	),
    );

    ( $dt_args{year}, $dt_args{day_of_year} ) = __rata_die_to_year_day(
	$shire_rd - GREGORIAN_RATA_DIE_TO_SHIRE );

    $self->{dt} = DateTime->from_day_of_year( %dt_args );

    return;
}

sub _recalc_Shire {
    my ( $self ) = @_;

    my $greg_rd = ( $self->utc_rd_values() )[0];

    # Because the leap year algorithm is the same in both calendars, I
    # can use __rata_die_to_year_day() on the Gregorian Rata Die day.
    my ( $year, $day_of_year ) = __rata_die_to_year_day(
	$greg_rd + GREGORIAN_RATA_DIE_TO_SHIRE );

    my ( $month, $day ) = __day_of_year_to_date( $year, $day_of_year );

    $self->{year} = $year;
    $self->{leapyear} = __is_leap_year( $year );
    $self->{wday} = __day_of_week( $month, $day );
    if ( $month ) {
	$self->{month} = $month;
	$self->{day} = $day;
	$self->{holiday} = 0;
    } else {
	$self->{holiday} = $day;
	$self->{month} = $self->{day} = 0;
    }

    $self->{recalc} = 0;

    return;
}

# Constructors

{
    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_new',
	name_is_optional	=> 1,
	params			=> {
	    year		=> {
		type		=> __t( 'Year' ),
	    },
	    month		=> {
		type		=> __t( 'Month' ),
		optional	=> 1,
	    },
	    day			=> {
		type		=> __t( 'DayOfMonth' ),
		optional	=> 1,
	    },
	    holiday		=> {
		type		=> __t( 'Holiday' ),
		optional	=> 1,
	    },
	    hour		=> {
		type		=> __t( 'Hour' ),
		default		=> 0,
	    },
	    minute		=> {
		type		=> __t( 'Minute' ),
		default		=> 0,
	    },
	    second		=> {
		type		=> __t( 'Second' ),
		default		=> 0,
	    },
	    nanosecond		=> {
		type		=> __t( 'Nanosecond' ),
		default		=> 0,
	    },
	    time_zone		=> {
		type		=> __t( 'TimeZone' ),
		optional	=> 1,
	    },
	    locale		=> {
		type		=> __t( 'Locale' ),
		optional	=> 1,
	    },
	    formatter		=> {
		type		=> __t( 'Formatter' ),
		optional	=> 1,
	    },
	},
    );

    sub new {
	my ( $class, @args ) = @_;

	my %my_arg = $validator->( @args );

	_check_date( \%my_arg );

	return $class->_new( %my_arg );
    }
}

# For internal use only - no validation.
sub _new {
    my ( $class, %my_arg ) = @_;

	if ( $my_arg{month} ) {
	    $my_arg{month} = __month_name_to_number( $my_arg{month} );
	    $my_arg{day} ||= 1;
	    $my_arg{holiday} = 0;
	} else {
	    $my_arg{holiday} ||= $my_arg{day} || 1;
	    $my_arg{holiday} = __holiday_name_to_number(
		$my_arg{holiday} );
	    $my_arg{month} = $my_arg{day} = 0;
	}
	$my_arg{leapyear} = __is_leap_year( $my_arg{year} );
	$my_arg{wday} = __day_of_week(
	    $my_arg{month},
	    $my_arg{day} || $my_arg{holiday},
	);

	my %dt_arg;
	foreach my $key ( @delegate_to_dt ) {
	    defined $my_arg{$key}
		and $dt_arg{$key} = delete $my_arg{$key};
	}

	my $self = bless \%my_arg, $class;

	$self->_recalc_DateTime(%dt_arg);

	return $self;
}

foreach my $method ( qw{ from_epoch now today from_object } ) {
    no strict qw{ refs };
    *$method = sub {
	my ( $class, @arg ) = @_;

	return bless {
	    dt		=> DateTime->$method( @arg ),
	    recalc	=> 1,
	}, $class;
    }
}

sub last_day_of_month {
    my ( $class, %arg ) = @_;
    $arg{day} = 30; # The shire calendar is nice this way
    return $class->new( %arg );
}

{
    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_from_day_of_year',
	name_is_optional	=> 1,
	params			=> {
	    year		=> {
		type		=> __t( 'Year' ),
	    },
	    day_of_year		=> {
		type		=> __t( 'DayOfYear' ),
	    },
	    hour		=> {
		type		=> __t( 'Hour' ),
		default		=> 0,
	    },
	    minute		=> {
		type		=> __t( 'Minute' ),
		default		=> 0,
	    },
	    second		=> {
		type		=> __t( 'Second' ),
		default		=> 0,
	    },
	    nanosecond		=> {
		type		=> __t( 'Nanosecond' ),
		default		=> 0,
	    },
	    time_zone		=> {
		type		=> __t( 'TimeZone' ),
		optional	=> 1,
	    },
	    locale		=> {
		type		=> __t( 'Locale' ),
		optional	=> 1,
	    },
	    formatter		=> {
		type		=> __t( 'Formatter' ),
		optional	=> 1,
	    },
	},
    );

    sub from_day_of_year {
	my ( $class, @args ) = @_;

	my %arg = $validator->( @args );

	( $arg{month}, $arg{day} ) = __day_of_year_to_date(
	    $arg{year},
	    delete $arg{day_of_year},
	);

	return $class->_new( %arg );
    }
}

sub calendar_name {
    return 'Shire';
}

sub clone { return bless { %{ $_[0] } }, ref $_[0] } # Stolen from DateTime.pm

# Get methods
sub year {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{year};
} # end sub year

sub month {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{month};
} # end sub month

sub month_name {
    my $self = shift;
    return __month_name( $self->month() );
} #end sub month_name

sub day_of_month {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{day};
} # end sub day_of_month

*day = \&day_of_month;	# sub day
*mday = \&day_of_month;	# sub mday

sub day_of_week {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{wday};
} # end sub day_of_week

*wday  = \&day_of_week;	# sub wday
*dow  = \&day_of_week;	# sub dow

sub day_name {
    my ( $self ) = @_;
    return __weekday_name( $self->day_of_week() );
}

sub day_name_trad {
    my ( $self ) = @_;
    return __trad_weekday_name( $self->day_of_week() );
}

sub holiday {
    my ( $self ) = @_;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{holiday};
}

sub holiday_name {
    my ( $self ) = @_;
    return __holiday_name( $self->holiday() );
}

sub is_leap_year {
    my $self = shift;
    $self->_recalc_Shire if $self->{recalc};
    return $self->{leapyear};
}

sub day_of_year {
    my ( $self ) = @_;

    $self->_recalc_Shire if $self->{recalc};

    return __date_to_day_of_year(
	$self->{year},
	$self->{month},
	$self->{day} || $self->{holiday},
    );
}

*doy  = \&day_of_year;	# sub doy

sub week { return ($_[0]->week_year, $_[0]->week_number); }

*week_year  = \&year;	# sub week_year; the shire calendar is nice this way

sub week_number {
    my $self = shift;
    my $yday = $self->day_of_year;

    DAY_NUMBER_MIDYEARS_DAY == $yday
	and return 0;
    DAY_NUMBER_MIDYEARS_DAY < $yday
	and --$yday;

    if ( $self->is_leap_year() ) {
	# In the following, DAY_NUMBER_MIDYEARS_DAY really refers to the
	# Ovelithe, because days greater than Midyear's day were
	# decremented above.
	DAY_NUMBER_MIDYEARS_DAY == $yday
	    and return 0;
	DAY_NUMBER_MIDYEARS_DAY < $yday
	    and --$yday;
    }

    return int(($yday - 1) / 7) + 1;
}

sub quarter {
    my ( $self ) = @_;
    my $week_number = $self->week_number()
	or return 0;
    return POSIX::floor( ( $week_number - 1 ) / 7 ) + 1;
}

# Set methods

{
    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_set',
	name_is_optional	=> 1,
	params			=> {
	    year		=> {
		type		=> __t( 'Year' ),
		optional	=> 1,
	    },
	    month		=> {
		type		=> __t( 'Month' ),
		optional	=> 1,
	    },
	    day			=> {
		type		=> __t( 'DayOfMonth' ),
		optional	=> 1,
	    },
	    holiday		=> {
		type		=> __t( 'Holiday' ),
		optional	=> 1,
	    },
	    hour		=> {
		type		=> __t( 'Hour' ),
		optional	=> 1,
	    },
	    minute		=> {
		type		=> __t( 'Minute' ),
		optional	=> 1,
	    },
	    second		=> {
		type		=> __t( 'Second' ),
		optional	=> 1,
	    },
	    nanosecond		=> {
		type		=> __t( 'Nanosecond' ),
		optional	=> 1,
	    },
	    locale		=> {
		type		=> __t( 'Locale' ),
		optional	=> 1,
	    },
	},
    );

    sub set {
	my ( $self, @args ) = @_;

	my %my_arg = $validator->( @args );

	_check_date( \%my_arg );

	$self->_recalc_Shire if $self->{recalc};

	$my_arg{day}
	    and not $my_arg{month}
	    and not $self->{month}
	    and _croak( 'Need to set month as well as day' );

	if ( $my_arg{month} ) {
	    $my_arg{day} ||= 1;
	    $self->{month} = __month_name_to_number( $my_arg{month} );
	    $self->{holiday} = 0;
	}

	if ( $my_arg{holiday} ) {
	    $self->{holiday} = __holiday_name_to_number( $my_arg{holiday} );
	    $self->{day} = $self->{month} = 0;
	}

	if ( $my_arg{day} ) {
	    $self->{day} = $my_arg{day};
	    $self->{holiday} = 0;
	}

	defined $my_arg{year}
	    and $self->{year} = $my_arg{year};

	$self->{leapyear} = __is_leap_year( $self->{year} );
	$self->{wday} = __day_of_week(
	    $self->{month},
	    $self->{day} || $self->{holiday},
	);

	my %dt_args;
	foreach my $arg ( @delegate_to_dt ) {
	    $dt_args{$arg} = $my_arg{$arg} if defined $my_arg{$arg};
	}

	$self->_recalc_DateTime( %dt_args );

	return $self;
    }
}

{
    my @midnight = (
	hour	=> 0,
	minute	=> 0,
	second	=> 0,
	nanosecond	=> 0,
    );

    my @quarter_start = (
	undef,
	[ holiday	=> 1 ],
	[ month		=> 4,	day	=> 1 ],
	[ holiday	=> 5 ],
	[ month		=> 10,	day	=> 1 ],
    );

    my %handler = (
	year	=> sub {
	    $_[0]->set(
		holiday	=> 1,
		@midnight,
	    );
	},
	quarter	=> sub {
	    my ( $self ) = @_;
	    # This is an extension to the Shire calendar by Tom Wyant.
	    # It has no textual justification whatsoever. Feel free to
	    # pretend it does not exist.
	    if ( my $quarter = $self->quarter() ) {
		# The start of a quarter is tricky since quarters 1 and
		# 3 start on holidays, so we just do a table lookup.
		$self->set(
		    @{ $quarter_start[ $quarter ] },
		    @midnight,
		);
	    } else {
		# Since Midyear's day and the Overlithe are not part of
		# any quarter, we just truncate them to the nearest day.
		$self->{dt}->truncate( to => 'day' );
	    }
	},
	month	=> sub {
	    my ( $self ) = @_;
	    if ( $self->{holiday} ) {
		# since holidays aren't in any month, this means we just
		# lop off any time
		$self->{dt}->truncate( to => 'day' );
	    } else {
		$self->set(
		    day		=> 1,
		    @midnight,
		);
	    }
	},
	week	=> sub {
	    my ( $self ) = @_;
	    if ( $self->{wday} ) {
		# TODO we do not, at this point in the coding, have date
		# arithmetic. So we do it with rata die.
		my ( $year, $day_of_year ) = __rata_die_to_year_day(
		    ( $self->utc_rd_values() )[0] - $self->{wday} + 1 +
		    GREGORIAN_RATA_DIE_TO_SHIRE
		);
		my ( $month, $day ) = __day_of_year_to_date(
		    $year, $day_of_year );
		my %set_arg = (
		    year	=> $year,
		    @midnight,
		);
		if ( $month ) {
		    @set_arg{ qw{ month day } } = ( $month, $day );
		} else {
		    $set_arg{holiday} = $day;
		}
		$self->set( %set_arg );
	    } else {
		$self->{dt}->truncate( to => 'day' );
	    }
	},
    );

    # Weeks in the Shire start on Sterday, but that's what 'week' gives
    # us.
    $handler{local_week} = $handler{week};

    my $validator = Params::ValidationCompiler::validation_for(
	name			=> '_validation_for_truncate',
	name_is_optional	=> 1,
	params			=> {
	    to			=> {
		type		=> __t( 'TruncationLevel' ),
	    },
	},
    );

    sub truncate : method {		## no critic (ProhibitBuiltInHomonyms)
	my ( $self, @args ) = @_;

	my %my_arg = $validator->( @args );

	$self->_recalc_Shire if $self->{recalc};

	if ( my $code = $handler{$my_arg{to}} ) {
	    $code->( $self );
	} else {
	    # only time components will change, DateTime can handle it
	    # fine on its own
	    $self->{dt}->truncate( to => $my_arg{to} );
	}

	return $self;
    }
}

sub set_time_zone {
    my ($self, $tz) = @_;
    $self->{dt}->set_time_zone($tz);
    $self->{recalc} = 1; # in case the day flips when the timezone changes
    return $self;
}

sub strftime {
    my ( $self, @fmt ) = @_;

    return wantarray ?
	( map { __format( $self, $_ ) } @fmt ) :
	__format( $self, $fmt[0] );
}

# Comparison overloads come with DateTime.  Stringify will be our own
use overload('<=>', \&_compare);
use overload('cmp', \&_compare);
use overload('""'  => \&_stringify);

sub _check_date {
    my ( $arg ) = @_;

    if ( $arg->{holiday} ) {
	$arg->{month}
	    and _croak( 'May not specify both holiday and month' );
	$arg->{day}
	    and _croak( 'May not specify both holiday and day' );
    }

    return;
}


sub _compare { return $_[0]->{dt} <=> $_[1]->{dt}; }

sub _stringify {
    splice @_, 1, $#_, '%Ex';
    goto &strftime;
}

sub on_date {
    splice @_, 1, $#_, '%Ex%n%En%Ed';
    goto &strftime;
}

# sub hour; sub minute; sub second; sub nanosecond;
# sub fractional_second; sub millisecond; sub microsecond;
# sub time_zone; sub time_zone_long_name; sub time_zone_short_name
# sub epoch; sub hires_epoch; sub utc_rd_values; sub utc_rd_as_seconds;
foreach my $method ( qw{
    hour minute second nanosecond
    fractional_second millisecond microsecond
    time_zone time_zone_long_name time_zone_short_name
    epoch hires_epoch utc_rd_values utc_rd_as_seconds
} ) {
    no strict qw{ refs };
    *$method = sub {
	my ( $self, @arg ) = @_;
	return $self->{dt}->$method( @arg )
    };
}

sub _croak {
    my @msg = @_;
    Carp::croak( __PACKAGE__ . ": @msg" );
}

1;

__END__

=head1 NAME

DateTime::Fiction::JRRTolkien::Shire - DateTime implementation of the Shire calendar.

=head1 SYNOPSIS

    use DateTime::Fiction::JRRTolkien::Shire;

    # Constructors
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          month => 'Rethe',
                                                          day => 25);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          month => 3,
                                                          day => 25);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->new(year => 1419,
                                                          holiday => '2 Lithe');

    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_epoch(
	epoch = $time);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->today;
	# same as from_epoch(epoch = time());

    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_object(
        object => $some_other_DateTime_object);
    my $shire = DateTime::Fiction::JRRTolkien::Shire->from_day_of_year(
        year => 1420,
        day_of_year => 182);
    my $shire2 = $shire->clone;

    # Accessors
    $year = $shire->year;
    $month = $shire->month;            # 1 - 12, or 0 on a holiday
    $month_name = $shire->month_name;
    $day = $shire->day;                # 1 - 30, or 0 on a holiday

    $dow = $shire->day_of_week;        # 1 - 7, or 0 on certain holidays
    $day_name = $shire->day_name;

    $holiday = $shire->holiday;
    $holiday_name = $shire->holiday_name;

    $leap = $shire->is_leap_year;

    $time = $shire->epoch;
    @rd = $shire->utc_rd_values;

    # Set Methods
    $shire->set(year => 7463,
                month => 5,
                day => 3);
    $shire->set(year => 7463,
                holiday => 6);
    $shire->truncate(to => 'month');

    # Comparisons
    $shire < $shire2;
    $shire == $shire2;

    # Strings
    print "$shire1\n"; # Prints Sunday 25 Rethe 1419

    # On this date in history
    print $shire->on_date;

=head1 DESCRIPTION

Implementation of the calendar used by the hobbits in J.R.R. Tolkien's
exceptional novel The Lord of The Rings, as described in Appendix D of
that book (except where noted).  The calendar has 12 months, each with
30 days, and 5 holidays that are not part of any month.  A sixth
holiday, Overlithe, is added on leap years.  The holiday Midyear's Day
(and the Overlithe on a leap year) is not part of any week, which means
that the year always starts on Sterday.

This module is a follow on to the Date::Tolkien::Shire module, and is
rewritten to support Dave Rolsky and company's DateTime module.  The
DateTime module must be installed for this module to work.  Unlike the
DateTime module, which includes time support, this calendar does not
have any mechanisms for giving a shire time (mostly because I've never
quite figured out what it should look like).  Time is maintained,
however, so that objects can be converted from other calendars to the
shire calendar and then converted back without their time components
being lost.  The same is true of time zones.

=head1 METHODS

Most of these methods mimic their corresponding DateTime methods in
functionality.  For additional information on these methods, see the
DateTime documentation.

=head2 Constructors

=head3 new

 my $dt_ring = DateTime::Fiction::JRRTolkien::Shire->new(
     year   => 1419,
     month  => 3,
     day    => 25,
 );
 my $dt_aa = DateTime::Fiction::JRRTolkien::Shire->new(
     year    => 1419,
     holiday => 3,     # Midyear's day
 );

This method takes a year, month, and day parameter, or a year and
holiday parameter.  The year can be any value.  The month can be
specified with a string giving the name of the month (the same string
that would be returned by month_name, with the first letter capitalized
and the rest in lower case) or by giving the numerical value for the
month, between 1 and 12.  The day should always be between 1 and 30.  If
a holiday is given instead of a day and month, it should be the name of
the holiday as returned by holiday_name (with the first letter of each
word capitalized) or a value between 1 and 6.  The 1 through 6 numbers
map to holidays as follows:

    1 => 2 Yule
    2 => 1 Lithe
    3 => Midyear's Day
    4 => Overlithe      # Leap years only
    5 => 2 Lithe
    6 => 1 Yule

The new method will also take parameters for hour, minute, second,
nanosecond, time_zone and locale.  If given, these parameters will be
stored in case the object is converted to another class that supports
times.

If a day is not given, it will default to 1.  If neither a day or month
is given, the date will default to 2 Yule, the first day of the year.

=head3 from_epoch

     $dts = DateTime::Fiction::JRRTolkien::Shire->from_epoch(
         epoch  => time,
         ...
     );

Same as in DateTime.

=head3 now

    $dts = DateTime::Fiction::JRRTolkien::Shire->now( ... );

Same as in DateTime.  Note that this is equivalent to

    from_epoch( epoch => time() );

=head3 today

    $dts = DateTime::Fiction::JRRTolkien::Shire->today( ... );

Same as in DateTime.

=head3 from_object

    $dts = DateTime::Fiction::JRRTolkien::Shire->from_object(
        object  => $object,
        ...
    );

Same as in DateTime. Takes any other DateTime calendar object and
converts it to a DateTime::Fiction::JRRTolkien::Shire object.

=head3 last_day_of_month

    $dts = DateTime::Fiction::JRRTolkien::Shire->last_day_of_month(
        year    => 1419,
        month   => 3,
        ...
    );

Same as in DateTime.  Like the C<new()> constructor, but it does not
take a day parameter.  Instead, the day is set to 30, which is the last
day of any month in the shire calendar. A holiday parameter should not
be used with this method.  Use L<new()|/new> instead.

=head3 from_day_of_year

    $dts = DateTime::Fiction::JRRTolkien::Shire->from_day_of_year(
        year           => 1419,
        day_of_year    => 86,
        ...
    );

Same as in DateTime.  Gets the date from the given year and day of year,
both of which must be given.  Hour, minute, second, time_zone, etc.
parameters may also be given, and will be passed to the underlying
DateTime object, just like in C<new()>.

=head3 clone

    $dts2 = $dts->clone();

Creates a new Shire object that is the same date (and underlying time)
as the calling object.

=head2 "Get" Methods

=head3 calendar_name

    print $dts->calendar_name(), "\n";

Returns C<'Shire'>.

=head3 year

    print 'Year: ', $dts->year(), "\n";

Returns the year.

=head3 month

    print 'Month: ', $dts->month(), "\n";

Returns the month number, from 1 to 12.  If the date is a holiday, a 0
is returned for the month.

=head3 month_name

    print 'Month name: ', $dts->month_name(), "\n";

Returns the name of the month. If the date is a holiday, an empty
string is returned.

=head3 day_of_month

    print 'Day of month: ', $dts->day_of_month(), "\n";

Returns the day of the current month, from 1 to 30.  If the date is a
holiday, 0 is returned.

=head3 day

Synonym for L<day_of_month()|/day_of_month>.

=head3 mday

Synonym for L<day_of_month()|/day_of_month>.

=head3 day_of_week

    print 'Day of week: ', $dts->day_of_week(), "\n";

Returns the day of the week from 1 to 7.  If the day is not part of
any week (Midyear's Day or the Overlithe), 0 is returned.

=head3 wday

Synonym for L<day_of_week|/day_of_week>.

=head3 dow

Synonym for L<day_of_week|/day_of_week>.

=head3 day_name

    print 'Name of day of week: ', $dts->day_name(), "\n";

Returns the name of the day of the week, or an empty string if the
day is not part of any week.

=head3 day_name_trad

    print 'Traditional name of day of week: ',
        $dts->day_name_trad(), "\n";

Like day_name, but returns the more traditional name of the days of the
week, as defined in Appendix D.

=head3 day_of_year

    print 'Day of year: ', $dts->day_of_year(), "\n";

Returns the day of the year, from 1 to 366

=head3 doy

Synonym for L<day_of_year()|/day_of_year>.

=head3 holiday

    print 'Holiday number: ', $dts->holiday(), "\n";

Returns the holiday number (given in the description of the
L<new()|/new> constructor).  If the day is not a holiday, 0 is returned.

=head3 holiday_name

    print 'Holiday name: ', $dts->holiday_name(), "\n";

Returns the name of the holiday. If the day is not a holiday, an empty
string is returned.

=head3 is_leap_year

    my @ly = ( 'is not', 'is' );
    printf "%d %s a leap year\n", $dts->year(),
        $ly[ $dts->is_leap_year() ];

Returns 1 if the year is a leap year, and 0 otherwise.

Leap years are given the same rule as the Gregorian calendar.  Every
four years is a leap year, except the first year of the century, which
is not a leap year.  However, every fourth century (400 years), the
first year of the century is a leap year (every 4, except every 100,
except every 400).  This is a slight change from the calendar described
in Appendix D, which uses the rule of once every 4 years, except every
100 years (the same as in the Julian calendar).  Given some uncertainty
about how many years have passed since the time in Lord of the Rings
(see note below), and the expectations of most people that the years
match up with what they're used to, I have changed this rule for this
implementation.  However, this does mean that this calendar
implementation is not strictly that described in Appendix D.

=head3 week_year

    print 'The week year is ', $dts->week_year(), "\n";

This is always the same as the year in the shire calendar, but is
present for compatibility with other DateTime objects.

=head3 week_number

    print 'The week number is ', $dts->week_number(), "\n";

Returns the week of the year, or C<0> for days that are not part of any
week: Midyear's day and the Overlithe.

=head3 week

    printf "Year %d; Week number %d\n", $dts->week();

Returns a two element array, where the first is the week_year and the
latter is the week_number.

=head3 epoch

    print scalar gmtime $dts->epoch(), "UT\n";

Returns the epoch of the given object, just like in DateTime.

=head3 hires_epoch

Returns the epoch as a floating point number, with the fractional
portion for fractional seconds.  Functions the same as in DateTime.

=head3 utc_rd_values

Returns the UTC rata die days, seconds, and nanoseconds. Ignores
fractional seconds.  This is the standard method used by other methods
to convert the shire calendar to other calendars.  See the DateTime
documentation for more information.

=head3 utc_rd_as_seconds

Returns the UTC rata die days entirely as seconds.

=head3 on_date

Returns the current day, with day of week if present, and with all names
in full.  If the day has some events that transpired
on it (as defined in Appendix B of the Lord of the Rings), those events
are appended. This can be fun to put in a F<.bashrc> or F<.cshrc>.
Try

    perl -MDateTime::Fiction::JRRTolkien::Shire
      -le 'print DateTime::Fiction::JRRTolkien::Shire->now->on_date;'

=head2 strftime

    print $dts->strftime( '%Ex%n' );

This is a re-implementation imported from
L<Date::Tolkien::Shire::Data|Date::Tolkien::Shire::Data>. It is intended
to be reasonably compatible with the same-named L<DateTime|DateTime>
method, but has some additions. Briefly:

=over

=item %EA

The full traditional weekday name, or C<''> for holidays that are part
of no week.

=item %Ea

The abbreviated traditional weekday name, or C<''> for holidays that are
part of no week.

=item %ED

The L<__on_date_accented()|/__on_date_accented> text for the given date.

You can get a leading C<"\n"> if there was an actual event using
C<'%En%ED'>.

=item %Ed

The L<__on_date()|/__on_date> text for the given date.

You can get a leading C<"\n"> if there was an actual event using
C<'%En%Ed'>. So to mimic L<Date::Tolkien::Shire|Date::Tolkien::Shire>
L<on_date()|Date::Tolkien::Shire/on_date>, use C<'%Ex%n%En%Ed'>.

=item %EE

The full holiday name, or C<''> for non-holidays.

=item %Ee

The abbreviated holiday name, or C<''> for non-holidays.

=item %En

Inserts nothing, but causes the next C<%Ed> or C<%ED> (and B<only> the
next one) to have a C<"\n"> prefixed if there was an actual event on the
date.

=item %Ex

Like C<'%c'>, but without the time of day, and with full names rather
than abbreviations.

=item %{{format||format||format}}

The formatter chooses the first format for normal days (i.e. part of a
month), the second for holidays that are part of a week (i.e. 2 Yule, 1
Lithe, 2 Lithe and 1 Yule), or the third for holidays that are not part
of a week (i.e. Midyear's day and the Overlithe). If the second or third
formats are omitted, the preceding format is used. Trailing C<||>
operators can also be omitted. If you need to specify more than one
right curly bracket or vertical bar as part of a format, separate them
with percent signs (i.e. C<'|%|%|'>.

=back

This method also supports certain Glibc extensions; specifically the
formatting flags C<'-'>, C<'_'>, C<'0'> and C<'^'>, and user-specified
field widths.

See L<__format()|Date::Tolkien::Shire::Data/__format> in
L<Date::Tolkien::Shire::Data|Date::Tolkien::Shire::Data> for full
documentation, which takes precedence over anything said here.

=head2 "Set" Methods

=head3 set

    $dts->set(
        month   => 3,
        day     => 25,
    );

Allows the day, month, and year to be changed.  It takes any parameters
allowed by new constructor, including all those supported by DateTime
and the holiday parameter, except for time_zone.  This is used in much
the same way as new, with the exception that any parameters not given
will be left as is.

All parameters are optional, with the current values inserted if the
values are not supplied.  However, with holidays not falling in any
month, it is recommended that a day and month always be given together.
Otherwise, unanticipated results may occur.

As in the L<new()|/new> constructor, time parameters have no effect on
the shire dates returned.  However, they are maintained in case the
object is converted to another calendar which supports time.

=head3 truncate

    $dts->truncate( to => 'day' );

Like the corresponding L<DateTime|DateTime> method, with the following
exceptions:

If the date is a holiday, truncation to C<'month'> is equivalent to
truncation to C<'day'>, since holidays are not part of any month.

Similarly, if the date is Midyear's day or the Overlithe, truncation to
C<'week'>, C<'local_week'>, or C<'quarter'> is equivalent to truncation
to C<'day'>, since these holidays are not part of any week (or, by
extension, quarter).

The week in the Shire calendar begins on Sterday, so both C<'week'> and
C<'local_week'> truncate to that day.

There is no textual justification for quarters, but they are in the
L<DateTime|DateTime> interface, so I rationalized the concept the same
way the Shire calendar rationalizes weeks. If you are not interested in
non-canonical functionality, please ignore anything involving quarters.

=head3 set_time_zone

    $dts->set_time_zone( 'UTC' );

Just like in DateTime. This method has no effect on the shire calendar,
but be stored with the date if it is ever converted to another calendar
with time support.

=head2 Comparisons and Stringification

All comparison operators should work, just as in DateTime.  In addition,
all C<DateTime::Fiction::JRRTolkien::Shire> objects will interpolate
into a string representing the date when used in a double-quoted string.

=head1 DURATIONS AND DATE MATH

Durations and date math (other than comparisons) are not supported at
present on this module (patches are always welcome).  If this is needed,
there are a couple of options.  If working with dates within epoch time,
the dates can be converted to epoch time, the math done, and then
converted back.  Regardless of the dates, the shire objects can also be
converted to DateTime objects, the math done with the DateTime class,
and then the DateTime object converted back to a Shire object.

=head1 NOTE: YEAR CALCULATION

L<http://www.glyphweb.com/arda/f/fourthage.html> references a letter sent
by Tolkien in 1958 in which he estimates approximately 6000 years have
passed since the War of the Ring and the end of the Third Age.  (Thanks
to Danny O'Brien from sending me this link).  I took this approximate as
an exact amount and calculated back 6000 years from 1958.  This I set as
the start of the 4th age (1422 S.R.).  Thus the fourth age begins in our
B.C 4042.

According to Appendix D of the Lord of the Rings, leap years in the
hobbits'
calendar are every 4 years unless it is the turn of the century, in which
case it is not a leap year. Our calendar (Gregorian) uses every 4 years
unless it's 100 years unless its 400 years.  So, if no changes have been
made to the hobbits' calendar since the end of the third age, their
calendar would be about 15 days further behind ours now then when the
War of the Ring took place.  Implementing this seemed to me to go
against Tolkien's general habit of converting dates in the novel to our
equivalents to give us a better sense of time.  My thought, at least
right now, is that it is truer to the spirit of things for years to line
up, and for Midyear's day to still be approximately on the summer
solstice.  So instead, I have modified Tolkien's description of the
hobbit calendar so that leap years occur once every 4 years unless it's
100 years unless it's 400 years, so as it matches the Gregorian calendar
in that regard.  These 100 and 400 year intervals occur at different
times in the two calendars, so there is not a one to one correspondence
of days regardless of years.  However, the variations follow a 400 year
cycle.

=head1 AUTHOR

Tom Braun <tbraun@pobox.com>

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 Tom Braun. All rights reserved.

Copyright (C) 2017 Thomas R. Wyant, III

The calendar implemented on this module was created by J.R.R. Tolkien,
and the copyright is still held by his estate.  The license and
copyright given herein applies only to this code and not to the
calendar itself.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text
of the licenses in the LICENSES directory included with this module.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 SUPPORT

Support on this module may be obtained by emailing me. However, I am
not a developer on the other classes in the DateTime project. For
support on them, please see the support options in the DateTime
documentation.

=head1 BIBLIOGRAPHY

Tolkien, J. R. R. I<Return of the King>.  New York: Houghton Mifflin
Press, 1955.

L<http://www.glyphweb.com/arda/f/fourthage.html>

=head1 SEE ALSO

The DateTime project documentation (perldoc DateTime, datetime@perl.org
mailing list, or L<http://datetime.perl.org/>).

=cut

1;

# ex: set textwidth=72 :
