use strict;
use Cwd;
use File::Basename qw(&basename &dirname);
use FindBin '$Bin';
use File::Spec::Functions;
use Config;
                                                                                
#check whether those script will install locally or be part of perl
my $use_lib_string="";
my $tmp = my $sql = my $conf = "";
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
                                                                                
$use_lib_string="use lib \'".$OPTIONS{LIB}."\';" if (defined $OPTIONS{LIB} );
$conf          = $OPTIONS{CONF} if (defined $OPTIONS{CONF} ); 
$tmp           = $OPTIONS{TMP} if (defined $OPTIONS{TMP} );
$sql           = $OPTIONS{SQLFILE} if (defined $OPTIONS{SQLFILE} );

my $origdir = cwd;
chdir dirname($0);
my $file;
($file = basename($0)) =~ s/\.PLS$//;
open OUT, ">$file" or die "Can't write file '$file': $!\n";
print "Extracting $file (with variable substitutions)\n";
print OUT <<"GROK!THIS!";
$Config{startperl}
use strict;
use File::Copy;
use File::Spec::Functions qw/ :DEFAULT splitdir /;
use FindBin '\$Bin';
$use_lib_string
my \$conf = "$conf";
my \$tmp  = "$tmp";
my \$sql  = "$sql";

GROK!THIS!

print OUT<<'NOGROK';
my $tmp_old=$Bin;
 $tmp_old=~s/make_util/tmp/;
my $conf_old=$Bin;
 $conf_old=~s/make_util/conf/;
make_dir($tmp) if ($tmp ne $tmp_old);

if ($conf && $conf ne $conf_old) {
    make_dir($conf);

    warn "Copying files to $conf ...\n";
    my $local_conf = "$Bin/../conf";
    opendir CONF, $local_conf
        or die "unable to opendir $local_conf for reading:$!";
    while (my $file = readdir(CONF) ) {
        my $localfile = catfile($local_conf, $file);
        if (-f $localfile) {
            my $targetfile= catfile($conf,       $file);
            copy($localfile, $targetfile)
                or die "Unable to copy to $targetfile: $!";
        }
    }
    closedir(CONF);
    warn "Done\n";
}

if ($sql) {
    warn "Creating ddl.properties file ... \n";

    my $creator=$Bin;
    $creator=~s!make_util/*!bin/xort_ddl_properties_creator.pl!;

    system ("perl $creator -d  $sql") && die "property creation failed";
    warn "Done\n";
}

sub make_dir {
    my $full_path = shift;
    my @tmpdirs = splitdir($full_path);
    my $tmpdir = "";
    foreach my $dir (@tmpdirs) {
        $tmpdir = catdir($tmpdir, $dir);
        if (!(-e $tmpdir)) {
            warn "Making directory $tmpdir ...\n";
            mkdir ($tmpdir,0777) or die "Unable to create $tmpdir: $!";
        }
    }
}

NOGROK
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;

