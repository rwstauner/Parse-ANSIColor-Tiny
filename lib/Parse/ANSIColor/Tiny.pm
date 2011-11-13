# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Parse::ANSIColor::Tiny;
# ABSTRACT: Determine attributes of ANSI-Colored string

# is it safe to use %Term::ANSIColor::ATTRIBUTES (_R) ?
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

sub new {
  my $class = shift;
  my $self = {
    @_ == 1 ? %{ $_[0] } : @_,
  };
  bless $self, $class;
}

sub names {
  my $self = shift;
  return grep { defined } map { $ATTRIBUTES_R{ 0 + $_ } } @_;
}

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

    my @attr = split /;/, $attrs;

    # TODO: inherit previous attributes
    # TODO: normalize attributes (red green) => green

    my $cur_pos = pos($orig);

    push @$parsed, [
      $last_attr,
      substr($orig, $last_pos, ($cur_pos - length($seq)) - $last_pos)
    ];

    $last_pos = $cur_pos;
    $last_attr = [$self->normalize(@$last_attr, $self->names(@attr))];
  }

    push @$parsed, [
      $last_attr,
      substr($orig, $last_pos)
    ]
      # if there's any string left
      if $last_pos < length($orig);

  return $parsed;
}

# TODO: exportable parse_ansi that generates a new instance
# TODO: option for blotting out 'concealed'? s/\S/ /g

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

  my $html = join '',
    '<div>',
    (map { '<span class="' . join(' ', @{ $_->[0] }) . '">' . $_->[1] . '</span>' } @$marked),
    '</div>';

  is $html,
    '<div><span class="">foo</span><span class="red">bar</span></div>',
    'turned simple ansi into html';

=head1 DESCRIPTION

=cut
