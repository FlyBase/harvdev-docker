use lib '/export2/zhou/install_xort';
use XML::XORT::Util::DbUtil::DB;
use XML::XORT::Dumper::DumperXML;
use XML::XORT::Util::GeneralUtil::Properties;
use XML::XORT::Util::GeneralUtil::Constants;
use strict;
use Net::FTP;

#set start time
my $start=time();

my $dir_indiana="/nfs/hershel/export2/zhou/indiana";

# here we dump all genes by scaffold, which will for Don/Victor's browser. 


#set env for FTP server
my $server = "flybase.harvard.edu";
my $user = "ftpsite";
my $password="";
my $date = `date +%m%d`;
chomp $date;
my $local ;
my $remote_dir = "/u1/ftpsite/pinglei_tmp";
my $remote;

#get some constant
my $constant_obj=XML::XORT::Util::GeneralUtil::Constants->new();
my $conf= $constant_obj->get_constant('CONF');
my $tmp=$constant_obj->get_constant('TMP');

#my $stm_scaffold_id="select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='golden_path_region' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='chromosome_arm' and (f1.uniquename not like 'AE0036%' and  f1.uniquename not like 'AE0037%' and f1.uniquename not like 'AE0038%')";

#my $stm_scaffold_id="select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='golden_path_region' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='chromosome_arm' and (f1.uniquename  like 'AE0036%' or  f1.uniquename  like 'AE0037%' or  f1.uniquename  like 'AE0038%')";

my $stm_scaffold_id="select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='golden_path_region' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='chromosome_arm' and ( f1.uniquename='AE003429' or f1.uniquename='AE003426')";

#dump all scaffold
#my $stm_scaffold_id="select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='golden_path_region' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='chromosome_arm'";

my $a;
my $file;
my $db='chado_gadfly9_t11_gonzalez';
my $dump_spec=$conf."/dumpspec_indiana.xml";
   my $dbh_pro=XML::XORT::Util::GeneralUtil::Properties->new($db);
   my  %dbh_hash=$dbh_pro->get_dbh_hash();
   my  $dbh=XML::XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
   $dbh->open();




  my $table = $dbh->get_all_arrayref($stm_scaffold_id);
      for my $i ( 0 .. $#{$table} ) { 
          for my $j ( 0 .. $#{$table->[$i]} ) {
              print "$table->[$i][$j]\t";
          }
          $file=$dir_indiana."/".$table->[$i][3]."_r3.2.chado.xml";
          $a=$table->[$i][0]." ".$table->[$i][1]." ".$table->[$i][2]." ".$table->[$i][3];
          print "\n", $file , $a, "\n";
          my $xml_obj=XML::XORT::Dumper::DumperXML->new($db);
          $xml_obj->Generate_XML(-file=>$file,  -format_type=>'local_id', -op_type=>'' , -struct_type=>'single', -dump_spec=>$dump_spec,  -app_data=>$a) if (!(-e $file) || ((-e $file) && (-z $file)));
          #my $file_bzip2=$file.".bz2";
          #system("bzip2 $file");
          #my $ftp = Net::FTP->new($server, Debug => 3);
          #$ftp->login($user, $password);
          #$ftp->binary();
          #$local=$file_bzip2;
          #$remote=$remote_dir."/".$table->[$i][3]."_v7.0_0728.chado.xml.bz2";
          #$ftp->put($local, $remote);
          #$ftp->quit();
          #system("bin/rm $file");
     }


# start to bzip2 file and ftp to Indiana
print "\nstart to bzip2 file";
   my $ftp = Net::FTP->new($server, Debug => 3);
   $ftp->login($user, $password);
  $ftp->binary();
  my $table = $dbh->get_all_arrayref($stm_scaffold_id);
      for my $i ( 0 .. $#{$table} ) { 
          for my $j ( 0 .. $#{$table->[$i]} ) {
              print "$table->[$i][$j]\t";
          }
          $file=$dir_indiana."/".$table->[$i][3]."_r3.2.chado.xml";
          $a=$table->[$i][0]." ".$table->[$i][1]." ".$table->[$i][2]." ".$table->[$i][3];
          print $file , $a, "\n";
          my $file_bzip2=$file.".bz2";
          system("bzip2 $file");

          $local=$file_bzip2;
          $remote=$remote_dir."/".$table->[$i][3]."_r3.2.chado.xml.bz2";
          $ftp->put($local, $remote);
          #$ftp->delete( $remote);

          system("bin/rm $file");
     }
$ftp->quit();
$dbh->close();


#send email to Indiana
#open(MAIL,"| /usr/ucb/mail -s \"new chado dump files\" don victor harvdev ");
#print MAIL "Don, Victor,\n\nnew dump in pinglei_tmp directory.\n\n-Pinglei\n\n";
#close MAIL;



my $end=time();
print "\n$0 started:", scalar localtime($start),"\n";
print "\n$0   ended:", scalar localtime($end),"\n";
exit(1);

