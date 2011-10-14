package xyz;
use strict;
use warnings;
use base 'Attribute::MemoizeToConstant';

sub bar : MemoizeToConstant {
  print "bar runs\n";
  return 12356;
}
1;
