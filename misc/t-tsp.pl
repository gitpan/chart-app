#!/usr/bin/perl -w

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

use strict;
use warnings;
use LWP;
use Data::Dumper;
use Perl6::Slurp ('slurp');
use App::Chart::Suffix::TSP;
use List::Util;

# uncomment this to run the ### lines
use Smart::Comments;

{
  require Finance::Quote;
  require Finance::Quote::TSP;
  $Finance::Quote::TSP::TSP_URL = 'file://'.$ENV{'HOME'}.'/chart/samples/tsp/sharePriceHistory.shtml';
  ### $Finance::Quote::TSP::TSP_URL

  my $q = Finance::Quote->new;
  my %rates = $q->fetch ('tsp','C');
  ### %rates
  exit 0;
}

{
  # my $content = slurp ($ENV{'HOME'}.'/chart/samples/tsp/share-prices.html');

  my $content = slurp ("$ENV{HOME}/chart/samples/tsp/sharePriceHistory.shtml");
  my $resp = HTTP::Response->new (200, 'OK',
                                  ['Content-Type: text/html'], $content);
  my $h = App::Chart::Suffix::TSP::parse($resp);
  print "h= ",Dumper($h);
   App::Chart::Download::crunch_h ($h);
  print "h= ",Dumper($h);

#   App::Chart::Download::write_daily_group ($h);
  exit 0;
}

