#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Data::Dumper;
use App::Chart::Gtk2::Symlist::All;
use App::Chart::Gtk2::Symlist::Glob;

{
  my $all = App::Chart::Gtk2::Symlist::All->instance;
  my $glob = App::Chart::Gtk2::Symlist::Glob->new ($all, '*.RBA');
  print $glob->length,"\n";
  print $glob->symbols,"\n";
  exit 0;
}
