use strict;
use Cwd;
use File::Spec;
use lib '/export2/zhou/install_xort';
use XML::XORT::Util::DbUtil::DB;
use XML::XORT::Dumper::DumperXML;
use XML::XORT::Util::GeneralUtil::Properties;
use XML::XORT::Util::GeneralUtil::Constants;
use strict;
use Getopt::Std;


=head1
   Since Apollo is capable of read chado xml, so this intend to replace  apollo_cgi.pl
   if any question, contact pinglei zhou(zhou@morgan.harvard.edu) for overall or Frank Smutniak(frank@morgan.harvard.edu) from Chado2Game convertion
   perl apollo_cgi.pl -h
   1.gene CG#
   2.cytology region
   3.scaffold name
   4.region: start/end/arm
=cut


#set the start time
my $start=time();

my %opt;

getopts('h:i:k:n:d:b:g:s:o:e:t:c:y:l:a:', \%opt) or usage() and exit;


usage() and exit if $opt{h};
usage() and print "\nsorry, you miss -d ...\n\n" and  exit if (!$opt{d});
usage() and print "\nsorry, you miss -t ...\n\n" and  exit if (!$opt{t});
#usage() and print "\nsorry, you miss -o ...\n\n" and  exit if (!$opt{o});


#get some constant
my $constant_obj=XML::XORT::Util::GeneralUtil::Constants->new();
my $conf= $constant_obj->get_constant('CONF');
my $tmp=$constant_obj->get_constant('TMP');



$opt{'b'}=0 if (!$opt{'b'});

#adjacent region for mini-xml
my $range=5000;
$range=$opt{'n'} if (defined $opt{'n'});
$opt{y}='ddl' if !(defined $opt{y});
$opt{y}=cwd."/".$opt{y} if ($opt{y}!~/\// && $opt{y} ne 'ddl');

my $db=$opt{d};
 $opt{'c'}=0 if (!$opt{'c'});
my $dump_spec;

my $dump_spec=$conf."/dumpspec_apollo_no_evidence.xml";
   $dump_spec="/users/zhou/document/FlyBase/dumpspec/dumpspec_apollo_.xml" if  $opt{'c'}==1;
   $dump_spec=$conf."/dumpspec_apollo_ARGS.xml" if $opt{'c'}==2;


my $scaffold_type="golden_path_region";
my $gene_type='gene';
my $arm_type="chromosome_arm";
my $species='melanogaster';
my $a;
my $file;
my $DEBUG=$opt{'b'};
my $dbh_pro=XML::XORT::Util::GeneralUtil::Properties->new($db);
my %dbh_hash=$dbh_pro->get_dbh_hash();
   $dbh_hash{'ddl_property'}=$opt{y};
my $dbh=XML::XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
   $dbh->open();

my $random_no=int(rand(10000000));
my $file_chado=$opt{'o'};
my $mark;

if ($opt{t}==1 && defined $opt{g}) {
       my $stm_gene=sprintf("select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename, f2.uniquename from organism o, feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='%s' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='%s' and f1.uniquename='%s' and o.organism_id=f2.organism_id and o.species='%s'", $gene_type, $arm_type, $opt{g}, $species);
       my $table = $dbh->get_all_arrayref($stm_gene);
       for my $i ( 0 .. $#{$table} ) {
         my $start=$table->[$i][1]-$range;
            $start=0 if ($start<0);
         my $end=$table->[$i][2]+$range;
         # substitute the following value in dumpspec:srcfeature_id, start, end,title(ie. gene_name/region/scaffold_name), arm_name
         $a=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][3]." ".$table->[$i][4];
         my $CTG_a=$start.",".$end.",".$table->[$i][3];
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($db, $DEBUG);
         $xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a, -loadable=>1,-ddl_property=>$opt{y}, -cache_conf=>$opt{k});
      }
}
elsif ($opt{t}==2 && defined $opt{i}) {
         my $hash_cyto_ref=&get_region_by_cyto($opt{i});
         my $start=$hash_cyto_ref->{'FMIN'};;
            $start=0 if ($start<0);
         my $end=$hash_cyto_ref->{'FMIN'};
         $a=$hash_cyto_ref->{'ARM_ID'}." ".$hash_cyto_ref->{'FMIN'}." ".$hash_cyto_ref->{'FMAX'}." "."cyto_".$hash_cyto_ref->{'ARM'}." ".$hash_cyto_ref->{'ARM'};
         my $CTG_a=$start.",".$end.",".$hash_cyto_ref->{'ARM'};
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($db, $DEBUG);
         $mark=$xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a,-ddl_property=>$opt{y}, -cache_conf=>$opt{k});

}
elsif ($opt{t}==3 && defined $opt{l}) {
       my $stm_scaffold=sprintf("select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename, f2.uniquename from organism o, feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='%s' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='%s' and f1.uniquename='%s' and f2.organism_id=o.organism_id and o.species='melanogaster'", $scaffold_type, $arm_type, $opt{l}); 
       my $table = $dbh->get_all_arrayref($stm_scaffold);
       for my $i ( 0 .. $#{$table} ) {
         my $start=$table->[$i][1];
            $start=0 if ($start<0);
         my $end=$table->[$i][2];
         # substitute the following value in dumpspec:srcfeature_id, start, end,title(ie. gene_name/region/scaffold_name), arm_name
         $a=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][3]." ".$table->[$i][4];
         my $CTG_a=$start.",".$end.",".$table->[$i][3];
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($db, $DEBUG);
         $xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a,-ddl_property=>$opt{y}, -cache_conf=>$opt{k});
      }
}
elsif ($opt{t}==4 && defined $opt{s} && defined $opt{e} && defined $opt{a}){
          my $stm_gene=sprintf("select f.feature_id, f.uniquename from organism o, feature f, cvterm c where f.type_id=c.cvterm_id and c.name='%s' and f.uniquename='%s' and f.organism_id=o.organism_id and o.species='%s'",  $arm_type, $opt{a}, $species);

         my $table = $dbh->get_all_arrayref($stm_gene);
       for my $i ( 0 .. $#{$table} ) {
         my $start=$opt{s};
            $start=0 if ($start<0);
         my $end=$opt{e};
         $a=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][1]."_".$start."_".$end." ".$table->[$i][1];
         my $CTG_a=$start.",".$end.",".$table->[$i][1];
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($db, $DEBUG);
         $mark=$xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a,-ddl_property=>$opt{y}, -cache_conf=>$opt{k});

      }
}


