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
use Glib;
use Gtk2 '-init';

{
  package Foo;
  package main;
  my $type = 'Glib::Boolean';
  #   $type = 'Gtk2::Gdk::Color';
  #   $type = 'Gtk2::Gdk::EventMask';
  $type = 'Foo';
  $type = 'Glib::Int';
  $type = 'Gtk2::Gdk::Cursor';
  print $type->isa($type) ? "yes\n" : "no\n";
  exit 0;
}
