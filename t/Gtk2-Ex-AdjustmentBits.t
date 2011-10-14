#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More tests => 9;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Chart::Gtk2::Ex::AdjustmentBits;

#-----------------------------------------------------------------------------
# {
#   my $want_version
#   is ($App::Chart::Gtk2::Ex::AdjustmentBits::VERSION, $want_version,
#       'VERSION variable');
#   is (App::Chart::Gtk2::Ex::AdjustmentBits->VERSION,  $want_version,
#       'VERSION class method');
# 
#   ok (eval { App::Chart::Gtk2::Ex::AdjustmentBits->VERSION($want_version); 1 },
#       "VERSION class check $want_version");
#   my $check_version = $want_version + 1000;
#   ok (! eval { App::Chart::Gtk2::Ex::AdjustmentBits->VERSION($check_version); 1 },
#       "VERSION class check $check_version");
# }

# Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
# my $have_display = Gtk2->init_check;

require Gtk2;
MyTestHelpers::glib_gtk_versions();

#-----------------------------------------------------------------------------
# empty()

{
  my $adjustment = Gtk2::Adjustment->new (50, 1, 100, 5, 10, 20);

  my $notify = 0;
  my $changed = 0;
  my $value_changed = 0;
  $adjustment->signal_connect (notify => sub {
                                 my ($adj, $pspec) = @_;
                                 diag "notify ",$pspec->get_name;
                                 $notify++;
                               });
  $adjustment->signal_connect (changed => sub {
                                 diag "changed";
                                 $changed++;
                               });
  $adjustment->signal_connect (value_changed => sub {
                                 diag "value_changed";
                                 $value_changed++;
                               });

  App::Chart::Gtk2::Ex::AdjustmentBits::empty ($adjustment);

  cmp_ok ($changed,       '==', 1, 'empty - changed');
  cmp_ok ($value_changed, '==', 1, 'empty - value_changed');
  cmp_ok ($notify,        '==', 6, 'empty - notify');

  is ($adjustment->upper,          0, 'empty - upper');
  is ($adjustment->lower,          0, 'empty - lower');
  is ($adjustment->page_size,      0, 'empty - page_size');
  is ($adjustment->page_increment, 0, 'empty - page_increment');
  is ($adjustment->step_increment, 0, 'empty - step_increment');
  is ($adjustment->value,          0, 'empty - value');
}


exit 0;
