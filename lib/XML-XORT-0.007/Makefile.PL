
#use 5.006001;
use ExtUtils::MakeMaker;
use Cwd;
use strict;
use FindBin '$Bin';
use File::Copy;
use File::Spec::Functions qw[ catfile catdir ];

my %env2arg = (
  CHADO_DB_NAME     => 'DBNAME',
  CHADO_DB_USERNAME => 'DBUSER',
  CHADO_DB_PASSWORD => 'DBPASS',
  CHADO_DB_HOST     => 'DBHOST',
  CHADO_DB_PORT     => 'DBPORT',
  CONF              => 'CONF',
  TMP               => 'TMP',
  GMOD_ROOT         => 'GMOD_ROOT',
  SQLFILE           => 'SQLFILE',
);

my $usage = <<"END";
To customize install locations, provide one or more of the options
CONF, TMP, and any other known MakeMaker parameter, as in CONF=/usr/local/conf
                                                                                
for example:
    perl Makefile.PL CONF=/usr/local/conf \\
                     TMP=/usr/local/tmp
                                                                                
                                                                                
Also supported are:
 DBNAME         Database name
 DBUSER         Database user name
 DBPASS         Database password
 DBHOST         Database hostname (default 'localhost')
 DBPORT         Database port (default 5432)
 SQLFILE        Database DDL file (no default)
 GMOD_ROOT      If used with GMOD applications, the root directory                                                                                
END
;



my $VERSION  = '0.007';
my $working_dir = cwd;
my @OPTIONS  = qw(DBNAME DBUSER DBPASS DBHOST DBPORT 
                  CONF TMP LIB SQLFILE GMOD_ROOT LIB PREFIX);
my $OPTIONS  = join ('|',@OPTIONS);
my %OPTIONS;

my $all_args = join( '|', qw[ RECONFIGURE DEFAULTS ], $OPTIONS );
my $all_envs = join( '|', keys %env2arg );
my %opts;
my @argv = @ARGV;
@ARGV    = (); # empty out @ARGV so MakeMaker doesn't get

#this will overwrite the default install dir, also all execute files will have a line: use lib '$install_dir';
my $install_dir;


# this just checks for --help and --GMOD_ROOT, other
# flags a processed later
foreach (@argv) {
  if ( /^--?h(elp)?$/i ) {
    die $usage;
  }
  elsif (/^GMOD_ROOT=(.+)/) {
    $opts{'GMOD_ROOT'}=$1;
  }
  elsif (/^LIB=(.+)/) {
    push @ARGV, $_;
    $install_dir=$1;
  }
}

unless ($opts{'GMOD_ROOT'}) {
    if ($ENV{'GMOD_ROOT'}) {
        $opts{'GMOD_ROOT'}=$ENV{'GMOD_ROOT'};
    }
}

my $gmod = 0;
if (eval {require Bio::GMOD::Config;
          Bio::GMOD::Config->import();
          require Bio::GMOD::DB::Config;
          Bio::GMOD::DB::Config->import();
          1;  } ) {
 
  print "I've detected that you have Bio::GMOD::Config, Do you want\n";
  $gmod = prompt("me to use the default db parameters provided by it?", 'y'); 
  $gmod = ($gmod =~ /^[yY]/) ? 1 : 0;

  if ($gmod) {
    my $gmod_conf = $opts{'GMOD_ROOT'} ?
                    Bio::GMOD::Config->new($opts{'GMOD_ROOT'}) :
                    Bio::GMOD::Config->new();
    my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf,'default');


    %OPTIONS  =  (
      DBNAME    => {
        default => $db_conf->name()
      },
      DBUSER    => {
        default => $db_conf->user()
      },
      DBPASS    => {
        default => $db_conf->password()
      },
      DBHOST    => {
        default => $db_conf->host()
      },
      DBPORT    => {
        default => $db_conf->port()
      },
      CONF      => {
        default => catdir ($gmod_conf->confdir(), "XORT")
      },
      TMP       => {
        default => catdir ($gmod_conf->tmpdir(), "XORT")
      },
      SQLFILE   => {
        default => $db_conf->sqlfile()
      },
    );
  }
} #close if Bio::GMOD::Config
else {
  %OPTIONS  =  (
    DBNAME    => {
      default => $ENV{'CHADO_DB_NAME'}
    },
    DBUSER    => {
      default => $ENV{'CHADO_DB_USERNAME'} || $ENV{'USER'}
    },
    DBPASS    => {
      default => $ENV{'CHADO_DB_PASSWORD'}
    },
    DBHOST    => {
      default => $ENV{'CHADO_DB_HOST'} || $ENV{'HOST'} ||
                 scalar gethostent || 'localhost'
    },
    DBPORT    => {
      default => $ENV{'CHADO_DB_PORT'} || 5432
    },

    CONF      => {
      default => $ENV{'GMOD_ROOT'} ?
                 catdir ($ENV{'GMOD_ROOT'}, 'XORT', 'conf') :
                 catdir ($working_dir, 'conf')
    },
    TMP       => {
      default => $ENV{'GMOD_ROOT'} ?
                 catdir ($ENV{'GMOD_ROOT'}, 'XORT', 'tmp') :
                 catdir ($working_dir, 'tmp')
    },
    SQLFILE   => {
      default => $ENV{'GMOD_ROOT'} ?
                 catdir ($ENV{'GMOD_ROOT'}, 'modules', 'complete.sql') :
                 catdir ($working_dir, 'examples/chado.ddl')
    },
  );
}

