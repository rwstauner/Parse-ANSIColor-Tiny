use strict;
use warnings;
use Test::More 0.96;
use Test::Differences;

plan skip_all => 'Term::ANSIColor required for these tests'
  unless eval 'require Term::ANSIColor';

use Parse::ANSIColor::Tiny;
my $p = new_ok('Parse::ANSIColor::Tiny');

# in order to match exact output from colored()
# we need to end each chunk with a 'clear' (colored() always ends with a clear)
# plus attributes are not inherited across calls so we need to repeat them
my $text = <<OUTPUT . "\e[0m";
I've got a \e[0m\e[1;33mlovely \e[0m\e[1;32mbunch\033[0m of coconuts.
I want to be \e[0m\033[34ma \e[0m\e[34;4mmighty \e[0m\e[34;4;45mpirate\e[0m.
OUTPUT

my $parsed = $p->parse($text);

eq_or_diff
  $parsed,
  [
    [ [], "I\'ve got a " ],
    [ ['bold', 'yellow'], 'lovely ' ],
    [ ['bold', 'green'], 'bunch'],
    [ [], " of coconuts.\nI want to be " ],
    [ ['blue'], 'a ' ],
    [ ['blue', 'underline'], 'mighty ' ],
    [ ['blue', 'underline', 'on_magenta'], 'pirate' ],
    [ [], ".\n" ],
  ],
  'parsed output';

my $colored = join('', map { Term::ANSIColor::colored(@$_) } @$parsed);

note $text, $colored;

eq_or_diff
  $colored,
  $text,
  'round-trip through Term::ANSIColor produced identical output';

done_testing;
