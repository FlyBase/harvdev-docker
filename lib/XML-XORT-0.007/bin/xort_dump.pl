#!/usr/local/bin/perl
use strict;
use Cwd;
use File::Spec;
use lib '/users/zhou/work/XML-XORT-0.007/xort';
use XML::XORT::Util::GeneralUtil::Properties;
use XML::XORT::Dumper::DumperXML;
use XML::XORT::Util::DbUtil::DB;
use Getopt::Long;
use encoding 'utf8';
#set the start time
my $start=time();

#Application defaults
my $help        = 0;
my $struct      = 'single';
my $database    = '';
my @tables;
my $format      = 'local_id';
my $operation   = '';
my $output      = '';
my $debug       = 0;
my $dump_spec   = '';
my $loadable    = 0;
my @app_data;
my $ddl_property='';
my $cache_config='';
my $entity_declaration=0;

my $result = GetOptions(
			'help|?'               => \$help,
			'struct=s'             => \$struct,
			'database=s'           => \$database,
			'tables=s'             => \@tables,
			'format=s'             => \$format,
			'operation=s'          => \$operation,
			'output|p=s'           => \$output,
			'debug|b:s'            => \$debug,
			'dumpspec|g=s'         => \$dump_spec,
			'loadable=s'           => \$loadable,
			'app_data=s'           => \@app_data,
                        'ddl_property|y:s'       =>\$ddl_property,
                        'cache_config|k:s'       =>\$cache_config,
                        'entity_declaration=s' =>\$entity_declaration
			);

sub usage() {
	print <<EOF;
	
usage: $0 [-da database property file] [-p output] [-f format_type] [-t tables] [-op op_type] [-g dumpspec] [-s struct_type] [-l loadable] [-k cache_file] [-y 

	--help, -h, -?                   : this (help) message
	--database, -da                  : name of XORT database property conf file
	--output file, -p file           : output xml file, if not given, output to STDOUT
	--format option, -f option       : local_id/no_local_id
	--tables tables, -t              : a colon delimited list of tables to dump
	--operation option, -op option   :'' /force/delete/update/insert/lookup
	--dumpspec dumpspec, -g dumpspec : dumpspec xml file which guide the dumper behavior
	--struct option, -s option       : module/single(default)
	--debug, -b        		 : print debugging messages (default: off)
	--loadable option, -l option     : 1 for loadable, 0 for non_loadable
        --app_data values, -a values     : data for dumpspec if using variable in dumpspec, separate by space for multiple values
        --cache confi file,-k            :a configure file to define what objects to be cached, must be valid dumpspec file",
        --ddl property file -y optin     :default will be ../conf/ddl.properties file
        --entity dec -e option           :1 use entity declaration for Greek chararcter or 0 write out raw data in UTF-8 (default) 2: use plain text",

        if you provide dumpspec, struct_type, loadable and tables will be ignored
	
	example1: $0  -da chado -g \"../conf/dumpspec_gene.xml\" -p \"/export/zhou/dump_gene_no_local_id.xml\" -f no_local_id -b 1

	example2: $0  -da chado_gadfly7 -g \"../conf/dumpspec_scaffold.xml\" -p \"/export/zhou/dump_scaffold_local_id.xml\" -f local_id -a \"1 14473012 14476172 AE002603\" -b 1

	example3: $0  -da chado_test -p /export/zhou/dump_temp_local_id.xml -f local_id -op force -s module -t \"feature:cvterm\"
EOF
}


usage() and die() if ($help or !$result);

usage() and die "You must specify a database option." if (!$database);

my $tables   = join(':',@tables);
my $app_data = join(' ',@app_data);

usage() and die "\nyou must either specify a dumpspec or table(s)" if ( !(-e $dump_spec) && $tables!~/\w+/);
my $xml_obj=XML::XORT::Dumper::DumperXML->new($database, $debug);
$xml_obj->Generate_XML(-tables=>$tables,-file=>$output, -struct_type=>$struct, -format_type=>$format, -op_type=>$operation, -dump_spec=>$dump_spec, -loadable=>$loadable, -app_data=>$app_data,-ddl_property=>$ddl_property, -cache_conf=>$cache_config, -entity_declaration=>$entity_declaration);


my $end=time();
warn "\n$0 started:", scalar localtime($start),"\n";
warn "\n$0   ended:", scalar localtime($end),"\n";

