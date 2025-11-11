=head1 NAME

         XML::XORT::Loader::XMLParser - module to load XORT XML into DB

=head1 SYNOPSIS

         my $loader_obj=XML::XORT::Loader::XMLParser->new(-dbname=>'chado',
                                                           -file=>$xort_file,
                                                           -debug=>0 );
         $loader_obj->load(-is_recovery=>1);

=head1 DESCRIPTION

        This is the basic module which will load XORT-FORMAT XML into DB

=cut

=head1 CONTACT

        Pinglei Zhou, FlyBase fellow at Harvard University (zhou@morgan.harvard.edu)

=cut

=head1 METHODS

=cut




# Loader for xml file using SAX
package XML::XORT::Loader::XMLParser;
use XML::Parser::PerlSAX;
use XML::XORT::Util::DbUtil::DB;
use strict;
use XML::XORT::Loader::XMLAccession;
use XML::XORT::Util::GeneralUtil::Constants;
#use Unicode::String qw(latin1 utf8);
# This one is modified on 1/29/2003 for the dtd: chado_1.0.dtd
# Different from XML_parser1_copy.pm
# 1. use DB.insert/delete/update intead of data_type_checker
# 2. table_element attributes: id/op


# update:
#   1. use unique columns to identify the record
#   2. for non_unique_key col, just update
#   3. for unique_key col, need to save the updated record, cascade for all following records
#   4. how to differentiate the data and data_sub ?

# Parsing algorithmas
# 1. Based on the element name to get the table name
# 2. all data in %hash_data or %hash_data_sub, the key will be parent_element.self_element
# 3. End of Element: if the element is table_id: retrive all the element with parent as table_id from %hash_data_sub into %hash_temp
#        call _replace_id(\%hash_temp, $table_id, '','') to get the id
#        if table_id is col of THIS table, save into %hash_data, otherwise, save back into %hash_data_sub



# --------------------------------------------------------
# global variable
# -------------------------------------------------------
my %hash_ddl;
my $level=1;

my $element_name;
my $table_name;
my $db;
my $dbh_obj;
my %hash_table_col;
# this hash will have the pair of local_id/db_id, eg. cvterm_99 from xml file, id from cvterm_id 88, the key format: table_name:local_id, value: db_id
# with this format, it can also trace all the deletion because of cascade
my %hash_id;

#  store the 'text' for no 'update', index for array: level, key for hash: table.col,  value: 'text' data
my @AoH_data;
# store the 'text' for 'update', index for array: level, key for hash: table.col,  value: 'text' data
my @AoH_data_new;

# those store the data for db_id/local_id/op/ref, index for array: level, key for hash: element_name
my @AoH_db_id;
my @AoH_local_id;
my @AoH_op;
my @AoH_ref;

# key: $level, value: local_id/element_name/op/ref
my %hash_level_id;
my %hash_level_name;
my %hash_level_op;
my %hash_level_ref;
#this hash use to test whether self has sub_element, start_element: save $level/1, end_element: delete $hash_level_sub_detect{$level-1}
my %hash_level_sub_detect;
#root element, if you use different root , change here
my $root_element='chado';
my $APP_DATA_NODE='_appdata';
my $SQL_NODE='_sql';

# all the operator
my $OP_FORCE='force';
my $OP_UPDATE='update';
my $OP_INSERT='insert';
my $OP_DELETE='delete';
my $OP_LOOKUP='lookup';

# all attribute
my $ATTRIBUTE_ID='id';
my $ATTRIBUTE_OP='op';
my $ATTRIBUTE_REF='ref';
my $ATTRIBUTE_NULL='null';

my $DDL_FILE='ddl';
my $DEBUG=0;
my $DELETE_BATCH=0; #this to flag the force deletion requested by Aubrey, which do batch deletion based on partial of unique keys
# for some elements, it will be ignored, i.e view, and _app_data,
# algorithms to filter out ignore elements: initiately P_pseudo set to -1, for tables_pseudo, increase by 1 at beginning of start_element,  decrease by 1 at end of end_element
# if P_pseudo >-1, then do nothing for start_element, end_element, character
my $TABLES_PSEUDO='table_pseudo';
my %hash_tables_pseudo;
my $P_pseudo=-1;

#here undefined at begin of start_element, save when come to end_element
my $character;

# all the table which has dbxref_id, and primary key can be retrieved by accession
my %hash_accession_entry=(
dbxref=>1,
pub=>1,
feature=>1,
cvterm=>1,
);

# this hash will contain all the data for the current parsing table(which also is the subelement of root element)
my %hash_trans;
# this indicate whether we start the parsing from beginning or some point in the middle
my $recovery_status=0;
my $log_file;

#get constant value
my $constant_obj=XML::XORT::Util::GeneralUtil::Constants->new();
my $conf= $constant_obj->get_constant('CONF');
my $tmp= $constant_obj->get_constant('TMP');

#declare it as public, so it can return the line number
my $parser;
#use to set value as null: <name null="true"/>, then set the value as 'IS_NULL'
my $att_null='false';
my $data_null="NULL";
sub new (){
 my $type=shift;
 my $self={};
# $self->{'db'}=shift;
# $self->{'file'}=shift;
# $DEBUG=shift;
# $db=$self->{db};


 my ($dbname, $xml_file, $debug,$delete_batch,$ddl_file ) =
     XML::XORT::Util::GeneralUtil::Structure::rearrange(['dbname','file','debug','delete_batch','ddl_property'], @_);
     $self->{'db'}=$dbname;
     $self->{'file'}=$xml_file;
     $DEBUG=$debug;
     $db=$self->{db};
     $DELETE_BATCH=$delete_batch if (defined $delete_batch);
 #load the properties file
     if (defined $ddl_file && $ddl_file =~/\w+/ && $ddl_file ne $DDL_FILE && !(-e $ddl_file)){
        warn "\nthe ddl file you provide does not exist:\n$ddl_file" and die ();
     }
     elsif (defined $ddl_file && $ddl_file =~/\w+/ && ($ddl_file eq $DDL_FILE || -e  $ddl_file)){
        $DDL_FILE=$ddl_file ;
     }

 my $pro=XML::XORT::Util::GeneralUtil::Properties->new($DDL_FILE);
 %hash_ddl=$pro->get_properties_hash();

 # load the elements which need to be filtered out
 my @array_pseudo=split(/\s+/, $hash_ddl{$TABLES_PSEUDO});
 foreach my $value(@array_pseudo){
   $hash_tables_pseudo{$value}=1;
   print "\npseudo:$value" if ($DEBUG==1);
 }


# under all thos hash and arrary, otherwise, it will intervense for batch executing
undef $level;
undef %hash_table_col;
undef %hash_id;
undef @AoH_data;
undef @AoH_data_new;
undef @AoH_db_id;
undef @AoH_local_id;
undef @AoH_op;
undef @AoH_ref;
undef %hash_level_id;
undef %hash_level_name;
undef %hash_level_op;
undef %hash_level_ref;
undef %hash_level_sub_detect;


 print "\n start to parse xml file .....\n";
 bless $self, $type;
 return $self;
}

=head2 load

  Arg [1]    : none

  Example    : $obj->load();
  Description: public method which do the loading job
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut

