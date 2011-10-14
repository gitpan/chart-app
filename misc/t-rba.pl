#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use Data::Dumper;
use HTTP::Response;
use Perl6::Slurp ('slurp');
use App::Chart::Suffix::RBA;



{
  my $resp = HTTP::Response->new();
  my $content = slurp ("$ENV{HOME}/chart/samples/rba/exchange-rates.html.2");
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Suffix::RBA::threeday_parse ($resp);
  print Data::Dumper->new([$h],['h'])->Indent(1)->Dump;
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}
{
  my $resp = HTTP::Response->new();
  my $content = slurp (<~/chart/samples/rba/hist-exch.html>);
  $resp->content($content);
  $resp->content_type('text/html');
  my $h = App::Chart::Suffix::RBA::historical_parse ($content);
  print Dumper (\$h);
  exit 0;
}

{
  my $h = App::Chart::Suffix::RBA::historical_info;
  print Dumper (\$h);
  exit 0;
}


{
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/rba/2007.xls');
  # my $content = slurp ($ENV{'HOME'}.'/chart/samples/rba/F11hist.2007.xls');
  print "file ",length($content),"\n";
  require Spreadsheet::ParseExcel;
  my $t = time();
  my $excel = Spreadsheet::ParseExcel::Workbook->Parse (\$content);
  print "took ",time()-$t,"\n";

  my $worksheets = $excel->{Worksheet};
  print "worksheets ",scalar(@$worksheets),"\n";
  my $sheet = $excel->Worksheet (0);
  my ($minrow, $maxrow) = $sheet->RowRange;
  my ($mincol, $maxcol) = $sheet->ColRange;
  print "rows ($minrow, $maxrow) cols ($mincol, $maxcol)\n";
  exit 0;
}

{
  my $resp = HTTP::Response->new();
#  my $content = slurp ($ENV{'HOME'}.'/chart/samples/rba/2003to2007.xls');
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/rba/2007.xls');
  print "file ",length($content),"\n";
  $resp->content ($content);
  my $h = App::Chart::Suffix::RBA::xls_parse ($resp);
  print Dumper (\$h);
  exit 0;
}

{
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/rba/F11hist.xls');
  print "file ",length($content),"\n";
  $resp->content ($content);
  my $h = App::Chart::Suffix::RBA::monthly_parse ($resp, '1983-01-01');
  print Dumper (\$h);
  exit 0;
}



{
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/rba/exchange_rates.html');
  $resp->content($content);
  print Dumper (App::Chart::Suffix::RBA::threeday_parse($resp));
  exit 0;
}


# hard coding this table is a bit unfortunate, but the html doesn't include
# currency symbols, just the names
#
my %fiveday_name_to_symbol =
  ('Click for earlier rates'     => 0,             # skip this
   'United States dollar'        => 'AUDUSD.RBA',
   'Japanese yen'                => 'AUDJPY.RBA',
   'European euro'               => 'AUDEUR.RBA',
   'South Korean won'            => 'AUDKRW.RBA',
   'New Zealand dollar'          => 'AUDNZD.RBA',
   'Chinese renminbi'            => 'AUDCNY.RBA',
   'UK pound sterling'           => 'AUDGBP.RBA',
   'New Taiwan dollar'           => 'AUDTWD.RBA',
   'Singapore dollar'            => 'AUDSGD.RBA',
   'Indonesian rupiah'           => 'AUDIDR.RBA',
   'Hong Kong dollar'            => 'AUDHKD.RBA',
   'Malaysian ringgit'           => 'AUDMYR.RBA',
   'Swiss franc'                 => 'AUDCHF.RBA',
   'Special Drawing Right'       => 'AUDSDR.RBA',
   'Trade-weighted Index (9am)'  => 0,             # skip this
   'Trade-weighted Index (Noon)' => 0,             # skip this
   'Trade-weighted Index (4pm)'  => 'AUDTWI.RBA'); # use this

