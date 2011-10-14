use strict;
use warnings;
use HTTP::Message;
use Perl6::Slurp ('slurp');


my $file = slurp ('foo.gz');
print length($file),"\n";
my $chunk = substr ($file, 0, length($file)/2);

my $resp = HTTP::Message->new;
$resp->add_content($chunk);
$resp->push_header('Content-Encoding' => 'gzip');
print $resp->headers->as_string;

my $image = $resp->decoded_content(charset=>'none');
print length ($image);
