# Reserve Bank of Australia setups.

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

package App::Chart::Suffix::RBA;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Calc;
use List::Util qw(min max);
use Set::IntSpan::Fast;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::Sympred;
use App::Chart::Latest;
use App::Chart::TZ;
use App::Chart::Weblink;

use constant DEBUG => 0;


# Not yet using Finance::Quote::RBA as 


my $pred = App::Chart::Sympred::Suffix->new ('.RBA');
App::Chart::TZ->sydney->setup_for_symbol ($pred);
App::Chart::setup_source_help
  ($pred, __p('manual-node','Reserve Bank of Australia'));

use constant RBA_COPYRIGHT_URL =>
  'http://www.rba.gov.au/copyright/index.html';


#------------------------------------------------------------------------------
# weblink - home page

App::Chart::Weblink->new
  (pred => $pred,
   name => __('_RBA Home Page'),
   desc => __('Open web browser at the Reserve Bank of Australia home page'),
   url  => 'http://www.rba.gov.au');


#------------------------------------------------------------------------------
# three day page
#
# This uses the rates at:
#
use constant RBA_EXCHANGE_URL =>
  'http://www.rba.gov.au/statistics/frequency/exchange-rates.html';
use constant RBA_EXCHANGE_URL_DAYS => 3;

sub threeday_available_date_time {
  return (App::Chart::Download::weekday_date_after_time
          (16,0, App::Chart::TZ->sydney),
          '16:00:00');
}

sub threeday_available_tdate {
  my ($iso, $time) = threeday_available_date_time();
  return App::Chart::Download::iso_to_tdate_floor ($iso);
}

sub threeday_parse {
  my ($resp) = @_;
  my @data = ();
  my $h = { url        => RBA_EXCHANGE_URL,
            copyright  => RBA_COPYRIGHT_URL,
            source     => __PACKAGE__,
            resp       => $resp,
            cover_pred => $pred,
            data       => \@data };

  my $content = $resp->decoded_content(raise_error=>1);

  # mung <tr id="USD"> to add <td>USD</td> so it appears in the TableExtract
  $content =~ s{<tr>}{<tr><td></td>}ig;
  $content =~ s{(<tr +id="([^"]*)">)}{$1<td>$2</td>}ig;

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['Units of foreign currency per'],
     slice_columns => 0);
  $te->parse($content);
  my $ts = $te->first_table_found();
  if (! $ts) { die "RBA: html table not found\n"; }

  my $rows = $ts->rows();
  my $lastrow = $#$rows;
  my $lastcol = $#{$rows->[0]};

  # date like "03 Sep 2007"
  my @dates;
  foreach my $c (2 .. $lastcol) {
    $dates[$c] = App::Chart::Download::Decode_Date_EU_to_iso($rows->[0]->[$c]);
  }
  $h->{'lo_date'} = List::Util::minstr (grep {defined} @dates);

  foreach my $r (1 .. $lastrow) {
    my $row = $rows->[$r];

    my $symbol = $row->[0] // next;
    $symbol =~ s/_.*//; # _4pm on TWI
    $symbol = "AUD$symbol.RBA";

    my $name = $row->[1];
    $name =~ s/ \(4pm\)$//; # 4pm on TWI

    foreach my $c (2 .. $lastcol) {
      my $rate = $row->[$c];
      # bank holiday columns have "BANK HOLIDAY" with one letter per row or
      # blank which comes through as undef, skip those
      next if ! Scalar::Util::looks_like_number($rate);

      push @data, { symbol    => $symbol,
                    name      => $name,
                    date      => $dates[$c],
                    last_time => '16:00:00',
                    close     => $rate,
                    currency  => substr($symbol,3,3),
                  };
    }
  }

  return $h;
}

#------------------------------------------------------------------------------
# latest quotes

App::Chart::LatestHandler->new
  (pred => $pred,
   url_tags_key => 'RBA-latest',
   proc => \&latest_download,
   available_date_time => \&threeday_available_date_time);

sub latest_download {
  my ($symbol_list) = @_;

  App::Chart::Download::status (__('RBA past three days'));
  my $resp = App::Chart::Download->get (RBA_EXCHANGE_URL,
                                       url_tags_key => 'RBA-latest');
  App::Chart::Download::write_latest_group (threeday_parse ($resp));
}


#------------------------------------------------------------------------------
# historical xls page
#
# This downloads and parses up the page:
#
use constant RBA_HISTORICAL_PAGE_URL =>
  'http://www.rba.gov.au/statistics/hist-exchange-rates/index.html';
#
# which offers various xls files for past rates.

sub historical_info {
  require App::Chart::Pagebits;
  return App::Chart::Pagebits::get
    (name      => __('RBA historical page'),
     url       => RBA_HISTORICAL_PAGE_URL,
     key       => 'rba-historical',
     freq_days => 1,
     parse     => \&historical_parse);
}

