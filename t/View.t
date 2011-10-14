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


use 5.010;
use strict;
use warnings;
use Test::More 0.82 tests => 3;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use AppChartTestHelpers;

require App::Chart::Gtk2::View;

#-----------------------------------------------------------------------------
{
  my $view = App::Chart::Gtk2::View->new;
  require Scalar::Util;
  Scalar::Util::weaken ($view);
  is ($view, undef,
      'garbage collect when weakened');
}

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

# Test::Weaken 3 for "contents"
my $have_test_weaken = eval "use Test::Weaken 3; 1";
if (! $have_test_weaken) { diag "Test::Weaken 3 not available -- $@"; }

sub my_ignores {
  my ($obj) = @_;
  #    print "ign $obj\n";
  return (AppChartTestHelpers::ignore_symlists($obj)
          || AppChartTestHelpers::ignore_global_number_formatter($obj)
          || Test::Weaken::ExtraBits::ignore_global_function($obj));
}

SKIP: {
  $have_display
    or skip 'due to no DISPLAY available', 2;
  $have_test_weaken
    or skip 'due to Test::Weaken 3 not available', 2;

  require Test::Weaken::Gtk2;
  require Test::Weaken::ExtraBits;

  {
    my $leaks = Test::Weaken::leaks
      ({ constructor => sub {
           my $toplevel = Gtk2::Window->new ('toplevel');
           my $view = App::Chart::Gtk2::View->new;
           $toplevel->add ($view);
           $toplevel->show_all;

           $view->set_symbol ('BHP.AX'); # 'CLZ11.NYM'
           return $toplevel;
         },
         destructor => \&Test::Weaken::Gtk2::destructor_destroy,
         contents => \&Test::Weaken::Gtk2::contents_container,
         ignore => \&my_ignores,
         # trace_tracking => 1,
         # trace_maxdepth => 1,
       });
    is ($leaks, undef, 'Test::Weaken deep garbage collection');
    if ($leaks) {
      diag "Test-Weaken ", explain $leaks;

      my $unfreed = $leaks->unfreed_proberefs;
      foreach my $proberef (@$unfreed) {
        diag "  unfreed $proberef ",ref($proberef);
      }
      foreach my $proberef (@$unfreed) {
        diag "  search $proberef";
        MyTestHelpers::findrefs($proberef);
      }
    }
  }

  {
    my $toplevel = Gtk2::Window->new ('toplevel');
    my $view = App::Chart::Gtk2::View->new;
    $toplevel->add ($view);
    $toplevel->realize;

    $view->set_symbol ('FOO');
    $view->crosshair;
    Scalar::Util::weaken ($view);
    $toplevel->destroy;
    is ($view, undef,
        'garbage collect when weakened -- with symbol and crosshair');
  }
}

exit 0;
