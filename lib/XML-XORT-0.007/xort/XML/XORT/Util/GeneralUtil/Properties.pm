package XML::XORT::Util::GeneralUtil::Properties;
 use strict;
 use Cwd;
 use File::Spec;
my $CONF_DIR='/users/zhou/work/XML-XORT-0.007/conf';





 sub new (){
  my $type=shift;
  my $self={};
  $self->{'name'}=shift;
  bless $self, $type;
  return $self;
 }

 sub get_dbh_hash(){
   my $self=shift;
   my $current_dir=File::Spec->rel2abs(File::Spec->curdir());

   my $file_name=$CONF_DIR."/".$self->{'name'}.".properties";
        #warn "\nfilename:$file_name\n";
             open (IN, $file_name) or die "could not open $file_name";
       my  %dbh_hash;
       while (<IN>){
           my  $pair=$_;
             chomp $pair;
           if (index($pair, "\#")){
             my @temp=split(/\=/, $pair);
             $dbh_hash{$temp[0]} =$temp[1];
 	   }
       }
    return %dbh_hash;
}

# commment start with  #
 sub get_properties_hash(){
    my $self=shift;
    my $file_name;
    if (-e $self->{'name'} && -r $self->{'name'}){
       $file_name=$self->{'name'};
    }
    else {
       $file_name=$CONF_DIR."/".$self->{'name'}.".properties";
    }

       open (IN, $file_name) or die "either default ddl.properties not exist or you do not supply separate ddl property file";
       my  %dbh_hash; ;
       while (<IN>){
            my  $pair=$_;
            chomp $pair;
            if($pair !~/^\#/ && $pair=~/\S/){
              my @temp=split(/\=/, $pair);
              my $key=$temp[0];
              my $value=$temp[1];
	      if (defined $value && $value=~/\S/){
                 $dbh_hash{$key} =$value;
	      }
	}
       }
    return %dbh_hash;

 }

 1;
