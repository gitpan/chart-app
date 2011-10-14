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

package App::Chart::Glib::Ex::TempProperty;
use 5.008;
use strict;
use warnings;
use Glib;

sub new {
  my ($class, $obj, $pname, $value) = @_;
  my $self = bless [ $obj, $pname, $obj->get_property($pname) ], $class;
  if (@_ > 3) { $obj->set_property($pname,$value); }
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  my ($obj, $pname, $value) = @$self;
  $obj->set_property($pname,$value);
}

1;
__END__

=head1 NAME

=for stopwords TempProperty

App::Chart::Glib::Ex::TempProperty -- temporary object property setting

=for test_synopsis my ($obj, $newval)

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::TempProperty;
 my $setting = App::Chart::Glib::Ex::TempProperty->new ($obj, 'propname', $newval);

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Glib::Ex::TempProperty->new ($obj, $propname) >>

=item C<< App::Chart::Glib::Ex::TempProperty->new ($obj, $propname, $newvalue) >>

Create and return a TempProperty object ...

=back

=head1 SEE ALSO

L<Glib::Ex::TieProperties>

=cut
