use 5.016;
use strict;
use warnings;

package Manga::Scraper;

BEGIN {
  require Exporter;
  our @ISA       = qw(Exporter);
  our @EXPORT    = ();
  our @EXPORT_OK = qw(get_page_releases);
}

use HTML::Parser;
use HTTP::Tiny;
use Readonly;

use Manga::Release;

Readonly my $BASE_URL => 'https://www.mangaupdates.com/releases.html';
Readonly my $PERPAGE  => 100;

my $http = HTTP::Tiny->new;

sub get_page_html {
  my ($n) = @_;

  my $params = $http->www_form_urlencode({
    act     => 'archive',
    perpage => $PERPAGE,
    page    => $n,
  });
  my $url = "$BASE_URL?$params";
  # TODO refactor to use data callbacks
  my $resp = $http->get($url);

  $resp->{success} or die "$resp->{status} $resp->{reason}";

  $resp->{content};
}

sub get_page_releases {
  my ($n) = @_;

  my @releases;

  # set up parser state machine
  my @fields;
  my $field;
  my $capture = 0;
  my $start = sub {
    my ($tagname, $attr_href) = @_;
    if ($tagname eq 'tr') {
      @fields = ();
    } else {
      # identify table fields by bgcolor attr
      if (exists $attr_href->{bgcolor}) {
        $field = '';
        $capture = 1;
      }
    }
  };
  my $end = sub {
    my ($tagname) = @_;
    if ($tagname eq 'tr') {
      push @releases, Manga::Release->new(@fields) if @fields;
    } else {
      push @fields, $field if $capture;
      $capture = 0;
    }
  };
  my $text = sub { $field .= $_[0] if $capture };

  my $p = HTML::Parser->new(
    api_version => 3,
    start_h     => [$start, 'tagname, attr'],
    end_h       => [$end,   'tagname'],
    text_h      => [$text,  'dtext'],
  );
  $p->report_tags(qw(tr td));

  my $html = get_page_html($n);
  $p->parse($html);

  # ascending by date
  [reverse @releases];
}

1;
