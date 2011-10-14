# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Suffix::TSP;
use 5.006;
use strict;
use warnings;
no warnings 'once';
use List::Util qw(min max);
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::FinanceQuote;
use App::Chart::IntradayHandler;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;

use constant DEBUG => 0;


my $pred = App::Chart::Sympred::Suffix->new ('.TSP');

# FIXME: is east coast right?
App::Chart::TZ->newyork->setup_for_symbol ($pred);

App::Chart::setup_source_help
  ($pred, __p('manual-node','Thrift Savings Plan'));

App::Chart::FinanceQuote->setup (pred => $pred,
                                suffix => '.TSP',
                                modules => ['TSP'],
                                method => 'tsp');


#------------------------------------------------------------------------------
# weblink

# only home page, per "Linkage to the TSP Web Site" requirement
App::Chart::Weblink->new
  (pred => $pred,
   name => __('_TSP Home Page'),
   desc => __('Open web browser at the US Government Thrift Savings Plan'),
   proc  => sub {
     require Finance::Quote::TSP;
     return $Finance::Quote::TSP::TSP_MAIN_URL;
   });


#-----------------------------------------------------------------------------
# download
#
# This uses the historical prices page:
#
use constant TSP_SHARE_PRICES_URL =>
  'https://www.tsp.gov/investmentfunds/shareprice/sharePriceHistory.shtml';
#
# which is the latest, or past data with a POST like
#
#     startdate=20030801&enddate=20031128&submit=Retrieve+Share+Prices&prev=0&next=30
#
# The data on each request is limited to 30 days at time, and goes back to
# 2003-06-02.
#

use constant CHUNK_SIZE => 20;

App::Chart::DownloadHandler->new
  (name            => __('TSP'),
   pred            => $pred,
   available_tdate => \&available_tdate,
   proc            => \&download);

# 18:55 still showing prev
# 20:22 showing today
sub available_tdate {
  App::Chart::Download::tdate_today_after
      (20,0, App::Chart::TZ->newyork);
}

sub download {
  my ($symbol_list) = @_;

  my $avail_tdate = available_tdate();
  my $lo_tdate = App::Chart::Download::start_tdate_for_update (@$symbol_list);

  if ($lo_tdate > $avail_tdate) {
    App::Chart::Download::verbose_message
        (__('TSP nothing further expected yet'));
    return;
  }

  # ask for extra in case available_tdate() is a bit short
  $avail_tdate += 2;

  # ENHANCE-ME: If the POST is botched then the return is the most recent 30
  # days, which means historical updates etc leave a gap.  Could check the
  # request comes back with something expected ... or have something in
  # write_daily_group().
  #

  while ($lo_tdate <= $avail_tdate) {
    my $hi_tdate = min ($lo_tdate + CHUNK_SIZE - 1, $avail_tdate);

    my $resp = get_chunk ($lo_tdate, $hi_tdate);
    my $h = parse ($resp);

    if ($hi_tdate == $avail_tdate) {
      $h->{'last_download'} = 1;
    }
    App::Chart::Download::write_daily_group ($h);

    $lo_tdate = $hi_tdate + 1;
  }
}

sub backto {
  my ($symbol_list, $backto_tdate) = @_;
  my $hi_tdate = App::Chart::Download::start_tdate_for_backto (@$symbol_list);

  while ($hi_tdate >= $backto_tdate) {
    my $lo_tdate = $hi_tdate - CHUNK_SIZE + 1;

    my $resp = get_chunk ($lo_tdate, $hi_tdate);
    my $h = parse ($resp);
    App::Chart::Download::write_daily_group ($h);

    $lo_tdate = $hi_tdate + 1;
  }
}

# return a HTTP::Response for data $lo_tdate to $hi_tdate, inclusive
sub get_chunk {
  my ($lo_tdate, $hi_tdate) = @_;

  App::Chart::Download::status
      (__x('TSP data {date_range}',
           date_range =>
           App::Chart::Download::tdate_range_string ($lo_tdate, $hi_tdate)));

  my ($lo_year, $lo_month, $lo_day) = App::Chart::tdate_to_ymd ($lo_tdate);
  my ($hi_year, $hi_month, $hi_day) = App::Chart::tdate_to_ymd ($hi_tdate);
  my $startdate = sprintf "%04d%02d%02d", $lo_year, $lo_month, $lo_day;
  my $enddate   = sprintf "%04d%02d%02d", $hi_year, $hi_month, $hi_day;

  return App::Chart::Download->get
    (TSP_SHARE_PRICES_URL,
     method => 'POST',
     data => "startdate=$startdate&enddate=$enddate&submit=Retrieve+Share+Prices&prev=0&next=30");
}

sub parse {
  my ($resp) = @_;

  # From 1 Jul 2008 prices are 4 decimal places, and old data is padded with
  # zeros.  Could prefer_decimals to strip them, but may as well leave at
  # current precision.
  #
  my @data = ();
  my $h = { source      => __PACKAGE__,
            currency    => 'USD',
            date_format => 'mdy',
            suffix      => '.TSP',
            data        => \@data };

  my $content = $resp->decoded_content (raise_error=>1);

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new (headers => [qr/^Date$/i],
                                    keep_headers => 1,
                                    slice_columns => 0);
  $te->parse($content);
  my $ts = $te->first_table_found();
  #### $ts
  if (! $ts) { die 'TSP price table not found'; }

  my $rows = $ts->rows();
  my $lastrow = $#$rows;
  my $lastcol = $#{$rows->[0]};

  my @symbol = map { my $symbol = $_;
                     $symbol =~ s/ Fund//i;
                     $symbol =~  s/ //g;
                     # upper case for "LINCOME.TSP" (documented in
                     # chart.texi that way)
                     $symbol eq 'Date' ? undef : "\U$symbol.TSP" } @{$rows->[0]};

  require Finance::Quote::TSP;
  my @name = map { my $key = $_;
                   $key =~  s/ //g;
                   $Finance::Quote::TSP::TSP_FUND_NAMES{"TSP$key"} }
    @{$rows->[0]};

  foreach my $r (1 .. $lastrow) {
    my $row = $rows->[$r];
    if (DEBUG) { require Data::Dumper;
                 print Data::Dumper::Dumper($row); }
    my $date = $row->[0];

    foreach my $c (1 .. $lastcol) {
      my $price = $row->[$c];

      push @data, { symbol => $symbol[$c],
                    name   => $name[$c],
                    date   => $date,
                    close  => $price,
                  };
    }
  }
  if (DEBUG) {
    require List::Util;
    print "min date ",List::Util::minstr(map {$_->{'date'}} @data),"\n";
    print "max date ",List::Util::maxstr(map {$_->{'date'}} @data),"\n";
  }
  return $h;
}

1;
__END__
