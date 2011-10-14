# message always ends up pushed to top of statusbar when changed





# Copyright 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Chart is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::Statusbar::Message;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Scalar::Util;
use Gtk2::Ex::Statusbar::DynamicContext;

use Glib::Object::Subclass
  'Glib::Object',
  properties => [ Glib::ParamSpec->object
                  ('statusbar',
                   'statusbar',
                   'Statusbar to display the message in.',
                   'Gtk2::Statusbar',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('message',
                   'message',
                   'The message text to display.',
                   '', # default
                   Glib::G_PARAM_READWRITE) ];

sub INIT_INSTANCE {
  my ($self) = @_;
  # App::Chart::Glib::Ex::TieWeakNotify->setup($self, 'statusbar');
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  _remove_message ($self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;

  if ($pname eq 'statusbar') {
    _remove_message($self);
    delete $self->{'dctx'}; # of old statusbar

    # per default GET_PROPERTY
    Scalar::Util::weaken ($self->{$pname} = $newval);

    _install_message($self);

  } elsif ($pname eq 'message') {
    $self->set_message ($newval);
  }
}

sub set_message {
  my ($self, $message) = @_;

  my $got = $self->{'message'};
  if ((! defined $message && ! defined $got)
      || (defined $message && defined $got
          && $message eq $self->{'message'})) {
    # unchanged, don't notify
    return;
  }

  $self->{'message'} = $message;  # per default GET_PROPERTY
  _remove_message($self);
  _install_message($self);

  # Not sure if it's better to notify immediately or after pushing the new
  # message.  Afterwards means the message is showing if any handlers might
  # try to push yet more stuff ...
  #
  $self->notify('message');
}

sub raise {
  my ($self) = @_;
  _remove_message($self);
  _install_message($self);
}

# doesn't free the DynamicContext, that's done by _install_message()
sub _remove_message {
  my ($self) = @_;
  my $message_id = delete $self->{'message_id'} || return;
  my $dctx = $self->{'dctx'} || return;
  my $statusbar = $self->{'statusbar'} || return;
  $statusbar->remove ($dctx->id, $message_id);
}

sub _install_message {
  my ($self) = @_;
  if (my $statusbar = $self->{'statusbar'}) {
    my $message = $self->{'message'};
    if (defined $message && $message ne '') {
      my $dctx = ($self->{'dctx'} ||=
                  Gtk2::Ex::Statusbar::DynamicContext->new($statusbar));
      $self->{'message_id'} = $statusbar->push ($dctx->id, $message);
      return;
    }
  }
  # let go of DynamicContext when not needed
  delete $self->{'dctx'};
}

1;
__END__

=head1 NAME

App::Chart::Gtk2::Ex::Statusbar::Message -- message displayed in a Statusbar

=for test_synopsis my ($statusbar)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::Statusbar::Message;
 my $msg = App::Chart::Gtk2::Ex::Statusbar::Message->new (statusbar => $statusbar);
 $msg->set_message ('Hello World');
 $msg->set_message (undef);

=head1 OBJECT HIERARCHY

C<App::Chart::Gtk2::Ex::Statusbar::Message> is a subclass of C<Glib::Object>,

    Glib::Object
      App::Chart::Gtk2::Ex::Statusbar::Message

=head1 DESCRIPTION

This is an object-oriented approach to displaying a message in a
C<Gtk2::Statusbar>.

=head1 FUNCTIONS

=over 4

=item C<< $msg = App::Chart::Gtk2::Ex::Statusbar::Message->new (key=>value, ...) >>

Create and return a new Message object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.

    my $msg = App::Chart::Gtk2::Ex::Statusbar::Message->new
                (statusbar => $statusbar,
                 message   => 'Hello World');

=item C<< $msg->set_message($str) >>

Set the message string to display, as per the C<message> property below.

=back

=head1 PROPERTIES

=over 4

=item C<statusbar> (C<Gtk2::Statusbar> or undef)

The Statusbar widget to display, or undef not to display.

=item C<message> (string or undef)

The message string to display, or C<undef> not to add anything to the
Statusbar.

Currently an empty string is treated the same as C<undef>, meaning it's not
added to the Statusbar.

=back

=head1 SEE ALSO

L<Gtk2::Statusbar>, L<Gtk2::Ex::Statusbar::DynamicContext>

=cut

# should be ok now...
#
# =head1 BUGS
# 
# When the C<statusbar> becomes C<undef> through weakening a C<notify> signal
# is not emitted.

