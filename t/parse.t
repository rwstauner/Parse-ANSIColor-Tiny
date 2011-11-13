use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

is_deeply
  $p->parse("foo\033[31mbar\033[00m"),
  [
    [ [     ], 'foo' ],
    [ ['red'], 'bar' ],
  ],
  'parsed simple color';

# TODO: test inheritance

done_testing;
