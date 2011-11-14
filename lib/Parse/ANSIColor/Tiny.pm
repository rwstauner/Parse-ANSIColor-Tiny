# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Parse::ANSIColor::Tiny;
# ABSTRACT: Determine attributes of ANSI-Colored string

our @COLORS = qw( black red green yellow blue magenta cyan white );
our %FOREGROUND = (
  (map { (               $COLORS[$_] =>  30 + $_ ) } 0 .. $#COLORS),
  (map { (   'bright_' . $COLORS[$_] =>  90 + $_ ) } 0 .. $#COLORS),
);
our %BACKGROUND = (
  (map { (       'on_' . $COLORS[$_] =>  40 + $_ ) } 0 .. $#COLORS),
  (map { ('on_bright_' . $COLORS[$_] => 100 + $_ ) } 0 .. $#COLORS),
);
our %ATTRIBUTES = (
  clear          => 0,
  reset          => 0,
  bold           => 1,
  dark           => 2,
  faint          => 2,
  underline      => 4,
  underscore     => 4,
  blink          => 5,
  reverse        => 7,
  concealed      => 8,
  %FOREGROUND,
  %BACKGROUND,
);

# copied from Term::ANSIColor
  our %ATTRIBUTES_R;
  # Reverse lookup.  Alphabetically first name for a sequence is preferred.
  for (reverse sort keys %ATTRIBUTES) {
      $ATTRIBUTES_R{$ATTRIBUTES{$_}} = $_;
  }

=method new

Constructor.

Takes a hash or hash ref of arguments
though currently no options are defined :-)

=cut

sub new {
  my $class = shift;
  my $self = {
    @_ == 1 ? %{ $_[0] } : @_,
  };
  bless $self, $class;
}

=method identify

  my @names = $parser->identify('1;31');
    # or $parser->identify('1', '31');
  # returns ('bold', 'red')

Identifies attributes by their number;
Returns a B<list> of names.

This is similar to L<Term::ANSIColor/uncolor>.

Unknown codes will be ignored (remove from the output):

  $parser->identify('33', '52');
  # returns ('yellow') # drops the '52'

=cut

sub identify {
  my $self = shift;
  return
    grep { defined }
    map  { $ATTRIBUTES_R{ 0 + $_ } }
    map  { split /;/ }
    @_;
}

=method normalize

  my @norm = $parser->normalize(@attributes);

Takes a list of named attributes
(like those returned from L</identify>)
and reduces the list to only those that would have effect.

=for :list
* Duplicates will be removed
* a foreground color will overwrite any previous foreground color (and the previous ones will be removed)
* same for background colors
* C<clear> will remove all previous attributes

  my @norm = $parser->normalize(qw(red bold green));
  # returns ('bold', 'green');

=cut

sub normalize {
  my $self = shift;
  my @norm;
  foreach my $attr ( @_ ){
    if( $attr eq 'clear' ){
      @norm = ();
    }
    else {
      # remove previous (duplicate) occurrences of this attribute
      @norm = grep { $_ ne $attr } @norm;
      # new fg color overwrites previous fg
      @norm = grep { !exists $FOREGROUND{$_} } @norm if exists $FOREGROUND{$attr};
      # new bg color overwrites previous bg
      @norm = grep { !exists $BACKGROUND{$_} } @norm if exists $BACKGROUND{$attr};
      push @norm, $attr;
    }
  }
  return @norm;
}

=method parse

  my $marked = $parser->parse($output);

Parse the provided string
and return an array ref of array refs describing the formatting:

  # [
  #   [ [], 'plain words' ],
  #   [ ['red'], 'colored words' ],
  # [

These array refs are consistent with the arguments to
L<Term::ANSIColor/colored>:

  colored( ['red'], 'colored words' );

=cut

sub parse {
  my ($self, $orig) = @_;

  my $last_pos = 0;
  my $last_attr = [];
  my $parsed = [];

  while( my $matched = $orig =~ m/(\e\[([0-9;]+)m)/mg ){
    my $seq = $1;
    my $attrs = $2;

    # strip out any escape sequences that aren't colors
    # TODO: unicode flags?
    # TODO: make this an option
    #$str =~ s/[^[:print:]]//g;

    my $cur_pos = pos($orig);

    my $len = ($cur_pos - length($seq)) - $last_pos;
    push @$parsed, [
      $last_attr,
      substr($orig, $last_pos, $len)
    ]
      # don't bother with empty strings
      if $len;

    $last_pos = $cur_pos;
    $last_attr = [$self->normalize(@$last_attr, $self->identify($attrs))];
  }

    push @$parsed, [
      $last_attr,
      substr($orig, $last_pos)
    ]
      # if there's any string left
      if $last_pos < length($orig);

  return $parsed;
}

=func identify_ansicolor

Function wrapped around L</identify>.

=func normalize_ansicolor

Function wrapped around L</normalize>.

=func parse_ansicolor

Function wrapped around L</parse>.

=head1 EXPORTS

Everything listed in L</FUNCTIONS> is also available for export upon request.

=cut

our @EXPORT_OK;
BEGIN {
  eval join '', ## no critic (StringyEval)
    map { "sub ${_}_ansicolor { __PACKAGE__->new->$_(\@_) }" }
    @EXPORT_OK = qw(identify normalize parse);
}

sub import {
  my $class = shift;
  return unless @_;

  my $caller = caller;
  no strict 'refs'; ## no critic (NoStrict)

  foreach my $arg ( @_ ){
    die "'$arg' is not exported by $class"
      unless my $func = *{"${class}::$arg"}{CODE};
    *{"${caller}::$arg"} = $func;
  }
}

# TODO: option for blotting out 'concealed'? s/\S/ /g
# TODO: HTML::FromANSI::Tiny ?  like synopsis, options for tag_name, attr_name, or style_attr?

1;

# NOTE: this synopsis is tested (eval'ed) in t/synopsis.t

=head1 SYNOPSIS

  # output from some command
  my $output = "foo\e[31mbar\e[00m";

  my $ansi = Parse::ANSIColor::Tiny->new();
  my $marked = $ansi->parse($output);

  is_deeply
    $marked,
    [
      [ [], 'foo' ],
      [ ['red'], 'bar' ],
    ],
    'parse colored string';

  # don't forget to encode the html!
  my $html = join '',
    '<div>',
    (map { '<span class="' . join(' ', @{ $_->[0] }) . '">' . $_->[1] . '</span>' } @$marked),
    '</div>';

  is $html,
    '<div><span class="">foo</span><span class="red">bar</span></div>',
    'turned simple ansi into html';

=head1 DESCRIPTION

Parse a string colored with ANSI escape sequences
into a structure suitable for reformatting (into html, for example).

The output of terminal commands can be marked up with colors and formatting
that in some instances you'd like to preserve.

This module is essentially the inverse of L<Term::ANSIColor>.
The array refs returned from L</parse>
can be passed back in to L<Term::ANSIColor/colored>.
The strings may not match exactly due to different ways the attributes can be specified,
but the end result should be colored the same.

This is a C<::Tiny> module...
it attempts to be correct for most cases with a small amount of code.
It may not be 100% correct, especially in complex cases.
It only handles the C<m> escape sequence (C<\033[0m>)
which produces colors and simple attributes (bold, underline)
(like what can be produced with L<Term::ANSIColor>).

If you do find bugs please submit tickets (with patches, if possible).

=head1 SEE ALSO

=for :list
* L<Term::ANSIColor> - For marking up text that will be printed to the terminal
* L<HTML::FromANSI> - Specific to (old) html; As of 2.03 (released in 2007) tags are not customizable.  Uses L<Term::VT102> which is likely more robust but may be overkill in simple situations (and was difficult to install in the past).

=cut