sub historical_parse {
  my ($content) = @_;

  # Eg.
  # <a href="/statistics/hist-exchange-rates/2007-2009.xls"
  # target="_blank" title="Link, opening in a new window, to XLS file.">
  # 2007 to 2009</a> <span class="nonHtml">[XLS 227K]</span>
  #
  # because the size is outside the link it doesn't really suit
  # HTML::LinkExtor / HTML::Parser etc
  #
  my @files;
  while ($content =~ m%href=\"([^\"]*[0-9][0-9][0-9][0-9]\.xls)\"
                       (.*\n){0,3}
                       .*\[XLS\s*([0-9.]+)([MK])
                      %igmx) {
    my $link = $1;
    my $size = $3;
    my $size_units = uc($4);

    if ($size_units eq 'K') { $size *= 1_000 }
    if ($size_units eq 'M') { $size *= 1_000_000 }

    my $uri = URI->new_abs($link, RBA_HISTORICAL_PAGE_URL);

    # eg per above: 2003-2007.xls
    #      or just: 2007.xls
    $link =~ /([0-9][0-9][0-9][0-9])((to|-)([0-9][0-9][0-9][0-9]))?\.xls$/
      or die "RBA: oops, unrecognised link: $link";
    my $lo_year = $1;
    my $hi_year = $4 || $1;

    push @files, { url     => $uri->as_string,
                   cost    => $size,
                   lo_year => $lo_year,
                   hi_year => $hi_year,
                 };
  }
  return { files => \@files };
}


#-----------------------------------------------------------------------------
# download - historical monthly prices
#
# This parses the monthly rates spreadsheet file from the
# RBA_HISTORICAL_PAGE_URL page above,
#
#     http://www.rba.gov.au/statistics/tables/xls/f11hist-1969-2009.xls
#
# but only the part from 1983 back is wanted since there's daily data for
# 1983 onwards.

my %monthly_fx_to_currency = ( 'JY'   => 'JPY', # japanese yen
                               # 'USD'
                               # 'EUR'
                               'SKW'  => 'KRW', # korean won
                               # 'NZD'
                               'CR'   => 'CNY', # chinese renminbi
                               'UKPS' => 'GBP', # british pound sterling
                               'NTD'  => 'TWD', # taiwan dollar
                               'SD'   => 'SGD', # singapore dollar
                               'IR'   => 'IDR', # indonesian rupiah
                               # 'HKD'
                               'MR'   => 'MYR', # malaysian ringgit
                               # 'SDR'          # special drawing right
                               # 'TWI'          # trade weighted index
                             );

sub monthly_parse {
  my ($resp, $stop_iso) = @_;
  my $content = $resp->decoded_content(raise_error=>1);

  my @data = ();
  my $h = { source    => __PACKAGE__,
            copyright => RBA_COPYRIGHT_URL,
            data      => \@data };

  require Spreadsheet::ParseExcel;
  require Spreadsheet::ParseExcel::Utility;

  my $excel = Spreadsheet::ParseExcel::Workbook->Parse (\$content);
  my $sheet = $excel->Worksheet (0);
  if (DEBUG) { print "Sheet (of ",$excel->{'SheetCount'},"): ",
                 $sheet->{'Name'},"\n"; }

  my ($minrow, $maxrow) = $sheet->RowRange;
  my ($mincol, $maxcol) = $sheet->ColRange;
  if (DEBUG) { print "  rows $minrow-$maxrow cols $mincol-$maxcol\n"; }

  # heading row repeats the filename "F11HIST.XLS" and then the currencies
  # in columns as say "FXRJY"
  my $heading_row = List::Util::first {
    my $cell = $sheet->Cell($_,$mincol);
    $cell && $cell->Value eq 'F11HIST.XLS' }
    ($minrow .. $maxrow)
      or die "RBA monthly: headings not found";
  if (DEBUG) { print "  heading row $heading_row\n"; }

  my @currencies = map {
    my $cell = $sheet->Cell($heading_row,$_);
    my $currency = $cell ? $cell->Value : '';
    $currency =~ s/^FXR//;
    ($monthly_fx_to_currency{$currency} || $currency)
  } ($mincol .. $maxcol);
  if (DEBUG) { print "  currencies ",scalar @currencies,
                 " ",join(' ',@currencies),"\n"; }

  my %currency_started;

 ROW: foreach my $row ($heading_row+1 .. $maxrow) {
    my $datecell = $sheet->Cell($row,0) or next;
    # seen 'Numeric', but presumably 'Date' is ok
    if ($datecell->{'Type'} ne 'Numeric'
        && $datecell->{'Type'} ne 'Date') {
      next;  # skip blanks at end
    }
    my $month = Spreadsheet::ParseExcel::Utility::ExcelFmt
      ('yyyy-mm-dd', $datecell->{'Val'}, $excel->{'Flg1904'});

    foreach my $col ($mincol+1 .. $maxcol) {
      my $currency = $currencies[$col-$mincol] or next;
      my $ratecell = $sheet->Cell($row,$col) or next;
      my $rate = $ratecell->Value;

      # avoid empty records until the start of data for a given currency is
      # reached
      if (! $rate && ! $currency_started{$currency}) { next; }

      my $symbol = "AUD$currency.RBA";
      $currency_started{$currency} = 1;
      foreach my $date (iso_weekdays_in_month ($month)) {
        if ($date gt $stop_iso) { last ROW; }
        push @data, { symbol   => $symbol,
                      currency => $currency,
                      date     => $date,
                      close    => $rate,
                    };
      }
    }
  }

  return $h;
}

# return a list of ISO date strings like '2008-09-08' which is all the
# weekdays in the month of ISO date $str
sub iso_weekdays_in_month {
  my ($str) = @_;
  my ($lo_year, $lo_month, undef) = App::Chart::iso_to_ymd ($str);
  my ($hi_year, $hi_month, undef) = Date::Calc::Add_Delta_YM
    ($lo_year,$lo_month,1, 0,1);
  my $lo = App::Chart::ymd_to_tdate_ceil ($lo_year, $lo_month, 1);
  my $hi = App::Chart::ymd_to_tdate_ceil ($hi_year, $hi_month, 1) - 1;
  return map { App::Chart::tdate_to_iso($_) } ($lo .. $hi);
}


#------------------------------------------------------------------------------
# xls parse
#
# This parses xls spreadsheet files like
#
#     http://www.rba.gov.au/Statistics/HistoricalExchangeRates/2003to2007.xls
#
# The files aren't huge (500k upwards) but there's a lot of cells, which
# makes Spreadsheet::ParseExcel fairly slow and eat up about 50Mb of core
# (as of version 0.32), even before getting to the $h data build.

sub xls_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content(raise_error=>1);

  my @data = ();
  my $h = { source    => __PACKAGE__,
            copyright => RBA_COPYRIGHT_URL,
            data      => \@data };

  require Spreadsheet::ParseExcel;
  require Spreadsheet::ParseExcel::Utility;

  my $excel = Spreadsheet::ParseExcel::Workbook->Parse (\$content);
  my $sheet = $excel->Worksheet (0);
  if (DEBUG) { print "Sheet: ",$sheet->{'Name'},"\n"; }

  my ($minrow, $maxrow) = $sheet->RowRange;
  my ($mincol, $maxcol) = $sheet->ColRange;

  # heading row "DAILY 4PM" and the currencies in columns
  my $heading_row = List::Util::first {
    my $cell = $sheet->Cell($_,$mincol);
    $cell && $cell->Value eq 'DAILY 4PM' }
    ($minrow .. $maxrow)
      or die "RBA historical: headings not found";
  if (DEBUG) { print "  heading row $heading_row\n"; }

  foreach my $row ($heading_row+1 .. $maxrow) {
    my $datecell = $sheet->Cell($row,$mincol) or next;
    $datecell->{'Type'} eq 'Date' or next;  # skip blanks
    my $date = Spreadsheet::ParseExcel::Utility::ExcelFmt
      ('yyyy-mm-dd', $datecell->{'Val'}, $excel->{'Flg1904'});

    foreach my $col ($mincol+1 .. $maxcol) {
      my $cell = $sheet->Cell($row,$col)
        or next;  # skip lots of blanks
      my $rate = $cell->Value
        or next;  # skip lots of blanks
      my $currency = $sheet->Cell($heading_row,$col)->Value;
      push @data, { symbol   => "AUD$currency.RBA",
                    currency => $currency,
                    date     => $date,
                    close    => $rate,
                  };
    }
  }

  return $h;
}



