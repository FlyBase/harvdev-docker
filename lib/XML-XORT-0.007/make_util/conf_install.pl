#!/usr/local/bin/perl
use strict;
use File::Copy;
use File::Spec::Functions qw/ :DEFAULT splitdir /;
use FindBin '$Bin';
use lib '/users/zhou/work/XML-XORT-0.007/xort';
my $conf = "/users/zhou/work/XML-XORT-0.007/conf";
my $tmp  = "/users/zhou/work/XML-XORT-0.007/tmp";
my $sql  = "/users/zhou/work/XML-XORT-0.007/examples/chado.ddl";

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