my %conf;
my $build_config =  catfile $working_dir, 'xort.conf';
if (!$gmod && -e $build_config && !@argv ) {

    my $answer = prompt(
    "Previous configuration detected.\nUse values in '$build_config'?", 'Y'
    );
  
    if ($answer =~/^[yY]/) { 

        warn "Using previous settings for file paths and options.\n";
        open F,'xort.conf' or die "unable to open:xort.conf: $!";
        while (<F>) {
            chomp;
            next if /^\#/;
            next unless /^($OPTIONS)=(.+)/o;
            $conf{$1} = interpolate($2);
        }
        close F;

        $opts{'RECONFIGURE'} = $answer =~ /^[Yy]/ ? 1 : 0;
    
    }
}

# this checks command line arguments first then env variables
# so the that user can override the enviroment
foreach ( @argv ) {
  if ( /^($all_args)=(.+)$/ ) {
    $opts{ $1 } = $2;
  }
  elsif ( /^($all_envs)=(.+)$/ ) {
    $OPTIONS{ $env2arg{$1} }{ default } = $2;
  }
}

#
# Now figure out where the values are coming from -- build.conf,
# command-line, or prompt().
#
my ( $DBNAME, $DBUSER, $DBPASS, $DBHOST, $DBPORT,
     $CONF, $TMP, $SQLFILE, $LIB, $PREFIX );

if ($gmod) {
    $opts{'DEFAULTS'} = 1;  
}

if ( $opts{'RECONFIGURE'} && %conf ) {
  $DBNAME   = $conf{'DBNAME'}   || '';
  $DBUSER   = $conf{'DBUSER'}   || '';
  $DBPASS   = $conf{'DBPASS'}   || '';
  $DBHOST   = $conf{'DBHOST'}   || '';
  $DBPORT   = $conf{'DBPORT'}   || '';
  $TMP      = $conf{'TMP'}      || '';
  $CONF     = $conf{'CONF'}     || '';
  $SQLFILE  = $conf{'SQLFILE'}  || '';
  $LIB      = $conf{'LIB'}      || '';
  $PREFIX   = $conf{'PREFIX'}   || '';
}
elsif ( $opts{'DEFAULTS'} ) {
  $DBNAME   = $OPTIONS{'DBNAME'}{'default'};
  $DBUSER   = $OPTIONS{'DBUSER'}{'default'};
  $DBPASS   = $OPTIONS{'DBPASS'}{'default'};
  $DBHOST   = $OPTIONS{'DBHOST'}{'default'};
  $DBPORT   = $OPTIONS{'DBPORT'}{'default'};
  $TMP      = $OPTIONS{'TMP'}{'default'};
  $CONF     = $OPTIONS{'CONF'}{'default'};
  $SQLFILE  = $OPTIONS{'SQLFILE'}{'default'};
}
elsif ( %opts ) {
  $DBNAME   = $opts{'DBNAME'}   || '';
  $DBUSER   = $opts{'DBUSER'}   || '';
  $DBPASS   = $opts{'DBPASS'}   || '';
  $DBHOST   = $opts{'DBHOST'}   || '';
  $DBPORT   = $opts{'DBPORT'}   || '';
  $TMP      = $opts{'TMP'}      || '';
  $CONF     = $opts{'CONF'}     || '';
  $SQLFILE  = $opts{'SQLFILE'}  || '';
  $LIB      = $opts{'LIB'}      || '';
  $PREFIX   = $opts{'PREFIX'}   || '';
}

if ( !$gmod && !$opts{'DEFAULTS'} && !$opts{'RECONFIGURE'} ) {
  #
  # Make sure everything has a value and looks kosher.
  #
  $DBNAME ||= prompt( 'What is the database name?',
    $conf{'DBNAME'} || $OPTIONS{'DBNAME'}{'default'}
  );
               
  $DBUSER ||= prompt( 'What is the database username?',
    $conf{'DBUSER'} || $OPTIONS{'DBUSER'}{'default'}
  );
                         
  $DBPASS ||= prompt( "What is the password for '$DBUSER'?",
    $conf{'DBPASS'} || $OPTIONS{'DBPASS'}{'default'}
  );
                 
  $DBHOST ||= prompt( 'What is the database host?',
    $conf{'DBHOST'} || $OPTIONS{'DBHOST'}{'default'}
  );

  $DBPORT ||= prompt( 'What is your database port?',
    $conf{'DBPORT'} || $OPTIONS{'DBPORT'}{'default'}
  );

  $TMP ||= prompt( 'Where will the tmp directory go?',
    $conf{'TMP'} || $OPTIONS{'TMP'}{'default'}
  );

  $CONF ||= prompt( 'Where will the conf directory go? warning:it will re-create dir if NOT use default, saving your OWN files before overwrite',
    $conf{'CONF'} || $OPTIONS{'CONF'}{'default'}
  );

  $SQLFILE ||= prompt( 'Where is the DDL file?',
    $conf{'SQLFILE'} || $OPTIONS{'SQLFILE'}{'default'}
  );

  $install_dir = prompt( 'where do you want to install XORT if other than default(e.g,/users/zhou/xort), press ENTER if default:') if !(defined $install_dir);
  if ($install_dir !~/^\/[\w\W]+\w$/){
     undef $install_dir ;
  }
  else {
    my $LIB_string='LIB='.$install_dir;
    push @ARGV, $LIB_string;
  }

}