#------------------------------------------------------------------------------
# data downloading

App::Chart::DownloadHandler->new
  (name   => __('RBA'),
   pred   => $pred,
   proc   => \&download,
   # backto => \&backto,
   available_date_time => \&threeday_available_date_time);

sub download {
  my ($symbol_list) = @_;

  my $lo_tdate = App::Chart::Download::start_tdate_for_update (@$symbol_list);
  my $hi_tdate = threeday_available_tdate();
  if (DEBUG) { print "RBA wanting $lo_tdate to $hi_tdate\n"; }

  if ($hi_tdate - $lo_tdate + 1 <= RBA_EXCHANGE_URL_DAYS) {
    App::Chart::Download::status (__('RBA past three days'));
    my $resp = App::Chart::Download->get (RBA_EXCHANGE_URL);
    my $h = threeday_parse ($resp);
    my $threeday_lo_tdate
      = App::Chart::Download::iso_to_tdate_ceil ($h->{'lo_date'});
    if ($threeday_lo_tdate <= $lo_tdate) {
      App::Chart::Download::write_daily_group ($h);
      return;
    }
  }

  my $info = historical_info();
  my $files = $info->{'files'};
  $files = App::Chart::Download::choose_files ($files, $lo_tdate, $hi_tdate);
  $files = [ sort {$a->{'lo_tdate'} <=> $b->{'lo_tdate'}} @$files ];
  foreach my $f (@$files) {
    my $url = $f->{'url'};
    require File::Basename;
    my $filename = File::Basename::basename($url);
    App::Chart::Download::status (__x('RBA data {filename}',
                                     filename => $filename));
    my $resp = App::Chart::Download->get ($url);
    my $h = xls_parse ($resp);
    App::Chart::Download::write_daily_group ($h);
  }
}

sub backto {
  my ($symbol_list, $backto_tdate) = @_;
  die "Not implemented";
}

1;
__END__