sub load (){
   my $self=shift;

   my ($is_recovery) =
     XML::XORT::Util::GeneralUtil::Structure::rearrange(['is_recovery'], @_);
   if ($is_recovery ==1 || $is_recovery eq '1'){
     $recovery_status=$is_recovery;
   }
   my $file=$self->{file};
   $db=$self->{db};
   my $dbh_pro=XML::XORT::Util::GeneralUtil::Properties->new($db);
    my %dbh_hash=$dbh_pro->get_dbh_hash();
    $dbh_hash{'ddl_property'}=$DDL_FILE;
    $dbh_obj=XML::XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
    $dbh_obj->open();
 #  $dbh_obj->set_autocommit();

    my @temp=split(/\/+/, $file);
    my $temp_file=$temp[$#temp];
    $log_file=$tmp."/".'load_'.$temp_file.".log";
    print "\n start to load the  xml file , if problem, will write log file to:$log_file\n";
    $parser = XML::Parser::PerlSAX->new(Handler=>MyHandler_Parser->_new( ));
  $parser->parse (Source=>{SystemId=>$file});

}

#add those two variables to contral the DOM parse process, which add additional XML structure validation
my $node_DOM;
my $node_DOM_current;
my $doc=new XML::DOM::Document();

 package MyHandler_Parser;
 use XML::XORT::Util::DbUtil::DB;
 use XML::DOM;
# use Unicode::String qw(latin1 utf8);#comment out 13/09/2006 since all data from XML::Parse in utf8 format as default
# keys: all the foreign keys
my %hash_foreign_key;
my $foreign_keys=$hash_ddl{'foreign_key'};
if (defined $foreign_keys){
my @temp=split(/\s+/, $foreign_keys);
for my $i(0..$#temp){
  $hash_foreign_key{$temp[$i]}=1;
}
}


 sub _new {
  my $type=shift;
  my $self={};
  $self->{'file'}=shift;
  return bless {}, $type;
 }


 sub start_document {
   #all the variable defined in new method is unreachable for all other method
   # so here is good place to initiate some varables
    my (@temp,$is_symbol, $is_fb_id, $db_xref, $op_table, $op_column, %hash_table_col);

    # if recovery from middle of file, load back those information for object referencing
    if (-e $log_file && ($recovery_status eq '1' || $recovery_status ==1)) {
        open (LOG, $log_file) or die "\ncould not open the log file,";
        while (<LOG>){
           my ($local_id, $db_id)=split(/\t+/);
           $hash_id{$local_id}=$db_id;
	}
      close(LOG);
    }
   elsif (!(-e $log_file) && ($recovery_status eq '1' || $recovery_status ==1)) {
      print "\n are you sure you have run this before ?\nif first time parsing, please set the is_recovery=>0\n" if ($DEBUG==1);
      exit(1);
   }
   else {
        print "\nIf you parse this xml file from the beginning, you can safely delete this file:\n" if ($DEBUG==1);
        system("rm $log_file") if (-e $log_file);

   } 
    $node_DOM=$doc->createElement('chado');
    $node_DOM_current=$node_DOM;
 }


# start_element: at the beginning of start_element, $level ++, if ELEMENT_PSEUDO,then $P_seudo increase by 1.  
 sub start_element {

     my ($self, $element) = @_;
     #characters() may be called more than once for each element because of entity
     $level++;
     $hash_level_sub_detect{$level}=1;
     $element_name=$element->{'Name'};
     print "\nstart_element:$element_name" if ($DEBUG==1);

     # here to check whether it is ELEMENT_pseudo
     if (defined $hash_tables_pseudo{$element_name}){
        $P_pseudo++;
     }


     #part of  DOM structure for extra structure validation
     # you could take this section out to speed up the loading process if you are confident with your chado xml structure or you already run validator
     my $node_element=$doc->createElement($element_name);
     my $line=$parser->location()->{LineNumber};
     my $node_text=$doc->createTextNode($line);
     $node_element->appendChild($node_text);
     if (defined $element->{'Attributes'} && defined  $element->{'Attributes'}->{$ATTRIBUTE_OP}  && $element->{'Attributes'}->{$ATTRIBUTE_OP} ne ""){
        $node_element->setAttribute($ATTRIBUTE_OP, $element->{'Attributes'}->{$ATTRIBUTE_OP});
     }
     $node_DOM_current->appendChild($node_element);
     $node_DOM_current=$node_element;
     my $name_parent=$node_DOM_current->getParentNode()->getTagName();
     if (defined $hash_ddl{$element_name}){ #self: table element
      if (defined $hash_ddl{$name_parent}){ #parent: table element, this is link table, then must be some cols element before it.
          my $sibling=$node_DOM_current->getParentNode()->getFirstChild ();
          my $flag_sibling=0;
          my $name_sib;
          while (defined $sibling){ #here to find at least one COL element before link table
	    if ($sibling->getNodeType()==ELEMENT_NODE()){
               $name_sib=$sibling->getTagName();
               $flag_sibling=1;
               last;
	    }
            $sibling=$sibling->getNextSibling();
	  }
          if ($flag_sibling==0 || defined $hash_ddl{$name_sib}){
             print "\nno COL element before link table element:$element_name at $line";
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
	  }

      }
      elsif ($name_parent ne $root_element) { #parent: col, then grandparent also must be table: 
         my $ref_col=&_get_table_columns($element_name);
         my $name_grandparent=$node_DOM_current->getParentNode()->getParentNode()->getTagName();
         my $key=$name_grandparent.":".$name_parent."_ref_table";
 	 if ($hash_ddl{$key} ne $element_name) {
             print "\n3 wrong nesting:$name_grandparent:$name_parent:$element_name: at $line" ;
             &_create_log(\%hash_trans, \%hash_id, $log_file);
             exit(1);
	 }
      }
    }
    elsif ( ! defined $hash_ddl{$element_name} && $element_name ne $root_element && $element_name ne $SQL_NODE){ #self:col
      my $ref_col=&_get_table_columns($name_parent);
      if (! (defined $hash_ddl{$name_parent})){#parent is not table
          print "\nwrong nest here:COLS element:$element_name nested within COLS element:$name_parent at $line";
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
      }
      else { #parent is table, and all existed previous sibling must be cols of SAME parent, also should be NO text value like this: <feature>a<name>b</name></feature>
         #print "\n$name_parent\t$element_name";
         if (!(defined  $ref_col->{$element_name})){
         	print "\ncol:$element_name nested with WRONG parent:$name_parent at $line";
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                 exit(1);
  	 }
         my $sibling=$node_DOM_current->getPreviousSibling();
         my $name_sibling;
         my $attribute_op_parent=($node_DOM_current->getParentNode())->getAttribute($ATTRIBUTE_OP);
         #print "\nelement_name:$element_name\n" if ($element_name eq "organism_dbxref");
         while (defined $sibling ){
            if ($sibling->getNodeType()==ELEMENT_NODE()){
               $name_sibling=$sibling->getTagName();
               if ( defined $hash_ddl{$name_sibling}){

                  print "\nerror here:link table $name_sibling should always AFTER instead of before cols:$element_name of parent:$name_parent at line:$line" ;
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                 exit(1);
    	       }
               elsif ($name_sibling eq $element_name){
                  my $attribute_op_self=$node_DOM_current->getAttribute($ATTRIBUTE_OP);
                  my $attribute_op_sibling=$sibling->getAttribute($ATTRIBUTE_OP);
                  if (!($attribute_op_parent eq $OP_UPDATE && ($attribute_op_self eq $OP_UPDATE || $attribute_op_sibling eq $OP_UPDATE))){
                    &_create_log(\%hash_trans, \%hash_id, $log_file);
                    print "\ndumplicate cols:$element_name for same table:$name_parent at $line\n";  exit(1);
		  }


	       }

             }
             $sibling=$sibling->getPreviousSibling();
         }
     }
   }



 #for those within ELEMENT_PSEUDO, do nothing
 if ($P_pseudo==-1) {
    # store the transaction information
    if (defined $hash_ddl{$element_name} && $hash_level_name{$level-1} eq $root_element){
       $hash_trans{'table'}=$element_name;
    }

     # save the id attributed into local_id
     my $local_id=$element->{'Attributes'}->{$ATTRIBUTE_ID};
     my $db_id;
     my $op=$element->{'Attributes'}->{$ATTRIBUTE_OP};
     my $ref=$element->{'Attributes'}->{$ATTRIBUTE_REF};
        $att_null=$element->{'Attributes'}->{$ATTRIBUTE_NULL};
        $att_null="\L$att_null" if  (defined $att_null);#print "\nelement_name:$element_name:att_null:$att_null:";
    if ($local_id && $local_id ne ''){
      #$local_id= utf8($local_id)->latin1;
      $local_id=~ s/\&amp;/\&/g;
      $local_id=~ s/\&lt;/</g;
      $local_id=~ s/\&gt;/>/g;
      $local_id=~ s/\&quot;/\"/g;
      $local_id=~ s/\&apos;/\'/g;
       $local_id=~ s/\\/\\\\/g;
       $hash_level_id{$level}=$local_id;
       $AoH_local_id[$level]{$element_name}=$local_id;
    }
    else {
       delete $hash_level_id{$level};
       delete $AoH_local_id[$level]{$element_name};
    }
    if ($op && $op ne ''){
      $op=~ s/\&amp;/\&/g;
      $op=~ s/\&lt;/</g;
      $op=~ s/\&gt;/>/g;
      $op=~ s/\&quot;/\"/g;
      $op=~ s/\&apos;/\'/g;
      $op=~ s/\\/\\\\/g;
       $hash_level_op{$level}=$op;
       $AoH_op[$level]{$element_name}=$op; 
    }
    else {
       delete $hash_level_op{$level};
       delete $AoH_op[$level]{$element_name};
    }

    if ($ref && $ref ne ''){
      #$ref= utf8($ref)->latin1;
      $ref=~ s/\&amp;/\&/g;
      $ref=~ s/\&lt;/</g;
      $ref=~ s/\&gt;/>/g;
      $ref=~ s/\&quot;/\"/g;
      $ref=~ s/\&apos;/\'/g;
       $ref=~ s/\\/\\\\/g;
       $hash_level_ref{$level}=$ref;
       $AoH_ref[$level]{$element_name}=$ref;
       print "\nref for this element:$element_name is :$ref" if ($DEBUG==1);
    }
    else {
       delete $hash_level_ref{$level};
       delete $AoH_ref[$level]{$element_name};
    }
    $hash_level_name{$level}=$element_name;


    #here to undef all old data before characters, since it might call characters more than once, it will concantate all previous data????
    # data will be in @AoH_data or @AoH_data_new: index of array: $level, key of hash: $table_name.$column
    my $hash_ref_temp=$AoH_data[$level];
    foreach my $key (keys %$hash_ref_temp){
         my ($junk, $element_name_temp)=split(/\./, $key);
         if ($element_name eq $element_name_temp && $AoH_op[$level]{$element_name} ne 'update'){
           delete $AoH_data[$level]{$key};
	 }
         elsif ($element_name eq $element_name_temp && $AoH_op[$level]{$element_name} eq 'update'){
           delete $AoH_data_new[$level]{$key};
	 }
    }



    # if self is table_element
    if (defined $hash_ddl{$element_name} ){
       # check if parent_element is table_element
       # when come to subordinary table(e.g cvrelationship), and previous sibling element is not table column(if is, it alread out) out it  output primary table(e.g cvterm)
       $table_name=$element_name;
       if (  defined $hash_ddl{$hash_level_name{$level-1}}){
	  print "\nstart to output the module table:$hash_level_name{$level-1}, level:$level,op:$hash_level_op{$level-1} before parse sub table:$table_name" if ($DEBUG==1);
          my  $hash_data_ref;

          $hash_data_ref=&_extract_hash($AoH_data[$level], $hash_level_name{$level-1});

          # if has 'ref' attribute, it will retrieve the data(all non_null cols) from db. 
          # the difference between this and the one using as foreign_obj refering is that, here we may have addition 'update' data to be updated, or to 
          # be deleted, so we need to get real data, then decide how to op it
          #if (defined $AoH_ref[$level-1]{$hash_level_name{$level-1}} && !(defined $hash_data_ref)){
          if (defined $AoH_ref[$level-1]{$hash_level_name{$level-1}} ){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_ref[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key}){
                  $hash_data_ref=&_get_ref_data($hash_level_name{$level-1}, $hash_id{$hash_id_key});
		}
               else {
                 my $temp_db_id=&_get_accession( $AoH_ref[$level-1]{$hash_level_name{$level-1}},$hash_level_name{$level-1}, $level-1);
                 if (defined $temp_db_id){
                      $hash_data_ref=&_get_ref_data($hash_level_name{$level-1}, $temp_db_id );
		 }
                 else {
                   print "\nunable to rerieve record for this ref:$AoH_ref[$level-1]{$hash_level_name{$level-1}}";
                 }
               }
	  }

          # for empty hash_ref, will do nothing(other way to test undefined hash ? ) if (%hash)  ????
          my @temp;
          foreach my $key (%$hash_data_ref){
            if (defined $key && $key ne '' && defined $hash_data_ref->{$key} && $hash_data_ref->{$key} =~/\w|\W/){
               push @temp, $key;
	     }
	  }
	 if ($#temp >-1 ){
          #print "\nthere is data for main module table:$hash_level_name{$level-1}"  if ($DEBUG==1);
          my  $hash_ref=&_data_check($hash_data_ref,  $hash_level_name{$level-1}, $level, \%hash_level_id, \%hash_level_name );

          # here for different type of op, deal with the $hash_data_ref and return the $db_id
          if ($hash_level_op{$level-1} eq 'update'){
             my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level], $hash_level_name{$level-1});
             $db_id=$dbh_obj->db_update(-data_hash=>$hash_ref,-new_hash=>$hash_data_ref_new, -table=>$hash_level_name{$level-1}, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
             #save the pair of local_id/db_id
	     if ($db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
               $hash_id{$hash_id_key}=$db_id;
	     }
	     if (defined $db_id){
               $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	     }
             else {
               print "\nyou try to update a record which not exist in db yet" ;
               &_create_log(\%hash_trans, \%hash_id, $log_file);
               exit(1);
             }
          }
          elsif ($hash_level_op{$level-1} eq 'delete'){
             $db_id=$dbh_obj->db_delete(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1}, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file,-delete_force=>$DELETE_BATCH);
             #delete from %hash_id
             if (defined $db_id){
               foreach my $key (keys %hash_id){
                 my ($temp_table, $temp)=split(/\:/, $key);
		 if ($hash_id{$key} eq $db_id && $temp_table eq $hash_level_name{$level-1}){
                     delete $hash_id{$key};
                     last;
		 }
	       }
               delete $AoH_db_id[$level-1]{$hash_level_name{$level-1}};
	     }
          }
          elsif ($hash_level_op{$level-1} eq 'insert'){
             $db_id=$dbh_obj->db_insert(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1},-hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
             print "\ndb_id:$db_id:"  if ($DEBUG==1);
             #save the pair of local_id/db_id
	     if (defined $db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
               $hash_id{$hash_id_key}=$db_id;
	     }
	     if (defined $db_id){
               $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	     }
          }
          elsif ($hash_level_op{$level-1} eq 'lookup'){
             $db_id=$dbh_obj->db_lookup(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1},-hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);

            #save the pair of local_id/db_id
	    if ($db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
               $hash_id{$hash_id_key}=$db_id;
	    }
	    if ($db_id){
               $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	    }
          }
          elsif ($hash_level_op{$level-1} eq 'force'){
             $db_id=$dbh_obj->db_force(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1}, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);

             #save the pair of local_id/db_id
	     if ($db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
               $hash_id{$hash_id_key}=$db_id;
	     }
	     if ($db_id){
                $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	     }
          }
 	 }
        }

        my $table_col=$hash_ddl{$table_name};
        my @array_col=split(/\s+/, $table_col);
        undef %hash_table_col;
        foreach my $i(0..$#array_col){
	   $hash_table_col{$array_col[$i]}=1;
         #  print "\ncol:$array_col[$i]"  if ($DEBUG==1);
        }

        #after deal with the primary table, here set the operation of link table, default willl be:force
        if (!(defined $AoH_op[$level]{$element_name})){
            $op=$OP_FORCE;
            $hash_level_op{$level}=$op;
            $AoH_op[$level]{$element_name}=$op;
        }

    } # end of self is table_element
   # otherwise, check if it is column, if not, exit and show error.
   elsif ( $element_name ne  $root_element && $element_name ne $SQL_NODE) {

     print "\ntable:$hash_level_name{$level-1}:\tcolumn:$element_name"  if ($DEBUG==1);
     my $col_ref=&_get_table_columns($hash_level_name{$level-1});
     #not column element name
     if (!(exists $col_ref->{$element_name})){
        print "\n invalid element...... element:$element_name" ;
        print "\ntable:$hash_level_name{$level-1}:\tcolumn:$element_name";
        &_create_log(\%hash_trans, \%hash_id, $log_file);
        exit(1);
     }
     #column element, undef the data, already done before ???
     else {
        my $temp_key=$hash_level_name{$level-1}.".".$element_name;
        if ($AoH_op[$level-1]{$hash_level_name{$level-1}} ne 'update'){
           delete $AoH_data[$level]{$temp_key};
	}
        else {
	  if (defined $AoH_op[$level]{$hash_level_name{$level}} &&  $AoH_op[$level]{$hash_level_name{$level}} eq 'update'){
            delete $AoH_data_new[$level]{$temp_key};
	  }
          else {
            delete $AoH_data[$level]{$temp_key};
          }
        }
     }
   }
  } # end of if ($P_pseudo==-1) {
 }

