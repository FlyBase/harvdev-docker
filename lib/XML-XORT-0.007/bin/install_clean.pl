#this will remove all script derived from make process
use strict;
use FindBin '$Bin';

system ("rm lib/XML/XORT/Util/GeneralUtil/Constants.pm");
system ("rm lib/XML/XORT/Util/GeneralUtil/Properties.pm");
system ("rm bin/xort_loader.pl");
system ("rm bin/xort_validator.pl");
system ("rm bin/apollo_cgi.pl");
system ("rm bin/xort_dump.pl");
system ("rm bin/XORTDiff.pl");
system ("rm bin/xort_ddl_properties_creator.pl");
system ("rm make_util/conf_install.pl");

my $tmp_old=$Bin;
    $tmp_old=~s/bin/tmp/;
my $conf_old=$Bin;
   $conf_old=~s/bin/conf/;
open (IN, 'xort.conf') or die "unable to open xort.conf";
  while (<IN>){
    if (/\=/){
       my ($dir_name, $dir_clean)=split(/\=/);
       chomp($dir_clean);
       if ($dir_name eq 'LIB'){

          my $temp=$dir_clean;
          system("rm -Rf $temp");
          $temp=$dir_clean.'/sun4-solaris';
          system("rm -Rf $temp");
       }
       if ($dir_name eq 'TMP'  && $dir_clean ne $tmp_old) {
          system("rm -Rf $dir_clean");
          print "\ntmp_old:$tmp_old:$dir_clean:";
       }

       if ($dir_name eq 'CONF' && $dir_clean ne $conf_old) {
          system("rm -Rf $dir_clean");
          print "\nconf_old:$conf_old:$dir_clean";
       }
    }
  }
close(IN);

system("rm xort.conf");
