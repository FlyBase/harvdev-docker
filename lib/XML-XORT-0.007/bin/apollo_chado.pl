use strict;
use Cwd;
use File::Spec;
use lib '/users/zhou/work/XML-XORT-0.007/xort';
use XML::XORT::Util::DbUtil::DB;
use XML::XORT::Dumper::DumperXML;
use XML::XORT::Util::GeneralUtil::Properties;
use XML::XORT::Util::GeneralUtil::Constants;
use strict;
use Getopt::Std;
use Getopt::Long;
use encoding 'utf8';

=head1
   Since Apollo is capable of read chado xml, so this intend to replace  apollo_cgi.pl
   if any question, contact pinglei zhou(zhou@morgan.harvard.edu) for overall or Frank Smutniak(frank@morgan.harvard.edu) from Chado2Game convertion
   perl apollo_cgi.pl -h
   1.gene FBgn# (or any other feature uniquename of a gene if Non-FlyBase data
   2.cytology region
   3.scaffold name
   4.region: start/end/arm
=cut


#set the start time
my $start_time=time();


#get some constant
my $constant_obj=XML::XORT::Util::GeneralUtil::Constants->new();
my $conf= $constant_obj->get_constant('CONF');
my $tmp=$constant_obj->get_constant('TMP');




#Application defaults
my $help        = 0;
my $gene        ='';
my $species     ='Dmel';#edit here for non-FlyBase user
my $database    = '';
my $range       =5000;
my $start       =0;
my $end         =9999999999;
my $scaffold    ='';
my $arm         ='';
my $type        =1;
my $cyto        ='';
my $output      = '';
my $ddl_property='ddl';
my $entity_declaration=2;
my $annotation=0;
my $debug=0;
my $cache_file='';


my $result = GetOptions(
			'help|?'               => \$help,
			'database|da=s'           => \$database,
			'gene|g=s'             => \$gene,
			'species|sp=s'          => \$species,
			'start|s=s'          => \$start,
			'end|e=s'           => \$end,
                        'range|n=s'      =>\$range,
			'arm|a=s'           => \$arm,
			'type|t=s'        => \$type,
                	'cyto|i=s'           => \$cyto,
			'output|o=s'           => \$output,
                        'ddl_property|y'       =>\$ddl_property,
                        'entity_declaration|en=s' =>\$entity_declaration,
                        'annotation|c=s'       =>\$annotation,
                        'debug|b=s'            =>\$debug,
                        'cache=s'              =>\$cache_file
			);



sub usage() {
	print <<EOF;
	
usage: $0 [-da database property file] [-t type] [-p output file] [-g gene ID] [-y cyto] [-l scaffold] [-s start_region] [-e end_region] [-a arm] [-c annotation type] [-en entity_declaration]

	--help, -h, -?                   : this (help) message
	--database, -da                  : name of XORT database property conf file
	--output file, -o file           : output xml file, if not given, output to STDOUT
	--species option, -sp option      : species abbreviation, Dmel(default),
                                           or Dmel, Comp, Dpse, Dere, Dgri, nDmoj, Dper, Dsec, Dwil, Dyak, Dmau, Dbuz, Dsim, Dana, Dvir, Dtak, Dleb, Dtsa
	--type option, -t                : input data type: 1 for Gene(-g), 2 for cytology(-y) 3 for scaffold(-l), 4 for Location(require -s -e -a)
        --gene option -g                 :gene uniquename
	--operation option, -op option   :'' /force/delete/update/insert/lookup
	--dumpspec dumpspec, -g dumpspec : dumpspec xml file which guide the dumper behavior
	--struct option, -s option       : module/single(default)
	--annotation, -c       		 : 1: dump annotation + computation data, 0: annotation only (default), 2 for including ARGS,
	--arm option, -a option          : arm name
        --scaffold option, -l option     : scaffold
        --cyto option, -i option         : cyto
        --start option, -s option        : start_region
        --end option -e                  : end region
        --neighbor -n                    : neighbour region, default will be 5000 bp, this only work for singe gene
        --ddl property file -y optin     :default will be ../conf/ddl.properties file
        --entity dec -en option           :1 use entity declaration for Greek chararcter, 0 write out raw data in UTF-8 (default)
	  --cache_file                   : cache file which pre-store some frequency-use terms

        example: $0 -t 1  -da chado -g FBgn0032184 -c 1 -o FBgn0032184.chado.xml
        example: $0 -t 2  -da chado -i 34A -o 34A.chado.xml
        example: $0 -t 3  -da chado -l  AE003701 -o AE003701.chado.xml
        example: $0 -t 4  -da chado -s 13002982 -e 13005448 -a 3L -o  3L_13002982-13005448.chado.xml
EOF
}


usage() and die() if ($help or !$result);

usage() and die "You must specify a database option." if (!$database);




