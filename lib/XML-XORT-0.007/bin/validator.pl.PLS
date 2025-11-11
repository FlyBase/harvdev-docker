use strict;
use Cwd;
use File::Basename qw(&basename &dirname);
use FindBin '$Bin';
use File::Spec::Functions;
use Config;

#check whether those script will install locally or be part of perl
my $use_lib_string="";
my $original_dir=cwd;
my %OPTIONS;
if (open F,"$Bin/../xort.conf" or print "unable to open $Bin/../xort.conf") {
  while (<F>) {
    next if /^\#/;
    chomp;
    $OPTIONS{$1} = $2 if /^(\w+)\s*=\s*(.+)/;
  }
  close F;
}

if (defined $OPTIONS{LIB} ) {
   $use_lib_string="use lib \'".$OPTIONS{LIB}."\';";
}

my $origdir = cwd;
chdir dirname($0);
my $file;
($file = basename($0)) =~ s/\.PLS$//;
$file = "xort_$file";
open OUT, ">$file" or die "Can't write file '$file': $!\n";

print "Extracting $file (with variable substitutions)\n";
print OUT <<"GROK!THIS!";
$Config{startperl}
use strict;
use Cwd;
use File::Spec;
$use_lib_string
GROK!THIS!

print OUT<<'NOGROK';
use XML::XORT::Util::GeneralUtil::Properties;
use Getopt::Std;

#set start time
my $start=time();

my $VALIDATION_NO_DB=0;
my $VALIDATION_DB=1;

my %opt;
getopts('h:d:v:b:y:a:s:f:', \%opt) or usage() and exit;

sub usage()
 {
  print "\nusage: $0 [-d database] [-f file]  [-v validate_level]",
    "\n -a batch delete       : 0 for no batch delete(default), 1 to allow batch delete",
    "\n -h                 : this (help) message",
    "\n -d                 : database",
    "\n -f xml file        : file to be valiated",
    "\n -b debug           : 0: no debug message(default), 1: debug message",
    "\n -s log send to STDOUT : 0 for log send to file(default), 1 to STDOUT",
    "\n -v validate_level  : 0 no database connection valiation, 1 for DB connection validation",
    "\n -y ddl property file :default will be ../conf/ddl.properties file",
    "\n\nexample: $0  -d chado_gadfly7 -f /users/zhou/work/tmp/AE003828_chadox.xml -v 0",
    "\n\nexample: $0  -d chado_test -f /users/zhou/work/tmp/AE003828_chadox.xml -v 1\n\n";
}

usage() and exit if $opt{h};

$opt{v}=$VALIDATION_NO_DB if !($opt{v});
$opt{b}=0 if !($opt{b});
$opt{a}=0 if !($opt{a});
$opt{s}=0 if !($opt{s});
$opt{y}='ddl' if !($opt{y});

usage() and exit if ((!$opt{d} && $opt{v} eq $VALIDATION_DB) || !$opt{f});

my $validate_db_obj;
my $validate_no_db_obj;

if ($opt{v} eq $VALIDATION_DB){
   print "\nuse connection......";
   use XML::XORT::Loader::XMLValidator;
   $validate_db_obj=XML::XORT::Loader::XMLValidator->new(-dbname=>$opt{d}, -file=>$opt{f}, -debug=>$opt{b},-delete_batch=>$opt{a},-ddl_property=>$opt{y},-STDOUT=>$opt{s});
   $validate_db_obj->validate_db(-validate_level=>$opt{v});
}
elsif ($opt{v} eq $VALIDATION_NO_DB){
   print "\nnot use connection......";

   use XML::XORT::Loader::XMLValidatorNoDB;
   $validate_no_db_obj=XML::XORT::Loader::XMLValidatorNoDB->new(-file=>$opt{f},-debug=>$opt{b},-delete_batch=>$opt{a},-ddl_property=>$opt{y},-STDOUT=>$opt{s});
   $validate_no_db_obj->validate(-validate_level=>$opt{v});
}

my $end=time();
warn "\nvalidator started:", scalar localtime($start),"\n";
warn "\nvalidator   ended:", scalar localtime($end),"\n";




NOGROK
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;

