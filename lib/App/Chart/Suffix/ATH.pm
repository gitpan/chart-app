# Athens Stock Exchange setups.    -*- coding: iso-8859-7 -*-

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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



# cf http://www.ase.gr/content/en/Companies/ListedCo/Profiles/pr_Snapshot.asp?Cid=99&coname=HELLENIC+TELECOM.+ORG.
#
#    http://www.ase.gr/content/en/Companies/ListedCo/Profiles/pr_Snapshot.asp?share=HTO
#    http://www.ase.gr/content/en/marketdata/stocks/prices/Share_SearchResults.asp?share=HTO



package App::Chart::Suffix::ATH;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::DownloadHandler::DividendsPage;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $timezone_athens = App::Chart::TZ->new
  (name     => __('Athens'),
   choose   => [ 'Europe/Athens' ],
   fallback => 'EET-2');
my $pred = App::Chart::Sympred::Suffix->new ('.ATH');
$timezone_athens->setup_for_symbol ($pred);

# (source-help! athens-symbol?
# 	      (__p('manual-node','Athens Stock Exchange'))


#------------------------------------------------------------------------------
# weblink - company info
#
# The greek pages "/gr/" need greek symbols, the english doesn't work, hence
# only an english link here, for now.

App::Chart::Weblink->new
  (pred => $pred,
   name => __('ATHEX _Company Information'),
   desc => __('Open web browser at the Athens Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.ase.gr/content/en/Companies/ListedCo/Profiles/Profile.asp?name='
       . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
   });


#------------------------------------------------------------------------------
# 8859-7 transliteration
#
# The 8859-7 bytes here in the source are for ease of seeing what they're
# supposed to be, but they're only in the comments, the code is all-ascii.
#
# $translit is a Regexp::Tr mapping Perl wide-chars which are certain greek
# characters (from iso-8859-7) to some latin equivalents.
#
# This is for some greek characters found in otherwise English names, like
# ���� (0xC2,0xC1,0xCD,0xCA) for BANK in ALPHA.ATH.  That comes out looking
# ok in Gtk or anywhere with good fonts, but for a tty a change to the
# actual intended latin characters is needed to make it printable.

