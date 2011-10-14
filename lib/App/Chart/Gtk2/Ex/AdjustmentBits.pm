# Copyright 2009, 2010, 2011 Kevin Ryde

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


package App::Chart::Gtk2::Ex::AdjustmentBits;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util qw(min max);
use Gtk2::Ex::AdjustmentBits 43; # v.43 for set_maybe()

# uncomment this to run the ### lines
#use Smart::Comments;


sub empty {
  my ($adj) = @_;
  Gtk2::Ex::AdjustmentBits::set_maybe ($adj,
                                       upper => 0,
                                       lower => 0,
                                       page_size => 0,
                                       page_increment => 0,
                                       step_increment => 0,
                                       value => 0);
}

1;
__END__

=for stopwords Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::AdjustmentBits -- helpers for Gtk2::Adjustment objects

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::AdjustmentBits;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::AdjustmentBits::empty ($adjustment) >>

Make C<$adjustment> empty by setting its upper, lower, and all values to 0.
This is done with C<set_maybe> below, so if it's already empty no "changed"
etc signals are emitted.

=back

=head1 SEE ALSO

L<Gtk2::Adjustment>, L<Gtk2::Ex::WidgetBits>

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
