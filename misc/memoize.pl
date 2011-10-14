use strict;
use warnings;
use Data::Dumper;
use Scalar::Util;

use base 'Attribute::MemoizeToConstant';
# use Attribute::MemoizeToConstant;

my $ref = { 'x' => "hello\n" };

BEGIN { our $foo = 8549; }

sub foo : MemoizeToConstant {
  print "foo runs\n";
  return $ref->{'x'};
}

print Dumper($Attribute::MemoizeToConstant::c);

print "ref ",$ref->{'x'};
print Dumper($ref);

print "foo() ",foo(),"\n";

print Dumper($ref);
Scalar::Util::weaken ($ref);
print Dumper($ref);

print "foo() ",foo(),"\n";

print Dumper($ref);

# print Dumper($Attribute::MemoizeToConstant::c);
# use Devel::FindRef;
# print Devel::FindRef::track($Attribute::MemoizeToConstant::c);

use lib '.';
require 'memoize-2.pl';

print "bar() ",xyz::bar(),"\n";
print "bar() ",xyz::bar(),"\n";
print "bar() ",xyz::bar(),"\n";

