#!/usr/local/bin/perl

eval 'exec /usr/local/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
use strict;
use Cwd;
use File::Spec;
use lib '/users/zhou/work/XML-XORT-0.007/xort';
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





