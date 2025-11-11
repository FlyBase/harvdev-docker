package XML::XORT::Util::GeneralUtil::Constants;
use strict;
use Cwd;
use File::Spec;

my %CONSTANT=(DBUSER=>'zhou',
DBHOST=>'fogel',
DBNAME=>'fb_2007_01',
DBPORT=>'5432',
SQLFILE=>'/users/zhou/work/XML-XORT-0.007/examples/chado.ddl',
LIB=>'/users/zhou/work/XML-XORT-0.007/xort',
DBPASS=>'zhoupgsql',
CONF=>'/users/zhou/work/XML-XORT-0.007/conf',
TMP=>'/users/zhou/work/XML-XORT-0.007/tmp',
);

sub new (){
    my $type=shift;
    my $self={};
    bless $self, $type;
    return $self;
}

sub get_constant (){
  my $self=shift;
  my $key=shift;
  return $CONSTANT{$key};
}

sub add_constant(){
  my $self=shift;
  my $key=shift;
  my $value=shift;
   $CONSTANT{$key}=$value;;
}

1;
