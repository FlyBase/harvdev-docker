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
use XML::XORT::Loader::XMLParser;
use Getopt::Std;
use XML::XORT::Util::GeneralUtil::Constants;

# --------------------------
# loader.pl to load chado xml into chado database
# i.e: loader.pl -d chado_test -f "/users/zhou/work/tmp/AE003828_chadox.xml" -i 0
# ---------------------------

#set start time
my $start=time();

my %opt;
getopts('h:d:f:y:i:a:b:', \%opt) or usage() and exit;

sub usage()
 {
  print "\nusage: $0 [-d database] [-f file] [-i is_recovery]",

    "\n -h              : this (help) message",
    "\n -d              : database",
    "\n -f xml file     : file to be loaded into database",
    "\n -i is_recovery  : 0 for no recovery 1 for recovery",
    "\n -b debug        : 0 for no debug message(default),  1 for debug message",
    "\n -a batch delete       : 0 for no batch delete(default), 1 to allow batch delete",
    "\n -y ddl property file :default will be ../conf/ddl.properties file",
    "\nexample: $0  -d chado_gadfly9_t3_gonzalez -f /nfs/hershel/export2/zhou/GTC/chado/CG9932.bev.fix.xml -i 0 -b 1\n\n";
}

usage() and exit if $opt{h};

#default for i:0
$opt{i}=0 if !($opt{i});
$opt{a}=0 if !($opt{a});

#default for b:0
$opt{b}=0 if !($opt{b});
$opt{y}='ddl' if !(defined $opt{y});
usage() and exit if (!$opt{d} || !$opt{f});

usage() and exit if (!$opt{d} || !$opt{f});

my $parse_obj=XML::XORT::Loader::XMLParser->new($opt{d}, $opt{f}, $opt{b}, $opt{a},$opt{y});
   $parse_obj->load(-is_recovery=>$opt{i});

my $end=time();
print "\n$0 started:", scalar localtime($start),"\n";
print "\n$0   ended:", scalar localtime($end),"\n";





NOGROK
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;