#
# Save build options.
#
if ( open CONF, ">$build_config" ) {
  $conf{'DBNAME'}   = $DBNAME;
  $conf{'DBUSER'}   = $DBUSER;
  $conf{'DBPASS'}   = $DBPASS;
  $conf{'DBHOST'}   = $DBHOST;
  $conf{'DBPORT'}   = $DBPORT;
  $conf{'TMP'}      = $TMP;
  $conf{'CONF'}     = $CONF;
  $conf{'SQLFILE'}  = $SQLFILE;
  $conf{'LIB'}=$install_dir if defined $install_dir;
  print CONF "# This hints file contains configuration information used by the XORT\n\n";
  print CONF "# To reconfigure, run perl Makefile.PL `cat xort.conf`\n\n";

  print CONF map { "$_=$conf{ $_ }\n" } keys %conf;
  close CONF or die "Can't write file '$build_config': $!\n";
}


#CONF and TMP directory stuff shouldn't happen until install
#but the local version of chado.properties should be created now

my $local_conf_dir = catdir $working_dir, 'conf';
my $chado_prop     = catfile $local_conf_dir, 'chado.properties';

open PROP, ">$chado_prop" or die "Couldn't open $chado_prop: $!";
print PROP <<END_PROP;
db_type=postgres
db=$DBNAME
host=$DBHOST
port=$DBPORT
user=$DBUSER
password=$DBPASS
END_PROP
;
close PROP;

#these need to change so the the .PL files don't get installed
# in PERL5LIB
system("perl", "$working_dir/bin/Properties.pm.PL");
system("perl", "$working_dir/bin/Constants.pm.PL");

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'XML::XORT',
    VERSION          => $VERSION,
    PREREQ_PM        => {
                          'XML::Parser::PerlSAX' => 0,
                          #'Unicode::String'      => 0,
                          'XML::DOM'             => 0,
                          #'XML::XQL'             => 0,
                          #'Cache::MemoryCache'   => 0,
                          'DBI'                  => 0
                         }, # e.g., Module::Name => 1.1
    PL_FILES       => { 
                        'bin/validator.pl.PLS'  =>'bin/xort_validator.pl',
                        'bin/loader.pl.PLS'     =>'bin/xort_loader.pl',
                        'bin/apollo_cgi.pl.PLS' =>'bin/apollo_cgi.pl',
                        'bin/XORTDiff.pl.PLS'   =>'bin/XORTDiff.pl',
                        'bin/dump.pl.PLS'       =>'bin/xort_dump.pl',
                        'bin/ddl_properties_creator.pl.PLS' 
                                        =>'bin/xort_ddl_properties_creator.pl',
                        'make_util/conf_install.pl.PLS'
                                        =>'make_util/conf_install.pl',
	              },
    EXE_FILES       => [
                        'bin/xort_validator.pl',
                        'bin/xort_loader.pl',
                        'bin/XORTDiff.pl',
                        'bin/xort_dump.pl',
                        'bin/xort_ddl_properties_creator.pl',
                        ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT      => "A generic module for mapping relational schema to XML",
       AUTHOR        => 'Pinglei Zhou <zhou@morgan.harvard.edu>') : ()),
);



sub MY::clean {
  package MY;
  my $inherited = shift->SUPER::clean(@_);
  $inherited .= "\t-\$(PERL) bin/install_clean.pl\n";
  $inherited;
}

sub MY::install {
    package MY;
    my $inherited = shift->SUPER::install(@_);
    $inherited =~ s/doc_install/doc_install conf_install/;
    $inherited;
}

sub interpolate {
  my $path = shift;
  my ($to_expand,$homedir);
  return $path unless $path =~ m!^~([^/]*)!;
  eval {
    if ($to_expand = $1) {
      $homedir = (getpwnam($to_expand))[7];
    } else {
      $homedir = (getpwuid($<))[7];
    }
    return $path unless $homedir;

    $path =~ s!^~[^/]*!$homedir!;
  };
  return $path;
}

sub MY::postamble {
qq{
conf_install ::
	\$(PERL) $working_dir/make_util/conf_install.pl
}
}
