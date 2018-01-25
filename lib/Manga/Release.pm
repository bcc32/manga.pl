use 5.016;
use strict;
use warnings;

package Manga::Release;

use overload (
  '""' => \&str,
);

sub iso8601_date {
  my ($mdy) = @_;
  my ($m, $d, $y) = split '/', $mdy;
  "20$y-$m-$d";
}

sub new {
  my ($class, $date, $series, $volume, $chapter, $group) = @_;
  bless {
    date    => iso8601_date($date),
    series  => $series,
    volume  => $volume,
    chapter => $chapter,
    group   => $group,
  } => $class;
}

sub fields {
  my ($self) = @_;
  return [
    $self->{date},
    $self->{series},
    $self->{volume},
    $self->{chapter},
    $self->{group},
  ];
}

sub str {
  my ($self) = @_;
  join "\x1f", @{$self->fields};
}

1;