our $translit; # global for testing
{
  my %table
    = (
       #            # A0 � NO-BREAK SPACE
       #            # A1 � MODIFIER LETTER REVERSED COMMA
       #            # A2 � MODIFIER LETTER APOSTROPHE
       #            # A3 � POUND SIGN
       #            # A4
       #            # A5
       #            # A6 � BROKEN BAR
       #            # A7 � SECTION SIGN
       #            # A8 � DIAERESIS
       #            # A9
       #            # AA
       #            # AB � LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
       #            # AC � NOT SIGN
       #            # AD � SOFT HYPHEN
       #            # AE
       #            # AF � HORIZONTAL BAR
       #            # B0 � DEGREE SIGN
       #            # B1 � PLUS-MINUS SIGN
       #            # B2 � SUPERSCRIPT TWO
       #            # B3 � SUPERSCRIPT THREE
       #            # B4 � GREEK TONOS
       #            # B5 � GREEK DIALYTIKA TONOS
       0xB6 => 'A', # B6 � GREEK CAPITAL LETTER ALPHA WITH TONOS
       #            # B7 � MIDDLE DOT
       0xB8 => 'E', # B8 � GREEK CAPITAL LETTER EPSILON WITH TONOS
       0xB9 => 'H', # B9 � GREEK CAPITAL LETTER ETA WITH TONOS
       0xBA => 'I', # BA � GREEK CAPITAL LETTER IOTA WITH TONOS
       #            # BB � RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
       #            # BC � GREEK CAPITAL LETTER OMICRON WITH TONOS
       #            # BD � VULGAR FRACTION ONE HALF
       #            # BE � GREEK CAPITAL LETTER UPSILON WITH TONOS
       0xBF => 'O', # BF � GREEK CAPITAL LETTER OMEGA WITH TONOS
       #            # C0 � GREEK SMALL LETTER IOTA WITH DIALYTIKA AND TONOS
       0xC1 => 'A', # C1 � GREEK CAPITAL LETTER ALPHA
       0xC2 => 'B', # C2 � GREEK CAPITAL LETTER BETA
       0xC3 => 'G', # C3 � GREEK CAPITAL LETTER GAMMA
       0xC4 => 'D', # C4 � GREEK CAPITAL LETTER DELTA
       0xC5 => 'E', # C5 � GREEK CAPITAL LETTER EPSILON
       0xC6 => 'Z', # C6 � GREEK CAPITAL LETTER ZETA
       0xC7 => 'H', # C7 � GREEK CAPITAL LETTER ETA
       #            # C8 � GREEK CAPITAL LETTER THETA
       0xC9 => 'I', # C9 � GREEK CAPITAL LETTER IOTA
       0xCA => 'K', # CA � GREEK CAPITAL LETTER KAPPA
       0xCB => 'L', # CB � GREEK CAPITAL LETTER LAMDA
       0xCC => 'M', # CC � GREEK CAPITAL LETTER MU
       0xCD => 'N', # CD � GREEK CAPITAL LETTER NU
       0xCE => 'X', # CE � GREEK CAPITAL LETTER XI
       #            # CF � GREEK CAPITAL LETTER OMICRON
       0xD0 => 'P', # D0 � GREEK CAPITAL LETTER PI
       0xD1 => 'R', # D1 � GREEK CAPITAL LETTER RHO
       #            # D2
       0xD3 => 'S', # D3 � GREEK CAPITAL LETTER SIGMA
       0xD4 => 'T', # D4 � GREEK CAPITAL LETTER TAU
       #            # D5 � GREEK CAPITAL LETTER UPSILON
       #            # D6 � GREEK CAPITAL LETTER PHI
       #            # D7 � GREEK CAPITAL LETTER CHI
       #            # D8 � GREEK CAPITAL LETTER PSI
       0xD9 => 'O', # D9 � GREEK CAPITAL LETTER OMEGA
       #            # DA � GREEK CAPITAL LETTER IOTA WITH DIALYTIKA
       #            # DB � GREEK CAPITAL LETTER UPSILON WITH DIALYTIKA
       0xDC => 'a', # DC � GREEK SMALL LETTER ALPHA WITH TONOS
       0xDD => 'e', # DD � GREEK SMALL LETTER EPSILON WITH TONOS
       #            # DE � GREEK SMALL LETTER ETA WITH TONOS
       0xDF => 'i', # DF � GREEK SMALL LETTER IOTA WITH TONOS
       #            # E0 � GREEK SMALL LETTER UPSILON WITH DIALYTIKA AND TONOS
       0xE1 => 'a', # E1 � GREEK SMALL LETTER ALPHA
       0xE2 => 'b', # E2 � GREEK SMALL LETTER BETA
       0xE3 => 'g', # E3 � GREEK SMALL LETTER GAMMA
       0xE4 => 'd', # E4 � GREEK SMALL LETTER DELTA
       0xE5 => 'e', # E5 � GREEK SMALL LETTER EPSILON
       0xE6 => 'z', # E6 � GREEK SMALL LETTER ZETA
       #            # E7 � GREEK SMALL LETTER ETA
       #            # E8 � GREEK SMALL LETTER THETA
       0xE9 => 'i', # E9 � GREEK SMALL LETTER IOTA
       0xEA => 'k', # EA � GREEK SMALL LETTER KAPPA
       0xEB => 'l', # EB � GREEK SMALL LETTER LAMDA
       0xEC => 'm', # EC � GREEK SMALL LETTER MU
       0xED => 'n', # ED � GREEK SMALL LETTER NU
       #            # EE � GREEK SMALL LETTER XI
       #            # EF � GREEK SMALL LETTER OMICRON
       0xF0 => 'p', # F0 � GREEK SMALL LETTER PI
       0xF1 => 'r', # F1 � GREEK SMALL LETTER RHO
       0xF2 => 's', # F2 � GREEK SMALL LETTER FINAL SIGMA
       0xF3 => 's', # F3 � GREEK SMALL LETTER SIGMA
       0xF4 => 't', # F4 � GREEK SMALL LETTER TAU
       #            # F5 � GREEK SMALL LETTER UPSILON
       #            # F6 � GREEK SMALL LETTER PHI
       #            # F7 � GREEK SMALL LETTER CHI
       #            # F8 � GREEK SMALL LETTER PSI
       0xF9 => 'o', # F9 � GREEK SMALL LETTER OMEGA
       0xFA => 'i', # FA � GREEK SMALL LETTER IOTA WITH DIALYTIKA
       #            # FB � GREEK SMALL LETTER UPSILON WITH DIALYTIKA
       #            # FC � GREEK SMALL LETTER OMICRON WITH TONOS
       #            # FD � GREEK SMALL LETTER UPSILON WITH TONOS
       0xFE => 'o', # FE � GREEK SMALL LETTER OMEGA WITH TONOS
       #            # FF
      );

  require Encode;
  my $tr_from = join ('',
                      map { Encode::decode ('iso-8859-7', chr($_)) }
                      keys %table);
  my $tr_to = join ('', values %table);

  $tr_to   =~ s/-/\\-/g; # escape "tr" dash as range
  $tr_from =~ s/-/\\-/g;

  require Regexp::Tr;
  $translit = Regexp::Tr->new ($tr_from, $tr_to);
  Regexp::Tr->flush;
  ### $translit
}

