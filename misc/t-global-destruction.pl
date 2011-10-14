use strict;
use warnings;
use Scalar::Util;
use Gtk2 '-init';

package ZZ;
use strict;
use warnings;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

sub DESTROY {
  my ($self) = @_;
  my $widget = $self->{'widget'}
    or return;
  print $widget->window || 'undef',"\n";
}

package main;

my $dragger = ZZ->new;
my $widget = Gtk2::DrawingArea->new;
$dragger->{'widget'} = $widget;
$widget->{'dragger'} = $dragger;

$widget->signal_connect (destroy => sub {
                           my ($widget) = @_;
                           delete $widget->{'dragger'};
                           print $widget->window,"\n";
                         });
Scalar::Util::weaken ($widget);
Scalar::Util::weaken ($dragger);

exit 0;

