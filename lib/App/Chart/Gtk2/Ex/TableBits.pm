# container child properties better, maybe, probably



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


package App::Chart::Gtk2::Ex::TableBits;
use 5.008;
use strict;
use warnings;
use Gtk2 1.200; # for Glib::Flags != operator overload
use List::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

my @update_attach_pname = ('left-attach',
                           'right-attach',
                           'top-attach',
                           'bottom-attach',
                           'x-options',
                           'y-options',
                           'x-padding',
                           'y-padding');

sub update_attach {
  my ($table, $child, @args) = @_;
  ### TableBits update_attach: "$child", @args

  my $parent = $child->get_parent;
  if (($parent||0) != $table
      || do {
        my @got = $table->child_get_property($child,@update_attach_pname);
        List::Util::first { $got[$_] != $args[$_] } 0 .. $#args
        }) {
    ### must re-attach
    if ($parent) { $parent->remove ($child); }
    $table->attach ($child, @args);
  }
}

1;
__END__

=for stopwords Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::TableBits -- helpers for Gtk2::Table widgets

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::TableBits;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::TableBits::update_attach ($table, $child, $left_attach, $right_attach, $top_attach, $bottom_attach, $xoptions, $yoptions, $xpadding, $ypadding) >>

Update the attachment positions of C<$child> in C<$table>, if necessary.
The arguments are the same as to C<< $table->attach >>.  If any differ from
the current child attachment properties then a C<remove> and fresh C<attach>
are done.

This function is designed to put a child at what might be a new position in
the table, but do nothing if it's already right.  Avoiding an unnecessary
C<remove> and C<attach> can save a lot of resizing and possibly some
flashing.

=back

=head1 SEE ALSO

L<Gtk2::Table>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

Chart is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Chart is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Chart.  If not, see L<http://www.gnu.org/licenses/>.

=cut