sub characters {
    my( $self, $properties ) = @_;
    my $element_name=$hash_level_name{$level};
 if ($P_pseudo==-1 && $element_name ne $APP_DATA_NODE) {
     my $data = $properties->{'Data'};
     $data =~ s/\&amp;/\&/g;
     $data =~ s/\&lt;/</g;
     $data =~ s/\&gt;/>/g;
     $data =~ s/\&quot;/\"/g;
     $data =~ s/\&apos;/\'/g;
     $data =~ s/\\/\\\\/g;
     #$data =~ s/\&amp;nbsp;/\s/g;
     #here to set NULL value
     $data=$data_null if (defined $att_null && $att_null eq 'true');
     #print "\n$element_name:data_null:$data_null:data:$data:att_null:$att_null:";
    #chomp($data);
    my $data_length=length $data;

    # data will be in @AoH_data: index of array: $level, key of hash: $table_name.$column
    #my $table_name_id=$table_name."_id";
    $character.=$data;



   } #if ($P_pseudo==-1) {
}



sub end_element {
  my ($self, $element) = @_;

  my $parent_element=$hash_level_name{$level-1};
  my $element_name=$element->{Name};
  my $table;
  #my $table_name_id=$table_name."_id";
  my $hash_ref;


     chomp $character if (defined $character);
     $character=~s/^\s+//g if (defined $character);
     #$character= utf8($character)->latin1;
     #we postpone the storage of character until here since character can be split into mutiple chunk
     # Add this function on Feb 11, 2005, which can retrieve any value use arbitary SQL
     #  <feature>
     #      <uniquename>CG12345</uniquename>
     #      ....
     #      <featureprop>
     #            <rank><_sql>select max(rank) from feature f, featureprop fp where f.feature_id=fp.feature_id and f.uniquename='CG12345'<_sql></rank>
     #
     if (defined $element_name && defined $SQL_NODE && $element_name eq $SQL_NODE){
        my  $key=$SQL_NODE.".".$hash_level_name{$level-1};
        $AoH_data[$level]{$key}= $AoH_data[$level]{$key}.$character;
     }

    # ----------------------------------------------------------------------------------
    # For any element which is column of table, it will be saved into hash_data(in here every element)
    # ----------------------------------------------------------------------------------
    elsif (defined $parent_element && defined $hash_ddl{$parent_element}){
        my $hash_ref_cols=&_get_table_columns($parent_element);
        #Page 161: \S any nonwhitespace character, \W any nonword character, problem here is that it may remove space from sentence
        if  (defined $hash_ref_cols->{$element_name} && defined $character && ($character =~/\S/ || $character eq '-') && $character ne "\t" ){
        #if  (defined $hash_ref_cols->{$element_name} && $data !~ /\t/){
	 # if  (defined $hash_ref_cols->{$element_name}){
           my  $key=$hash_level_name{$level-1}.".".$element_name;
                # treat differently for update and other operation
                if ($AoH_op[$level-1]{$parent_element} eq 'update'){
		  if (defined $AoH_op[$level]{$element_name} && $AoH_op[$level]{$element_name} eq 'update'){
                      $AoH_data_new[$level]{$key}= $character;
		  }
                  else {
                      $AoH_data[$level]{$key}= $character;
                  }
		}
                else {
		  if (!(defined $AoH_op[$level]{$element_name}) || $AoH_op[$level]{$element_name} ne 'update'){
                      $AoH_data[$level]{$key}= $character;
		    }
                   else {
                      print "\nTry to update a column which the op for table is not update....." ;
                      &_create_log(\%hash_trans, \%hash_id , $log_file );
                      exit(1);
                  }
	        }
         #print "\n\nin characters key:$key\tvalue:$AoH_data[$level]{$key}:\tlevel:$level"  if ($DEBUG==1);


          #here to save all the currrent transaction information in case of abnormal transaction happen, and undef at end of each trans
           if (!(defined $hash_ddl{$element_name}) && $hash_level_name{$level-2} eq $root_element){
                $hash_trans{$element_name}=$AoH_data[$level]{$key};
            }
       }
     }
    undef $character;




  print "\nend_element_name:$element_name" if ($DEBUG==1);
   # come to end of document
  if ($element_name eq $root_element){
    print "\n\nbingo ....you success !...." ;
    #$dbh_obj->close();
    return;
  }
  my $line=$parser->location()->{LineNumber};
  #DOM structure for extra validation, here remove the child node, which has done its job for validation to prevent out of memory error
  my $node_temp=$node_DOM_current;
  $node_DOM_current=$node_DOM_current->getParentNode();
  if ($node_DOM_current->getNodeName() eq $root_element){
      #$node_DOM_current->removeChild ($node_temp);
	  $node_temp->dispose;
   }

 #do something only when NOT within ELEMENT_PSEUDO
 if ($P_pseudo==-1) {

   if (defined $hash_ddl{$element_name} && $hash_level_name{$level-1} eq $root_element){
      undef %hash_trans;
   }


   #end of </_sql>, then trieve db_id from SQL 
   if ($element_name eq $SQL_NODE){
        my  $key1=$SQL_NODE.".".$hash_level_name{$level-1}; 
        my $db_id=&_parse_sql($AoH_data[$level]{$key1});
        print "\ndb_id:$db_id\n";
        #if parent: column element, substitute the foreign key value with db_id

	if (!$hash_ddl{$hash_level_name{$level-1}} && $hash_level_name{$level-1} ne $root_element){
              my $key=$hash_level_name{$level-2}.".".$hash_level_name{$level-1};
	      if ($hash_level_op{$level-2} eq 'update'){
                if ($hash_level_op{$level-1} eq 'update'){
                   $AoH_data_new[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
	        }
                else {
                   $AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
                }
	      }
              else {
                #$AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
                $AoH_data[$level-1]{$key}=$db_id;
              }
              print "\nsubstitute it with db_id:$AoH_db_id[$level]{$element_name}:level:$level-1:key:$key:" if ($DEBUG==1);
       }


   }
   # ------------------------------------------------------------
   # here come to the end of table
   # -------------------------------------------------------------
   # self: table_element
   elsif ($hash_ddl{$element_name}) {
        my $hash_ref=undef;
        my $hash_ref_new=undef;
        my $db_id;
        my $hash_ref_cols=&_get_table_columns($element_name);
        my  $hash_data_ref=&_extract_hash($AoH_data[$level+1], $element_name);
        #here derefer to hash, so can test whether there is any data:if (%hash)
        #my %hash_data_temp=%$hash_data_ref;
        # if sub_element is not table_element, and is col of this table, and no 'ref' attribute for this element,  extract data
        # for nesting case, which $hash_level_name{$level+1} is table_element already done in start_element
        if (defined $hash_ref_cols->{$hash_level_name{$level+1}} && !(exists $hash_ddl{$hash_level_name{$level+1}})  && defined $hash_data_ref){
 
          # for empty hash_ref, do nothing (already test in last step ???)
          if (defined $hash_data_ref){
            my  $hash_ref=&_data_check($hash_data_ref, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
            # here for different type of op, deal with the $hash_data_ref and return the $db_id
            if ($hash_level_op{$level} eq 'update'){
               my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level+1], $element_name);
               $db_id=$dbh_obj->db_update(-data_hash=>$hash_ref,-new_hash=>$hash_data_ref_new, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }
            elsif ($hash_level_op{$level} eq 'delete'){
               $db_id=$dbh_obj->db_delete(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file,-delete_force=>$DELETE_BATCH);
               #delete from %hash_id
               if ($db_id){
                  foreach my $key (keys %hash_id){
                    my ($temp_table, $temp)=split(/\:/, $key);
	            if ($hash_id{$key} eq $db_id && $element_name eq $temp_table){
                       delete $hash_id{$key};
                       delete $AoH_db_id[$level]{$element_name};
                       last;
	  	    }
	         }
	       }
            }
            elsif ($hash_level_op{$level} eq 'insert'){
               $db_id=$dbh_obj->db_insert(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }
            elsif ($hash_level_op{$level} eq 'lookup'){
               $db_id=$dbh_obj->db_lookup(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }
            elsif ($hash_level_op{$level} eq 'force'){
               $db_id=$dbh_obj->db_force(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }

            # save the pair of local_id/db_id
            # if ($hash_level_op{$level} ne 'update' && $db_id && defined $AoH_local_id[$level]{$element_name}){
            if ($db_id && defined $AoH_local_id[$level]{$element_name} && $hash_level_op{$level} ne 'delete'){
               my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
               $hash_id{$hash_id_key}=$db_id;
	    }
            if ($db_id && $hash_level_op{$level} ne 'delete'){
               $AoH_db_id[$level]{$element_name}=$db_id;
	    }
               print "\nend_element:$element_name is table element, and sub element is col of this table" if ($DEBUG==1);
               print "\nlocal_id:$AoH_local_id[$level]{$element_name}:\tdb_id:$db_id:" if ($DEBUG==1);
         }
       }    # end of if defined hash_data_ref, 
       #for case using ref attribuate to ref object
       elsif (defined $AoH_ref[$level]{$hash_level_name{$level}} && !(defined $hash_data_ref)){
          my  $hash_id_key=$element_name.":".$AoH_ref[$level]{$hash_level_name{$level}};
          print "\nin case using ref attribuate to ref object, ref:$AoH_ref[$level]{$hash_level_name{$level}}" if ($DEBUG==1);
          if (defined $hash_id{$hash_id_key}){
              $hash_data_ref=&_get_ref_data($element_name, $hash_id{$hash_id_key});
  	  }
          else {
              my $temp_db_id=&_get_accession($AoH_ref[$level]{$hash_level_name{$level}}, $element_name, $level);
              if (defined $temp_db_id){
                 $hash_data_ref=&_get_ref_data($element_name, $temp_db_id );
	      }
              else {
                 print "\nunable to retrieve the record based on the ref:$AoH_ref[$level]{$hash_level_name{$level}}";

                 exit(1) if ($hash_level_op{$level} ne $OP_DELETE);
              }
          }

          # for empty hash_ref, do nothing
          if (defined $hash_data_ref){
            my  $hash_ref=&_data_check($hash_data_ref, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
            # here for different type of op, deal with the $hash_data_ref and return the $db_id
            if ($hash_level_op{$level} eq 'update'){
               my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level+1], $element_name);
               #  my  $hash_data_ref_new=&_data_check($hash_ref_new_temp, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
               $db_id=$dbh_obj->db_update(-data_hash=>$hash_ref,-new_hash=>$hash_data_ref_new, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
          }
            elsif ($hash_level_op{$level} eq 'delete'){
               $db_id=$dbh_obj->db_delete(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file,-delete_force=>$DELETE_BATCH);
               #delete from %hash_id
               if ($db_id){
                  foreach my $key (keys %hash_id){
                    my ($temp_table, $temp)=split(/\:/, $key);
	            if ($hash_id{$key} eq $db_id && $element_name eq $temp_table){
                       delete $hash_id{$key};
                       delete $AoH_db_id[$level]{$element_name};
                       last;
	  	    }
	         }
	       }
            }
            elsif ($hash_level_op{$level} eq 'insert'){
               print "\nit is invalid xml to have 'insert' and 'ref' appear together";
               &_create_log(\%hash_trans, \%hash_id, $log_file);
               exit(1);
          }
            elsif ($hash_level_op{$level} eq 'lookup'){
               $db_id=$dbh_obj->db_lookup(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
          }
            elsif ($hash_level_op{$level} eq 'force'){
               print "\nit is invalid xml to have 'force' and 'ref' appear together";
               &_create_log(\%hash_trans, \%hash_id, $log_file);
               exit(1);
            }

            # save the pair of local_id/db_id
            # if ($hash_level_op{$level} ne 'update' && $db_id && defined $AoH_local_id[$level]{$element_name}){
            if ($db_id && defined $AoH_local_id[$level]{$element_name} && $AoH_op[$level]{$element_name} ne 'delete'){
               my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
               $hash_id{$hash_id_key}=$db_id;
	    }
            if ($db_id  && $AoH_op[$level]{$element_name} ne 'delete'){
               $AoH_db_id[$level]{$element_name}=$db_id;
	    }
               print "\nend_element is $element_name table element, and sub element is col of this table" if ($DEBUG==1);
               print "\nlocal_id:$AoH_local_id[$level]{$element_name}:\tdb_id:$db_id:" if ($DEBUG==1);
         } # end of if (%hash_data_temp)
	} # end of using ref attribute to refer object
        elsif (defined $AoH_ref[$level]{$hash_level_name{$level}} && defined $hash_data_ref) {
           print "\nexist data for ref:$AoH_ref[$level]{$hash_level_name{$level}} and hash_data_temp has value:";
           foreach my $temp_key (keys %$hash_data_ref){
             print "\nkey:$temp_key:value:$hash_data_ref->{$temp_key}";
	   }
           &_create_log(\%hash_trans, \%hash_id, $log_file);
           exit(1);
        }


        #if parent: column element, substitute the foreign key value with db_id
        # for case like this: <cvterm_relationship><object_id><feature>...</feature></object_id></cvterm_relationship>, throw error
	if (!$hash_ddl{$hash_level_name{$level-1}} && $hash_level_name{$level-1} ne $root_element){
          my $ref_string=$hash_level_name{$level-2}.":".$hash_level_name{$level-1}."_ref_table";
          if ($hash_ddl{$ref_string} eq $element_name){
              my $key=$hash_level_name{$level-2}.".".$hash_level_name{$level-1};
	      if ($hash_level_op{$level-2} eq 'update'){
                if ($hash_level_op{$level-1} eq 'update'){
                   $AoH_data_new[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
	        }
                else {
                   $AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
                }
	      }
              else {
               $AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
              }
              print "\nsubstitute it with db_id:$AoH_db_id[$level]{$element_name}:level:$level-1:key:$key:" if ($DEBUG==1);
         }
         else {
               warn "\ninvalid nested $hash_level_name{$level-2}:$hash_level_name{$level-1}:$element_name";
               warn  "\nshould be $hash_level_name{$level-2}:$hash_level_name{$level-1}:$hash_ddl{$ref_string}";
               &_create_log(\%hash_trans, \%hash_id, $log_file);
               exit(1);
         }
       }
   }
   # self: column element
   else {
      my $temp_foreign=$hash_level_name{$level-1}.":".$element_name."_ref_table";
      my $key=$hash_level_name{$level-1}.".".$element_name;
      my $primary_table=$hash_ddl{$temp_foreign};
      print "\n$element_name is column_element" if ($DEBUG==1);
       #if is foreign key, and next level element is the primary table, it has done in last step, ie. <type_id><cvterm>...</cvterm></type_id>
      if (defined $hash_ddl{$temp_foreign} && defined $hash_level_name{$level+1} && $hash_ddl{$temp_foreign} eq $hash_level_name{$level+1} && defined $hash_ddl{$temp_foreign} ne '' && (defined $hash_level_sub_detect{$level+1})){
        # my $key=$hash_level_name{$level-1}.".".$element_name;
        # print "\nforeign key, next level element:$hash_level_name{$level+1} is the primary table";
        # print "\nnext level db_id:$AoH_db_id[$level+1]{$primay_table}:";
        # print "\nref_table:$hash_ddl{$temp_foreign}:\tprimary_table: $hash_level_name{$level+1}";

        # already done in the case of: self: table, parent: col
        # if ($hash_level_op{$level-1} eq 'update'){
	#   if ($hash_level_op{$level} eq 'update'){
        #     $AoH_data[$level]{$key}=$AoH_db_id[$level+1]{$primay_table};
	#   }
        #   else {
        #     $AoH_data_new[$level]{$key}=$AoH_db_id[$level+1]{$primay_table};
        #   }
        # }
        # else {
        #    $AoH_data[$level]{$key}=$AoH_db_id[$level+1]{$primay_table};
        # }
      }
      # foreign key, no sub element, but have data, then it is local_id or accession, replace it  with db_id
      elsif (defined $hash_ddl{$temp_foreign} && !(defined $hash_level_sub_detect{$level+1}) &&  ((defined  $AoH_data[$level]{$key}) && ($AoH_data[$level]{$key} ne '')|| (defined  $AoH_data_new[$level]{$key}) && ($AoH_data_new[$level]{$key} ne ''))){
         #table: not update
        if ($hash_level_op{$level-1} ne 'update'){
          my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data[$level]{$key};
	  if (defined $hash_id{$hash_id_key}){
              $AoH_data[$level]{$key}=$hash_id{$hash_id_key};
	    }
          elsif(defined $hash_accession_entry{$primary_table}) {
             print "\nhas value:$AoH_data[$level]{$key},not in hash_id" if ($DEBUG==1);
             my $id=&_get_accession($AoH_data[$level]{$key}, $primary_table, $level);
             if (defined $id){
                $AoH_data[$level]{$key}=$id;
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $id){
                    print "\nyou define two different record with same local_id:: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print "\n$element_name: can't retrieve the id based on the accession:$AoH_data[$level]{$key}" if ($DEBUG==1);
                print "\nor correct format for accesion, but op for table:$hash_level_name{$level-1} is:$hash_level_op{$level-1} , and record for this accesion is not in db yet" if ($DEBUG==1);
                 &_create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
             }
           }
          else {
                print "\n$element_name:$AoH_data[$level]{$key}: is not accession, or local_id:$AoH_data[$level]{$key} is not defined yet" ;
                &_create_log(\%hash_trans, \%hash_id , $log_file );
                exit(1);
          }
           print "\nend_element:$element_name is col, table_op:not update" if ($DEBUG==1);
       	}
        #table:update, col:update
        elsif ($hash_level_op{$level-1} eq 'update' && $hash_level_op{$level} eq 'update' ){
          my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data_new[$level]{$key};
	  if (defined $hash_id{$hash_id_key}){
              $AoH_data_new[$level]{$key}=$hash_id{$hash_id_key};
	  }
          elsif(defined $hash_accession_entry{$primary_table}) {
             my $id=&_get_accession($AoH_data_new[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data_new[$level]{$key}=$id;
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print "\n$element_name: can't retrieve the id based on the accession:$AoH_data_new[$level]{$key}";

                &_create_log(\%hash_trans, \%hash_id,  $log_file);
                exit(1);
             }
          }
          else {
                print "\n$element_name:$AoH_data_new[$level]{$key} is not accession, or local_id:$AoH_data_new[$level]{$key} is not defined yet";
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
          }
          print "\nend_element: self:col, table_op:update, col_op:update" if ($DEBUG==1);
        }
        #table: update, col: not upate
        else {
           my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data[$level]{$key};
	   if (defined $hash_id{$hash_id_key}){
              $AoH_data[$level]{$key}=$hash_id{$hash_id_key};
	    }
           elsif(defined $hash_accession_entry{$primary_table}) {
             my $id=&_get_accession($AoH_data[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data[$level]{$key}=$id;
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $id){
                    print "\nyou define two different record with same local_id:: at line:$line";
                   &_create_log(\%hash_trans, \%hash_id, $log_file);
                   exit(1);
	       }
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print "\n$element_name: can't retrieve the id based on the accession:$AoH_data[$level]{$key}";
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
             }
           }
          else {
                print "\n$element_name $AoH_data[$level]{$key} is not accession, or local_id:$AoH_data[$level]{$key} is not defined yet";
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
          }
         print "\nend_element: self:col, table_op:update, col_op:not update" if ($DEBUG==1);
        }
       print "\nprimary table:$hash_ddl{$temp_foreign}:sub element:$hash_level_name{$level+1}" if ($DEBUG==1);
       print "\n\n$element_name is foreign key, no sub element, has data, db_id:$AoH_data[$level]{$key}" if ($DEBUG==1);
      }
      # foreign key, no sub element, but NO data, error .......
      elsif (defined $hash_ddl{$temp_foreign} && defined  $hash_level_name{$level+1} &&  $hash_ddl{$temp_foreign} ne $hash_level_name{$level+1} && $hash_ddl{$temp_foreign} ne '' && !$AoH_db_id[$level+1]{$primary_table} && ($AoH_data[$level]{$key} eq '')) {
        print "\n\n$element_name: is foreign key, no sub element, not data, error .....";
        &_create_log(\%hash_trans, \%hash_id, $log_file);
        exit(1);
      }
       # not foreign key, do nothing
      elsif (!(defined$hash_ddl{$temp_foreign}) || !$hash_ddl{$temp_foreign}){
        # print "\n$element_name: is not foreign key, do nothing .....:$temp_foreign";
        #implemented on Jan 31, 2006 to update as null: <name null="true"/>
	if (defined $att_null && $att_null eq 'true'){
           my  $key=$hash_level_name{$level-1}.".".$element_name;
                # treat differently for update and other operation
                if (defined $AoH_op[$level-1]{$parent_element} && $AoH_op[$level-1]{$parent_element} eq 'update'){
		  if ($AoH_op[$level]{$element_name} eq 'update'){
                      $AoH_data_new[$level]{$key}= $data_null;
		  }
                  else {
                      $AoH_data[$level]{$key}= $data_null;
                  }
		}
                else {
		  if (!(defined $AoH_op[$level]{$element_name}) || $AoH_op[$level]{$element_name} ne 'update'){
                      $AoH_data[$level]{$key}= $data_null;
		    }
                   else {
                      print "\nTry to update a column which the op for table is not update....." ;
                      &_create_log(\%hash_trans, \%hash_id , $log_file );
                      exit(1);
                  }
	        }
	 }

      }

   }
   undef $att_null;
 }  #end of if ($P_pseudo ==-1)

  delete $hash_level_sub_detect{$level+1};
  $level--;
  if (defined $hash_tables_pseudo{$element_name}){
     $P_pseudo --;
  }
}


sub end_document {
    #clean the load.log 

    system(sprintf("rm $log_file")) if (-e $log_file && ($recovery_status eq '0' || $recovery_status ==0));
    $dbh_obj->close();
    print "\n\nbingo ....you success !....";
   # exit(1);
   return;
}


#sub entity_reference {
# my ($self, $properties) = @_;
 #do nothing
#}


=head2 _extract_hash

  Arg [1]    : 
  Arg [2]    : 
  Example    : 
  Description: private method
               this util method will execute whateven in the sql(could be multiple stm, separate by ';'?), and return output from last sql
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut
sub _parse_sql(){
  my $stm=shift;
#  my $ref=$dbh_obj->get_all_arrayref($stm);
#  for my $i ( 0 .. $#{$ref} ) {
#  }
  print "\n:$stm:";
  return $dbh_obj->get_one_value($stm);
}




=head2 _extract_hash

  Arg [1]    : hash reference contains the data
  Arg [2]    : element name
  Example    : $hash_ref=&_extract_hash($AoH_data[$level], $element);
  Description: private method
               this util method will extract all the data from hash which the key of this hash prefix with $element."."
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut

sub _extract_hash(){
    my $hash_ref=shift;
    my $element=shift;
    my %result;

    my $content=$element.".";
    foreach my $value (keys %$hash_ref){
            #print "\nextract_hash before:key:$value:value:$hash_ref->{$value}:"  if ($DEBUG==1);
	if (index($value, $content) ==0 ){
            my $start=length $content;
            my $key=substr($value, $start);
            #print "\nextract_hash:content:$content:value:$value:key:$key:$hash_ref->{$value}:"  if ($DEBUG==1);
           # if ($hash_ref->{$value} =~/\w/){
             $result{$key}=$hash_ref->{$value};

	   #}
             delete $hash_ref->{$value};
	}
    }



   # foreach my $key (keys %$hash_ref){
   #    print "\nleft key:$key:\tvalue:$hash_ref{$key}:"  if ($DEBUG==1);
   # }
    if (%result){
         return \%result;
    }
  return ;
}


=head2 _data_check

  Arg [1]    : hash reference contains the data
  Arg [2]    : table name
  Arg [3]    : level
  Arg [4]    : hash reference, key:$level, value: $local_id
  Arg [5]    : hash reference, key:$level, value:element_name

  Example    : $hash_ref=&_data_check(\%hash_data, 'feature', 3, \%hash_level_id, \%hash_level_name);
  Description: private method
               this util method will check the missed columns, 
               missed column, if non_null,  non_foreign key, error ...
               if non_null, foreign key, go to get from parent, grandparent ....
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut

sub _data_check(){
    my $hash_ref=shift;
    my $table=shift;
    my $level=shift;
    my $hash_level_id_ref=shift;
    my $hash_level_name_ref=shift;
    my %result;

    my $hash_foreign_key;
    my @array_foreign_key=split(/\s+/, $hash_ddl{foreign_key});
    for (@array_foreign_key){
       $hash_foreign_key{$_}++;
    }

    my %hash_non_null_default;
    my $table_non_null_default=$table."_non_null_default";
    if (defined $hash_ddl{$table_non_null_default}){
      my @default=split(/\s+/, $hash_ddl{$table_non_null_default});
      for (@default){
        $hash_non_null_default{$_}++;
      }
    }

    my %hash_unique_key;
    my $table_unique_key=$table."_unique";
    my @unique_key=split(/\s+/, $hash_ddl{$table_unique_key});
    for (@unique_key){
      $hash_unique_key{$_}++;
    }
    my $unique_keys_no=0;#this serve as special treatment for 'delete' requested by Aubrey, which can do batch deletion based on partial of unique keys
    my $line=$parser->location()->{LineNumber};

    my $table_non_null=$table."_non_null_cols";
    my @temp=split(/\s+/, $hash_ddl{$table_non_null});
    my $table_id_string=$table."_primary_key";
    my $table_id=$hash_ddl{$table_id_string};
    #my $table_id=$table."_id";
    #edited on 02/01/2006, which first retrive foreign-refer key first to avoid ambiguity of log message.
    #policy: only allow ONE not_null retrieve, not for nullable retrieve.
    my %hash_context_retrieved;
    for my $i(0..$#temp){
      my $foreign_key=$table.":".$temp[$i];
      #not serial id, is not null column, and is foreign key, then retrieved from the nearest outer of hash_level_db_id
      if ($temp[$i] ne $table_id &&  !(defined $hash_ref->{$temp[$i]}) && (defined $hash_foreign_key{$temp[$i]} )){
         my $temp_key=$table.":".$temp[$i]."_ref_table";
         print "\ndata_check temp_key:$temp_key:value:$hash_ddl{$temp_key}" if ($DEBUG==1);
         my $retrieved_value=&_context_retrieve($level,  $hash_ddl{$temp_key}, $hash_level_name_ref);
         if ($retrieved_value){
            $hash_ref->{$temp[$i]}=$retrieved_value;
            if (defined $hash_context_retrieved{$hash_ddl{$temp_key}}){
                print "\nyou try to retrieve more than ONE not_null column using context_retrive at line:$line for column:$hash_context_retrieved{$hash_ddl{$temp_key}} and $temp[$i] from table:$table";
                &_create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
            }
            $hash_context_retrieved{$hash_ddl{$temp_key}}=$temp[$i];
	  }
       }
    }

    for my $i(0..$#temp){
      my $foreign_key=$table.":".$temp[$i];
      #not serial id, is not null column, and is foreign key, then retrieved from the nearest outer of hash_level_db_id
      if ($temp[$i] ne $table_id &&  !(defined $hash_ref->{$temp[$i]}) && (defined $hash_foreign_key{$temp[$i]} )){
         my $temp_key=$table.":".$temp[$i]."_ref_table";
         print "\ndata_check temp_key:$temp_key:value:$hash_ddl{$temp_key}" if ($DEBUG==1);
         my $retrieved_value=&_context_retrieve($level,  $hash_ddl{$temp_key}, $hash_level_name_ref);
         if ($retrieved_value){
            #$hash_ref->{$temp[$i]}=$retrieved_value;#only allow for ONCE as above
	  }
         elsif (!(defined $hash_non_null_default{$temp[$i]})) {
	   if (exists $hash_unique_key{$temp[$i]}){
	     if ( $DELETE_BATCH!=1){
              print "\n\ncan not find the value for required element(unique key):$temp[$i] of table:$table from context .....";
              &_create_log(\%hash_trans, \%hash_id, $log_file);
              exit(1);
	     }
	   }
           #if not null, but not unique key, then depend on the op: ok for lookup/delete, ok for force if already exist in DB, NOT ok for insert
           else {
               my $op=$hash_level_op{$level-1};
               if ($op eq $OP_INSERT){
                    print "\n\ncan not find the value for required element(foreign key, not unique, op:$OP_INSERT):$temp[$i] of table:$table from context .....";
                    &_create_log(\%hash_trans, \%hash_id, $log_file);
                    exit(1);
	       }
               elsif ($op eq $OP_FORCE){
                  my %hash_temp;
                  foreach my $key(keys %$hash_ref){
                     $hash_temp{$key}=$hash_ref->{$key};
		  }


                  my  $db_id=$dbh_obj->db_lookup(-data_hash=>\%hash_temp, -table=>$table,-hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
                  if (!($db_id)){
                    print "\n\n$temp[$i]: is foreign_key, unique_key, unable to retrieve from context, op is $OP_FORCE, and this record is not in DB yet";
                    &_create_log(\%hash_trans, \%hash_id, $log_file);
                    exit(1);

		  }
               }
	    }

         }
      }   # end of is foreign_key, try to retrieve from context
      elsif ($temp[$i] ne $table_id &&  !(defined $hash_ref->{$temp[$i]}) && !(defined $hash_foreign_key{$temp[$i]}) && !(defined $hash_non_null_default{$temp[$i]})) {
	if (exists $hash_unique_key{$temp[$i]} && $DELETE_BATCH !=1){
          print "\n\nyou missed the required element:$temp[$i] for table:$table, also it is not foreign key";
          &_create_log(\%hash_trans, \%hash_id, $log_file);
          exit(1);
        }
        else {
               my $op=$hash_level_op{$level-1};
               if ($op eq $OP_INSERT){
                    print "\n\ncan not find the value for required element(not foreign key, not unique, op:$OP_INSERT):$temp[$i] of table:$table from context .....";
                    &_create_log(\%hash_trans, \%hash_id, $log_file);
                    exit(1);
	       }
                #if not null, but not unique key, then depend on the op: ok for lookup/delete, ok for force is already exist in DB, NOT ok for insert
               elsif ($op eq $OP_FORCE){
                  my %hash_temp;
                  foreach my $key(keys %$hash_ref){
                     $hash_temp{$key}=$hash_ref->{$key};
		  }
                  my  $db_id=$dbh_obj->db_lookup(-data_hash=>\%hash_temp, -table=>$table,-hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
                  if (!($db_id)){
                    print "\n\n$temp[$i]: not  foreign_key, unique_key, op is $OP_FORCE, and this record is not in DB yet";
                    &_create_log(\%hash_trans, \%hash_id, $log_file);
                    exit(1);

		  }
               }
        }
      }
    }

    #   delete $hash_ref->{$value};
    foreach my $key (keys %$hash_ref){
      print "\nin data_check col of table:$table:$key\tvalue:$hash_ref->{$key}:" if ($DEBUG==1) ;
      $unique_keys_no++ if (defined $hash_unique_key{$key});
    }
    if ($unique_keys_no ==0){
          print "\n\nyou do NOT specify ANY unique key for table:$table, very dangerous operation.....";
          &_create_log(\%hash_trans, \%hash_id, $log_file);
          exit(1);
    }
    return $hash_ref;
}



=head2 _context_retrieve

  Arg [1]    : level
  Arg [2]    : primary table name
  Arg [3]    : hash reference, key:level, value:element name
  Example    :
  Description: private method
               This util method will retrieve the missed value based on the context check: nearest outer of correct type
  Returntype : primary id from db for this record or null
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut

sub _context_retrieve(){
    my $level=shift;
    my $primary_table=shift;
    my $hash_level_name_ref=shift;
    my $result;
    print "\ncontext_retrieve:level:$level:primary_table:$primary_table"  if ($DEBUG==1);
    for ( my $i=$level-1; $i>=0; $i--){
      print "\ncontext check hash_level_name:$hash_level_name_ref->{$i}"  if ($DEBUG==1);
      if ($primary_table eq $hash_level_name_ref->{$i}){
        print "\ncontext_retrieve:level:$level:primary_table:$primary_table:value:$AoH_db_id[$i]{$primary_table}" if ($DEBUG==1);
        $result= $AoH_db_id[$i]{$primary_table};
        last;
      }
    }
    print "\nresult is:$result" if ($DEBUG==1);
    return $result;
}


=head2 _get_table_columns

  Arg [1]    : table name
  Example    :
  Description: private method
               This util will return a hash ref which contains all the columns of this table
  Returntype : hash reference, key: column name, value:data type
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut

sub _get_table_columns(){
  my $table=shift;
  my $table_col=$hash_ddl{$table};

  my @array_col=split(/\s+/, $table_col);
  my $hash_table_column_ref;
        foreach my $i(0..$#array_col){
          if ($array_col[$i] ne ''){
	    $hash_table_column_ref->{$array_col[$i]}=1;
	  }
          # print "\ncol:$array_col[$i]"  if ($DEBUG==1);
        }
  return $hash_table_column_ref;
}


=head2 _get_accession

  Arg [1]    : accession
  Arg [2]    : table name
  Arg [3]    : level
  Example    :
  Description: private method
               This util will get id based on the accession
               Format of accession: dbname:accession[.version]
               For dbxref, if not in db, insert it
               For feature/cvterm, if not in db, get the pseudo organism_id(if not in , create one: genus:Drosophila species:melanogaster taxgroup:0
               convenction: uniquename for this case will in format of: db:accession[.version]

  Returntype : primary table id value or null
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut


sub _get_accession(){
  my $accession=shift;
  my $table=shift;
  my $level=shift;

  my $op=$hash_level_op{$level};
  my ($dbname, $acc, $version, $db_id, $stm_select, $stm_insert);
  print "\nstart the _get_accession in XMLParse.pm to parser accession:$accession for table:$table ....";

  my $config_acc_file=$conf."/config_accession.xml";
  if (-e $config_acc_file) {
     #why here we need to close the connection before do the accession retrieve ?
     $dbh_obj->close();
     my $acc_parser=XML::XORT::Loader::XMLAccession->new($db, $config_acc_file, $DEBUG,$DDL_FILE);
     my $acc_id=$acc_parser->parse_accession($table, $accession, $op);
     print "\nget global_id:$acc_id: for this accession:$accession";
      $dbh_obj->open();
     print "\nend the _get_accession....";
     return $acc_id;
  }
  else {
    print "\nunable to find configureation file:$config_acc_file";
    return;
  }

}



# util method serving for get_accession in case of inserting new record based on the accession
sub _get_organism_id(){

    my $level=shift;

    my $result;
    for ( my $i=$level; $i>=0; $i--){
      print "\nhash_level_name:$hash_level_name{$i-1}"  if ($DEBUG==1);
      if ( $hash_level_name{$i} eq 'feature' ){
        my $hash_ref=$AoH_local_id[$i+1];
        foreach my $key (keys %$hash_ref){
           print "\nkey:$key\tvalue:$hash_ref->{$key}"  if ($DEBUG==1);
	}
        $result= $AoH_local_id[$i+1]{'organism_id'};
        print "\n\norganism_id is:$result ........" if ($DEBUG==1);
        last;
      }
    }
    print "\n\norganism_id is:$result ........" if ($DEBUG==1);
    return $result;

}

=head2 _get_ref_data

  Arg [1]    : table name
  Arg [2]    : id
  Example    :
  Description: private method
               this util was created because of ref attribute, which ref object by local_id or accession, 
               here the id will the real db id, so each will retrieve at most ONE record
               this method will retrive the real data(only unique keys) from DB, and store in hash

  Returntype : hash reference contains data
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut


sub _get_ref_data(){
 my $table=shift;
 my $id=shift;

 my $hash_ref;
 #my $table_id=$table."_id";
 my $table_id_string=$table."_primary_key";
 my $table_id=$hash_ddl{$table_id_string};
 my $table_unique=$table."_non_null_cols";
 my @array_table_cols=split(/\s+/, $hash_ddl{$table_unique});
 my $data_list;
 for my $i(0..$#array_table_cols){
   if ($data_list){
       $data_list=$data_list." , ".$array_table_cols[$i];
   }
   else {
       $data_list=$array_table_cols[$i];
   }
 }

 my $stm_select=sprintf("select $data_list from $table where $table_id=$id");
 print "\nget_ref_data stm:$stm_select" if ($DEBUG==1);
 my $array_ref=$dbh_obj->get_all_arrayref($stm_select);
 if (defined $array_ref){
   for my $i (0..$#{$array_ref->[0]}){
        $hash_ref->{$array_table_cols[$i]}=$array_ref->[0][$i];
        print "\nfrom ref:$table:$array_table_cols[$i]:$array_ref->[0][$i]" if ($DEBUG==1);
   }
  return $hash_ref;
 }
 return ;
}



=head2 _create_log

  Arg [1]    : hash reference contains data already parse to for specific record
  Arg [2]    : hash_reference, key:local id, value: db id
  Arg [3]    : file to be written to
  Example    :
  Description: private method
               create a log file which contains all necessary for recovery the failed loading process from last step

  Returntype : null
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut
sub _create_log(){
   my $hash_trans=shift;
   my $hash_local_id=shift;
   my $file=shift;

   print "\nit will use this log_file:$file: to recover the process if you set the -is_recovery=1";
   my $log_file=">".$file;

   print "\nlog file:$log_file";
   open (LOG, $log_file) or die "unable to write to file:$log_file";
   foreach my  $key (keys %$hash_local_id){
      print LOG "$key\t$hash_local_id->{$key}\n";
   }
   print "\n\nsorry, for some reasons, this process stop before finish the following transaction:$hash_trans->{table}\n";
   my $line=$parser->location()->{LineNumber};
   print LOG "\nproblem around the following line:$line\n";
   print "\nproblem around the following line:$line\n";
   foreach my $key (keys %$hash_trans){
     if ($key ne 'table'){
         print "\nelement:$key\tvalue:$hash_trans->{$key}";
    }
   }
   print "\n\n";
}


1;




