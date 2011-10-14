#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More tests => 62;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Download;


is (App::Chart::Download::timestamp_to_timet
    (App::Chart::Download::timet_to_timestamp(0)),
    0,
    'time_t 0 to timestamp and back');

is (App::Chart::Download::date_parse_to_iso('2007-10-26'),  '2007-10-26');
is (App::Chart::Download::date_parse_to_iso('26 Oct 2007'), '2007-10-26');

is (App::Chart::Download::Decode_Date_EU_to_iso ('26 Oct 2007'), '2007-10-26');
is (App::Chart::Download::Decode_Date_EU_to_iso ('26/10/2007'),  '2007-10-26');
is (App::Chart::Download::Decode_Date_EU_to_iso ('2/10/2007'),   '2007-10-02');
is (App::Chart::Download::Decode_Date_EU_to_iso ('2/1/2007'),    '2007-01-02');
is (App::Chart::Download::Decode_Date_EU_to_iso ('2jan2007'),    '2007-01-02');
is (App::Chart::Download::Decode_Date_EU_to_iso ('31 dec 99'),   '1999-12-31');
# per CAS.pm
is (App::Chart::Download::Decode_Date_EU_to_iso ('25.01.00'),    '2000-01-25');

is (App::Chart::Download::Decode_Date_YMD_to_iso ('080908'),    '2008-09-08');

is (App::Chart::Download::iso_to_tdate_floor('1970-01-05'),  0);
is (App::Chart::Download::iso_to_tdate_floor('1970-01-06'),  1);
is (App::Chart::Download::iso_to_tdate_floor('1970-01-02'), -1);

is (App::Chart::Download::trim_decimals('1234',2),   '1234');
is (App::Chart::Download::trim_decimals('1.1',2),    '1.1');
is (App::Chart::Download::trim_decimals('1.230',2),  '1.23');
is (App::Chart::Download::trim_decimals('1.2345',2), '1.2345');

ok (App::Chart::Download::str_is_zero('0'));
ok (App::Chart::Download::str_is_zero('0.'));
ok (App::Chart::Download::str_is_zero('.0'));
ok (App::Chart::Download::str_is_zero('0.0'));
ok (App::Chart::Download::str_is_zero('0.0000'));
ok (! App::Chart::Download::str_is_zero('0.5000'));
ok (! App::Chart::Download::str_is_zero('1'));
ok (! App::Chart::Download::str_is_zero('10'));
ok (! App::Chart::Download::str_is_zero('01'));
ok (! App::Chart::Download::str_is_zero('000.5'));
ok (! App::Chart::Download::str_is_zero('000.5000'));

{
  my @lines;
  @lines = App::Chart::Download::split_lines("\nx\n");
  is_deeply (\@lines, ['x']);
  @lines = App::Chart::Download::split_lines("\nx\r\ny");
  is_deeply (\@lines, ['x','y']);
  @lines = App::Chart::Download::split_lines("\nx  \r\ny");
  is_deeply (\@lines, ['x','y']);
  @lines = App::Chart::Download::split_lines("\nx  \r\ny  ");
  is_deeply (\@lines, ['x','y']);
}

is (App::Chart::Download::cents_to_dollars('1'), '0.01');
is (App::Chart::Download::cents_to_dollars('12'), '0.12');
is (App::Chart::Download::cents_to_dollars('599'), '5.99');
is (App::Chart::Download::cents_to_dollars('0.5'), '0.005');
is (App::Chart::Download::cents_to_dollars('.5'), '0.005');
is (App::Chart::Download::cents_to_dollars('.05'), '0.0005');
is (App::Chart::Download::cents_to_dollars('12.5'), '0.125');
is (App::Chart::Download::cents_to_dollars('12.35'), '0.1235');
is (App::Chart::Download::cents_to_dollars('123.456'), '1.23456');

is (App::Chart::Download::crunch_price(' 1.25'), '1.25');

is (App::Chart::Download::crunch_number(' 0'), '0');
is (App::Chart::Download::crunch_number('000'), '0');
is (App::Chart::Download::crunch_number('000.00'), '0.00');
is (App::Chart::Download::crunch_number('005'), '5');
is (App::Chart::Download::crunch_number('0.5'), '0.5');
is (App::Chart::Download::crunch_number('00.5'), '0.5');
is (App::Chart::Download::crunch_number('000.5'), '0.5');
is (App::Chart::Download::crunch_number('0.05'), '0.05');
is (App::Chart::Download::crunch_number('00.05'), '0.05');
is (App::Chart::Download::crunch_number('000.05'), '0.05');
is (App::Chart::Download::crunch_number('10.05'), '10.05');
is (App::Chart::Download::crunch_number('100.05'), '100.05');
is (App::Chart::Download::crunch_number('1000.05'), '1000.05');

App::Chart::Database->delete_symbol ('FOO.TEST');

is_deeply ([ App::Chart::Download::all_combinations([]) ],
           [ [] ]);
is_deeply ([ App::Chart::Download::all_combinations([1]) ],
           [ [], [1] ]);
is_deeply ([ App::Chart::Download::all_combinations([1,2]) ],
           [ [],[1],[2],[1,2] ]);
is_deeply ([ App::Chart::Download::all_combinations([1,2,3]) ],
           [ [],[1],[2],[1,2], [3],[1,3],[2,3],[1,2,3] ]);

is (App::Chart::Download::tdate_end_of_month
    (App::Chart::ymd_to_tdate_ceil (1970,1,1)),
    App::Chart::ymd_to_tdate_floor (1970,1,31));
is (App::Chart::Download::tdate_end_of_month
    (App::Chart::ymd_to_tdate_floor (1970,1,31)),
    App::Chart::ymd_to_tdate_floor (1970,1,31));

exit 0;
