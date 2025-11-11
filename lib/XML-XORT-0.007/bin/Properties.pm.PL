use strict;
use Cwd;
use File::Basename qw(&basename &dirname);
use FindBin '$Bin';
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
#my $conf_file = catfile( $Local{'CONF_DIR'}, 'xort.conf' );

my $origdir = cwd;
chdir dirname($0);
my $file;
($file = basename($0)) =~ s/\.PL$//;
$file  = "$original_dir/lib/XML/XORT/Util/GeneralUtil/$file";
open OUT, ">$file" or die "Can't write file '$file': $!\n";
print OUT<<'NOGROK';
package XML::XORT::Util::GeneralUtil::Properties;
 use strict;
 use Cwd;
 use File::Spec;
NOGROK




print OUT <<"GROK!THIS!";
my \$CONF_DIR='$OPTIONS{CONF}';

GROK!THIS!


print OUT<<'NOGROK';




 sub new (){
  my $type=shift;
  my $self={};
  $self->{'name'}=shift;
  bless $self, $type;
  return $self;
 }

 sub get_dbh_hash(){
   my $self=shift;
   my $current_dir=File::Spec->rel2abs(File::Spec->curdir());

   my $file_name=$CONF_DIR."/".$self->{'name'}.".properties";
        warn "\nfilename:$file_name\n";
             open (IN, $file_name) or die "could not open $file_name";
       my  %dbh_hash;
       while (<IN>){
           my  $pair=$_;
             chomp $pair;
           if (index($pair, "\#")){
             my @temp=split(/\=/, $pair);
             $dbh_hash{$temp[0]} =$temp[1];
 	   }
       }
    return %dbh_hash;
}

# commment start with  #
 sub get_properties_hash(){
    my $self=shift;
    my $file_name;
    if (-e $self->{'name'} && -r $self->{'name'}){
       $file_name=$self->{'name'};
    }
    else {
       $file_name=$CONF_DIR."/".$self->{'name'}.".properties";
    }

       open (IN, $file_name) or die "either default ddl.properties not exist or you do not supply separate ddl property file";
       my  %dbh_hash; ;
       while (<IN>){
            my  $pair=$_;
            chomp $pair;
            if($pair !~/^\#/ && $pair=~/\S/){
              my @temp=split(/\=/, $pair);
              my $key=$temp[0];
              my $value=$temp[1];
	      if (defined $value && $value=~/\S/){
                 $dbh_hash{$key} =$value;
	      }
	}
       }
    return %dbh_hash;

 }

 1;
NOGROK
