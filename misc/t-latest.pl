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
use Gtk2 '-init';
use App::Chart::Gtk2::Symlist;
use App::Chart::Latest;

binmode(STDOUT,":encoding(latin-1)") or die;
{
  my $latest = App::Chart::Latest->get ('CCL.AX');
  use Data::Dumper;
  print Dumper ($latest);
  print $latest->short_datetime;
  exit 0;
}

{
  require Time::Piece;
  my $now = Time::Piece->localtime;
  print $now->mjd,"\n";
  print $now->strftime ("%a %d %b %H:%M"),"\n";
  #  print $now->AppChart_strftime_wide ("%a %b"),"\n";
  exit 0;
}
