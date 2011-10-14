use strict;
use warnings;
use Glib;
use Gtk2 '-init';

{
  my $w = Gtk2::Window->new ('toplevel');
  my $f = $w->flags;
  print $f,"\n";
  use Data::Dumper;
  print Dumper($f);

  $f += 'sensitive';

  print $f,"\n";
  use Data::Dumper;
  print Dumper($f);

  exit 0;
}

{
  my $f = Glib::ParamFlags->new (['readable']);
  print $f,"\n";
  use Data::Dumper;
  print Dumper($f);

  my $g = $f;
  print $g,"\n";
  print Dumper($g);

  $g += 'writable';
  print $g,"\n";
  print Dumper($g);
}
