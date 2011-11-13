use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

eq_or_diff
  $p->parse("foo\033[31mbar\033[00m"),
  [
    [ [     ], 'foo' ],
    [ ['red'], 'bar' ],
  ],
  'parsed simple color';

eq_or_diff
  $p->parse("foo\033[01;31mbar\033[33mbaz\033[00m"),
  [
    [ [                ], 'foo' ],
    [ ['bold', 'red'   ], 'bar' ],
    [ ['bold', 'yellow'], 'baz' ],
  ],
  'bold attribute inherited';

done_testing;