my $end=time();
warn "\n$0 started:", scalar localtime($start),"\n";
warn "\n$0   ended:", scalar localtime($end),"\n";
$dbh->close();

sub usage()
 {
  print "\nusage: $0 [-d database] [-f file] [-i is_recovery]",


    "\n -h              : this (help) message",
    "\n -t              : input data type: 1 for Gene(-g), 2 for cytology(-y) 3 for scaffold(-l), 4 for Location(require -s -e -a)",
    "\n -d              : database",
    "\n -o              : output chado xml",
    "\n -g              : CG##",
    "\n -n              : neighbour region, default will be 5000 bp, this only work for singe gene",
    "\n -s              : start_region",
    "\n -e              : end_region",
    "\n -l              : scaffold",
    "\n -a              : arm name",
    "\n -c              : 1: dump annotation + computation data, 0: annotation only (default), 2 for including ARGS, 3 for new schema test",
    "\n -b debug        : 0:no debug message(default), 1:debug message",
    "\n -i              : cyto name",
    "\n -k cache conf   :a configure file to define what objects to be cached, must be valid dumpspec file",
    "\nexample: $0 -t 1  -d chado -g CG31188 -o CG31188.chado.xml\n\n",
    "\nexample: $0 -t 2  -d chado -y 34A -o 34A.chado.xml\n\n",
    "\nexample: $0 -t 3  -d chado -l  AE003701 -o AE003701.chado.xml\n\n",
    "\nexample: $0 -t 4  -d chado -s 13002982 -e 13005448 -a 3L -o  3L_13002982-13005448.chado.xml\n\n";

}


sub get_region_by_cyto(){
   my $cyto=shift;
   my $cyto_original=$cyto;
   if ($cyto=~/\-/){
       $cyto=$2;
   }
   $cyto="\U$cyto";
   $cyto="band-".$cyto;
   my $stm_cyto=sprintf("select f.uniquename as cyto_name, fl2.fmin as cyto_fmin, fl2.fmax as cyto_fmax, f3.uniquename, f3.feature_id from feature f, featureloc fl, feature f2, featureloc fl2, feature f3, cvterm c  where f.feature_id = fl.srcfeature_id and fl.feature_id = f2.feature_id and f2.feature_id = fl2.feature_id and f.type_id =c.cvterm_id and c.name='chromosome_band' and fl2.srcfeature_id=f3.feature_id and fl2.rank = 0 and f.is_analysis = 'f' and f.uniquename='%s'", $cyto);
   my $array_cyto = $dbh->get_all_arrayref($stm_cyto);
   my %hash_cyto;
   print "\nno location information for this cyto: $cyto\n" and exit(1) if ($#{$array_cyto} !=0);
   $hash_cyto{'CYTO'}=$cyto_original;
   $hash_cyto{'FMIN'}=$array_cyto->[0][1];
   $hash_cyto{'FMAX'}=$array_cyto->[0][2];
   $hash_cyto{'ARM'}=$array_cyto->[0][3];
   $hash_cyto{'ARM_ID'}=$array_cyto->[0][4];


  return \%hash_cyto;
  }