$ddl_property=cwd."/".$ddl_property if ($ddl_property !~/\// && $ddl_property ne 'ddl');

#here you need to edit to reflect the actually directory of dumpspec file, there are many dumpspecs in the example dir
# print "\tDE DEBUG: annotation is: .$annotation.\n";
my $dump_spec="/users/zhou/document/FlyBase/dumpspec/dumpspec_apollo_no_evidence.xml";
   $dump_spec="/users/zhou/document/FlyBase/dumpspec/dumpspec_apollo_v3.0.xml" if  $annotation==1;
   $dump_spec=$conf."/dumpspec_apollo_ARGS.xml" if $annotation==2;
# print "\tDE DEBUG: dump_spec is: .$dump_spec.\n";

usage() and die "\nspecify a dumpspec not exist" if  !(-e $dump_spec);


my $scaffold_type="golden_path_region";
my $gene_type='gene';
my $arm_type="chromosome_arm";#since all annotated features will ONLY have ONE featureloc, no need to specify type of srcfeature

my $a;
my $file;
my $dbh_pro=XML::XORT::Util::GeneralUtil::Properties->new($database);
my %dbh_hash=$dbh_pro->get_dbh_hash();
   $dbh_hash{'ddl_property'}=$ddl_property;
my $dbh=XML::XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
   $dbh->open();

my $random_no=int(rand(10000000));
my $file_chado=$output;
my $mark;

#edit here if you have different implementation from FlyBase
my $species_id=$dbh->get_one_value(sprintf("select organism_id from organism where abbreviation='%s'", $species));
warn "\nunable to find the specified species:$species" and exit(1) if !(defined $species_id);
if ($type==1 && $gene=~/\w+/) {
 my $stm_gene=sprintf("select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename, f2.uniquename from feature f1, featureloc fl, cvterm c1,  feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='%s' and f2.feature_id=fl.srcfeature_id  and f1.uniquename='%s' and f1.organism_id=$species_id", $gene_type, $gene);

       my $table = $dbh->get_all_arrayref($stm_gene);
       for my $i ( 0 .. $#{$table} ) {
         my $start=$table->[$i][1]-$range;
            $start=0 if ($start<0);
         my $end=$table->[$i][2]+$range;
         # substitute the following value in dumpspec:srcfeature_id, start, end,title(ie. gene_name/region/scaffold_name), arm_name
         $a=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][3]." ".$table->[$i][4];
         my $CTG_a=$start.",".$end.",".$table->[$i][3];
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($database, $debug);
         $xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a, -loadable=>1,-ddl_property=>$ddl_property, -cache_conf=>$cache_file, -entity_declaration=>$entity_declaration);
      }
}
elsif ($type==2 && $cyto=~/\w+/) {
         my $hash_cyto_ref=&get_region_by_cyto($cyto);
         my $start=$hash_cyto_ref->{'FMIN'};;
            $start=0 if ($start<0);
         my $end=$hash_cyto_ref->{'FMIN'};
         $a=$hash_cyto_ref->{'ARM_ID'}." ".$hash_cyto_ref->{'FMIN'}." ".$hash_cyto_ref->{'FMAX'}." "."cyto_".$hash_cyto_ref->{'ARM'}." ".$hash_cyto_ref->{'ARM'};
         my $CTG_a=$start.",".$end.",".$hash_cyto_ref->{'ARM'};
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($database, $debug);
         $mark=$xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a,-ddl_property=>$ddl_property, -cache_conf=>$cache_file, -entity_declaration=>$entity_declaration);

}
elsif ($type==3 && $scaffold=~/\w+/) {
       my $stm_scaffold=sprintf("select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename, f2.uniquename from  feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='%s' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='%s' and f1.uniquename='%s' and f2.organism_id=$species_id", $scaffold_type, $arm_type, $scaffold); 
       my $table = $dbh->get_all_arrayref($stm_scaffold);
       for my $i ( 0 .. $#{$table} ) {
         my $start=$table->[$i][1];
            $start=0 if ($start<0);
         my $end=$table->[$i][2];
         # substitute the following value in dumpspec:srcfeature_id, start, end,title(ie. gene_name/region/scaffold_name), arm_name
         $a=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][3]." ".$table->[$i][4];
         my $CTG_a=$start.",".$end.",".$table->[$i][3];
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($database, $debug);
         $xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a,-ddl_property=>$ddl_property, -cache_conf=>$cache_file, -entity_declaration=>$entity_declaration);
      }
}
elsif ($type==4 && $arm=~/\w+/ && $start=~/^\d+$/ && $end=~/^\d+$/){
           my $stm_gene=sprintf("select f.feature_id, f.uniquename from  feature f where f.seqlen is not null and f.is_obsolete='false' and  f.uniquename='%s' and f.organism_id=$species_id ", $arm);

         my $table = $dbh->get_all_arrayref($stm_gene);
       for my $i ( 0 .. $#{$table} ) {
         my $start=$start;
            $start=0 if ($start<0);
         my $end=$end;
         $a=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][1]."_".$start."_".$end." ".$table->[$i][1];
         my $CTG_a=$start.",".$end.",".$table->[$i][1];
         my $xml_obj=XML::XORT::Dumper::DumperXML->new($database, $debug);
         $mark=$xml_obj->Generate_XML(-file=>$file_chado,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a,-ddl_property=>$ddl_property, -cache_conf=>$cache_file, -entity_declaration=>$entity_declaration);

      }
}
else {
usage();
}


my $end_time=time();
warn "\n$0 started:", scalar localtime($start_time),"\n";
warn "\n$0   ended:", scalar localtime($end_time),"\n";
$dbh->close();


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



