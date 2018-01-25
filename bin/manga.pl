use 5.016;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Readonly;
use Text::CSV;

use Manga::Scraper qw(get_page_releases);

# TODO get from options
Readonly my $DBFILE  => 'releases.dat';
Readonly my $NEWFILE => 'new.csv';
Readonly my $PAGES   => 5;
Readonly my $RS      => "\x1e";         # ASCII Record Separator

sub read_old {
  local $/ = $RS;
  open my $fh, '<:encoding(utf8)', $DBFILE or return;

  my %old;
  while (my $line = <$fh>) {
    $old{$line} = 1;
  }
  \%old;
}

sub main {
  my $old_href = read_old();

  open my $dbfh,  '>>:encoding(utf8)', $DBFILE;
  open my $newfh, '>>:encoding(utf8)', $NEWFILE;

  # only affects $dbfh since $csv has its own eol setting
  local $\ = $RS;

  my $csv = Text::CSV->new({ binary => 1 });
  $csv->eol("\n");

  for my $page (reverse 1..$PAGES) {
    my $releases_aref = get_page_releases($page);
    for my $release (@$releases_aref) {
      unless (exists $old_href->{$release}) {
        $csv->print($newfh, $release->fields);
        print $dbfh $release;
      }
    }
  }
}

main() unless caller();
