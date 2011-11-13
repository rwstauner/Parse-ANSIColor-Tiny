# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Parse::ANSIColor::Tiny;
# ABSTRACT: Determine attributes of ANSI-Colored string

# is it safe to use %Term::ANSIColor::ATTRIBUTES (_R) ?
our @COLORS = qw( black red green yellow blue magenta cyan white );
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
  (map { (               $COLORS[$_] =>  30 + $_ ) } 0 .. $#COLORS),
  (map { (       'on_' . $COLORS[$_] =>  40 + $_ ) } 0 .. $#COLORS),
  (map { (   'bright_' . $COLORS[$_] =>  90 + $_ ) } 0 .. $#COLORS),
  (map { ('on_bright_' . $COLORS[$_] => 100 + $_ ) } 0 .. $#COLORS),
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

    my @attr = map { 0 + $_ } split /;/, $attrs;

    # TODO: inherit previous attributes
    # TODO: normalize attributes (red green) => green

    my $cur_pos = pos($orig);

    push @$parsed, [
      $last_attr,
      substr($orig, $last_pos, ($cur_pos - length($seq)) - $last_pos)
    ];

    $last_pos = $cur_pos;
    $last_attr = [map { $ATTRIBUTES_R{ $_ } } @attr];
    # if the last entry is clear/reset that's as good as no attributes
    $last_attr = [] if $last_attr->[-1] eq 'clear';
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

1;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
