use 5.016;
use strict;
use warnings;
use autodie;

use FindBin;
use lib "$FindBin::Bin/../lib";

use IO::Interactive qw( interactive );
use Readonly;
use Text::CSV;

use Manga::Scraper qw( get_page_releases );

# TODO get from options
Readonly my $DBFILE  => 'releases.dat';
Readonly my $NEWFILE => 'new.csv';
Readonly my $PAGES   => 50;
Readonly my $RS      => "\x1e";         # ASCII Record Separator

interactive->autoflush(1);

sub read_old {
  no autodie qw( open );

  open my $fh, '<:encoding(utf8)', $DBFILE or return;

  local $/ = $RS;

  my %old;
  while (my $line = <$fh>) {
    chomp $line;
    $old{$line} = 1;
  }
  \%old;
}

sub _progress {
  print { interactive } '.';
}

sub main {
  my $old_href = read_old();

  open my $dbfh,  '>>:encoding(utf8)', $DBFILE;
  open my $newfh, '>>:encoding(utf8)', $NEWFILE;

  my $csv = Text::CSV->new({ binary => 1 });
  $csv->eol("\n");

  for my $page (reverse 1..$PAGES) {
    my $releases_aref = get_page_releases($page);
    for my $release (@$releases_aref) {
      unless (exists $old_href->{$release}) {
        $csv->print($newfh, $release->fields);
        print $dbfh $release, $RS;
      }
    }
    _progress();
    sleep 2;
  }
}

main() unless caller();
