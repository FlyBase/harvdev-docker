use strict;
use Cwd;
use File::Basename qw(&basename &dirname);
use File::Spec::Functions;

my $original_dir=cwd;
my %OPTIONS;
if (open F,"$original_dir/xort.conf" or print "unable to open $original_dir/xort.conf") {
  while (<F>) {
    next if /^\#/;
    chomp;
    $OPTIONS{$1} = $2 if /^(\w+)\s*=\s*(.+)/;
  }
  close F;
}

$OPTIONS{CONF} ||='/usr/local/conf';
$OPTIONS{TMP} ||='/usr/local/tmp';
#my $conf_file = catfile( $Local{'CONF_DIR'}, 'xort.conf' );

my $HASH_STRING;
foreach my $key (keys %OPTIONS) {
    $HASH_STRING=$HASH_STRING.$key."=>'".$OPTIONS{$key}."',\n";
}
$HASH_STRING="(".$HASH_STRING.");";

my $file;
($file = basename($0)) =~ s/\.PL$//;
$file  = "$original_dir/lib/XML/XORT/Util/GeneralUtil/$file";

open OUT, ">$file" or die "Can't write file '$file': $!\n";

print "Extracting $file (with variable substitutions)\n";
print OUT<<"GROK";
package XML::XORT::Util::GeneralUtil::Constants;
use strict;
use Cwd;
use File::Spec;

my \%CONSTANT=$HASH_STRING
GROK

print  OUT <<'NOGROK';

sub new (){
    my $type=shift;
    my $self={};
    bless $self, $type;
    return $self;
}

sub get_constant (){
  my $self=shift;
  my $key=shift;
  return $CONSTANT{$key};
}

sub add_constant(){
  my $self=shift;
  my $key=shift;
  my $value=shift;
   $CONSTANT{$key}=$value;;
}

1;
NOGROK