#-----------------------------------------------------------------------------
# download - last 30 days by symbol
#
# This uses the prices pages like
#
#     http://www.ase.gr/content/en/marketdata/stocks/prices/Share_SearchResults.asp?share=HTO
#
# Various places link to those price pages using a "SID" id number, but the
# symbol works too.
#
# There's no ETag or Last-Modified to save re-downloading if our idea of
# what should be available is a bit out.

App::Chart::DownloadHandler->new
  (name   => __ 'ATHEX',
   pred   => $pred,
   proc   => \&last30_download,
   max_symbols => 1,
   available_date_time => \&last30_available_date_time,
  );

# Dunno when to expect new data.  Try after 6pm Athens time.
sub last30_available_date_time {
  return (App::Chart::Download::weekday_date_after_time
          (18,0, $timezone_athens),
          '18:00:00');
}

sub last30_download {
  my ($symbol_list) = @_;

  foreach my $symbol (@$symbol_list) {
    App::Chart::Download::status (__x ('ATHEX 30 days data {symbol}',
                                      symbol => $symbol));
    my $url = 'http://www.ase.gr/content/en/marketdata/stocks/prices/Share_SearchResults.asp?share='
      . URI::Escape::uri_escape (App::Chart::symbol_sans_suffix ($symbol));
    my $resp = App::Chart::Download->get ($url);
    App::Chart::Download::write_daily_group (last30_parse ($resp));
  }
}

sub last30_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);

  my @data = ();
  my $h = { source        => __PACKAGE__,
            currency      => 'EUR',
            last_download => 1,
            cost_key      => 'athens-last30',
            date_format   => 'dmy',
            resp          => $resp,
            data          => \@data };

  # message in page if bad symbol
  if ($content =~ /Your search didn't return any results/) {
    return $h;
  }

  $content =~ m{Share Closing Prices: ([A-Z]+)[^-]*-[^>]*>([^<]+)</a>}
    or die "ATHEX last30 name not matched";
  my $symbol = $1 . '.ATH';
  my $name = $2;

  # some names on the english pages have greek 8859-7 capitals, mung those
  # to plain ascii
  $h->{'name'} = $translit->trans ($name);

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['Date', 'Open', 'Max', 'Min', 'Price', 'Volume' ]);
  $te->parse($content);
  if (! $te->tables) {
    die "ATHEX last30 table not matched";
  }

  foreach my $row ($te->rows) {
    my ($date, $open, $high, $low, $close, $volume) = @$row;
    push @data, { symbol => $symbol,
                  date   => $date,
                  open   => $open,
                  high   => $high,
                  low    => $low,
                  close  => $close,
                  volume => $volume };
  }
  return $h;
}


#------------------------------------------------------------------------------
# dividends
#
# This uses the dividend page at
#
use constant DIVIDENDS_URL =>
  'http://www.ase.gr/content/en/announcements/dailypress/Daily_Dividends.asp';
#
# As of May 2008 alas there's no ETag or Last-Modified to avoid
# re-downloading, so leave at the default DividendsPage recheck frequency.
#

App::Chart::DownloadHandler::DividendsPage->new
  (name  => __('ATHEX dividends'),
   pred  => $pred,
   url   => DIVIDENDS_URL,
   parse => \&dividends_parse,
   key   => 'ATH-dividends');

sub dividends_parse {
  my ($resp) = @_;
  my $body = $resp->decoded_content (raise_error => 1);

  my @dividends = ();
  my $h = { source       => __PACKAGE__,
            resp         => $resp,
            date_format  => 'dmy',
            # amounts are like "0.360", trim to 2 decimals
            prefer_decimals => 2,
            dividends       => \@dividends };

  # "Price in &euro;" reaches here as wide char \x{20AC}, probably, maybe,
  # hopefully, but don't bother to try to match that.
  #
  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => [ 'Symbol',
                  'Ex-Dividend Date',
                  'Start Payment Date',
                  'Price in' ]);
  $te->parse($body);
  my @tables = $te->tables
    or die "ATHEX dividend table not matched";

  foreach my $ts (@tables) {
    foreach my $row ($ts->rows) {
      my ($symbol, $ex_date, $pay_date, $amount) = @$row;

      # skip blank separator rows
      if (! defined $symbol) { next; }

      # skip second row of headings under "Pre-Paid Dividends"
      if ($symbol eq 'Symbol') { next; }

      push @dividends, { symbol   => "$symbol.ATH",
                         ex_date  => $ex_date,
                         pay_date => $pay_date,
                         amount   => $amount };
    }
  }
  return $h;
}

1;
__END__
