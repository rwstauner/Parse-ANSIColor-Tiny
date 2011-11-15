use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

my $mod = 'Parse::ANSIColor::Tiny';
eval "require $mod" or die $@;

my $p = new_ok($mod);

my @colors = qw( black red green yellow blue magenta cyan white );

eq_or_diff
  [$p->colors],
  [@colors],
  'base colors';

eq_or_diff
  [$p->foreground_colors],
  [@colors, map { "bright_$_" } @colors],
  'fg colors';

eq_or_diff
  [$p->background_colors],
  [(map { "on_$_" } @colors), (map { "on_bright_$_" } @colors)],
  'bg colors';

done_testing;
