#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use 5.010;
use Gtk2 '-init';
use App::Chart::Gtk2::Ex::Statusbar::Message;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (200, -1);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $buttonbox = Gtk2::HBox->new;
$vbox->pack_start ($buttonbox, 0,0,0);

my $statusbar = Gtk2::Statusbar->new;
$vbox->pack_start ($statusbar, 0,0,0);
$statusbar->signal_connect (notify => sub {
                              my ($statusbar, $pspec) = @_;
                              print "$progname: statusbar notify ",$pspec->get_name,"\n";
                            });

my $statusbar2 = Gtk2::Statusbar->new;
$vbox->pack_start ($statusbar2, 0,0,0);
$statusbar->signal_connect (notify => sub {
                              my ($statusbar2, $pspec) = @_;
                              print "$progname: statusbar2 notify ",$pspec->get_name,"\n";
                            });

my $msg = App::Chart::Gtk2::Ex::Statusbar::Message->new (statusbar => $statusbar);
$msg->set_message ('Hello');
$msg->signal_connect (notify => sub {
                        my ($msg, $pspec) = @_;
                        print "$progname: msg notify ",$pspec->get_name,"\n";
                      });

{
  my $button = Gtk2::Button->new_with_label ('Switch');
  $button->signal_connect (clicked => sub {
                             print "$progname: switch\n";
                             my $old = $msg->get('statusbar');
                             my $new = (! defined $old ? $statusbar
                                        : $old == $statusbar ? $statusbar2
                                        : undef);
                             $msg->set (statusbar => $new);
                           });
  $buttonbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ('Change');
  my $n = -1;
  $button->signal_connect (clicked => sub {
                             print "$progname: change\n";
                             my $old = $msg->get('message');
                             my $new = $old . $n--;
                             $msg->set_message ($new);
                           });
  $buttonbox->pack_start ($button, 0,0,0);
}
{
  my $statusbar = Gtk2::Statusbar->new;
  $vbox->pack_start ($statusbar, 0,0,0);
}

{
  require Gtk2::Ex::Statusbar::ContextStr;

  my $cstrobj = Gtk2::Ex::Statusbar::ContextStr->new;
  print "$progname: ", $cstrobj->str, "\n";

  my $cstrobj2 = Gtk2::Ex::Statusbar::ContextStr->new;
  print "$progname: ", $cstrobj2->str, "\n";

  undef $cstrobj;
  $cstrobj = Gtk2::Ex::Statusbar::ContextStr->new;
  print "$progname: ", $cstrobj->str, "\n";
}

$toplevel->show_all;
Gtk2->main;
exit 0;
