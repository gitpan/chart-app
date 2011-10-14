#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# 0-desktop-file-validate.t is shared by several distributions.
#
# 0-desktop-file-validate.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-desktop-file-validate.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use ExtUtils::Manifest;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (system('desktop-file-validate --help >/dev/null 2>&1')) {
  plan skip_all => "due to desktop-file-validate program available";
}

my $manifest = ExtUtils::Manifest::maniread();
my @files = grep /\.desktop$/, keys %$manifest;
@files = grep {!m{^devel/}} @files;

plan tests => scalar(@files);

my $good = 1;
foreach my $filename (@files) {
  my $status = system('desktop-file-validate',
                      '--no-warn-deprecated',
                      $filename);
  is ($status, 0, "file $filename");
}

exit 0;
