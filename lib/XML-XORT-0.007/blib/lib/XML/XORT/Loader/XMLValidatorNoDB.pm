=head1 NAME

         XML::XORT::Loader::XMLParser - module to validate XORT-format XML to check whether it compatiable with DB schema

=head1 SYNOPSIS

         my $validator_obj=XML::XORT::Loader::XMLValidator->new(-file=>$xort_file,
                                                           -debug=>1 );
         $validator_obj->validate(-validate_level=>1);

=head1 DESCRIPTION

        This is the basic module which will load XORT-FORMAT XML into DB

=cut

=head1 CONTACT

        Pinglei Zhou, FlyBase fellow at Harvard University (zhou@morgan.harvard.edu)

=cut

=head1 METHODS

=cut


package XML::XORT::Loader::XMLValidatorNoDB;
use XML::Parser::PerlSAX;
use XML::XORT::Util::DbUtil::DB;
use XML::XORT::Util::GeneralUtil::Constants;
use strict;

#level 1 validate: no db connection at all


# --------------------------------------------------------
# global variable
# -------------------------------------------------------
my %hash_ddl;
my $level=1;

my $DELETE_BATCH=1; #this to flag the force deletion requested by Aubrey, which do batch deletion based on partial of unique keys

my $element_name;
my $table_name;
my %hash_table_col;

# this hash will have the pair of local_id/db_id, eg. cvterm_99 from xml file, id from cvterm_id 88, the key format: table_name:local_id
# value format: table_name:db_id  ?????? different from XMLParser.pm
my %hash_id;
#this will store all the id which suppose delete from db, in the format of table_name:db_id
my %hash_db_id_deleted;

#  store the 'text' for no 'update', index for array: level, key for hash: table.col,  value: 'text' data
my @AoH_data;
# store the 'text' for 'update', index for array: level, key for hash: table.col,  value: 'text' data
my @AoH_data_new;

#format for db_id: table_name:db_id ???
my @AoH_db_id;
my @AoH_local_id;
my @AoH_op;
my @AoH_ref;

# key: $level, value: local_id/element_name/op/ref
my %hash_level_id;
my %hash_level_name;
my %hash_level_op;
my %hash_level_ref;
# this will save all the data supposed to be insert into db(insert/force)
# first key:table_name:replace_db_id, first value: hash_ref
# second key: column_name, second value: value for this col
my %HoH_data;
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
my $OP_lookup='lookup';

# all attribute
my $ATTRIBUTE_ID='id';
my $ATTRIBUTE_OP='op';
my $ATTRIBUTE_REF='ref';

my $DEBUG=0;
my $DDL_FILE='ddl';
#set if log goes to STDOUT or file
my $FLAG_STDOUT=0;
# for some elements, it will be ignored, i.e view, and _app_data,
# algorithms to filter out ignore elements: initiately P_pseudo set to -1, for tables_pseudo, increase by 1 at beginning of start_element,  decrease by 1 at end of end_element
# if P_pseudo >-1, then do nothing for start_element, end_element, character
my $TABLES_PSEUDO='tables_pseudo';
my %hash_tables_pseudo;
my $P_pseudo=-1;

#here undefined at begin of start_element, save when come to end_element
my $character;

# all the table which has dbxref_id, and primary key can be retrieved by accession
my %hash_accession_entry=(
dbxref=>1,
feature=>1,
);



# this hash will contain all the data for the current parsing table(which also is the subelement of root element)
my %hash_trans;
# this control the validator will talk to database or not
my $validate_level=-1;
my $VALIDATION_NO_DB=0;
my $VALIDATION_DB=1;

# this service as replace id for db id/local id whenever no db connection or no record exist in db, start from 0, then keep decreasing each insertion
my $replace_db_id=0;
my $replace_local_id=0;

my $log_file;

#retrive some constants
my $constant_obj=XML::XORT::Util::GeneralUtil::Constants->new();
my $conf= $constant_obj->get_constant('CONF');
my $tmp= $constant_obj->get_constant('TMP');

#declare it as public, so it can return the line number
my $parser;

sub new (){
 my $type=shift;
 my $self={};
# $self->{'file'}=shift;
# $DEBUG=shift;


 my ( $xml_file, $debug,$delete_batch ,$ddl_property, $stdout ) =
     XML::XORT::Util::GeneralUtil::Structure::rearrange(['file','debug','delete_batch','ddl_property','STDOUT'], @_);
     $self->{'file'}=$xml_file;
     $DEBUG=$debug;
     $DELETE_BATCH=$delete_batch if (defined $delete_batch);
     $DDL_FILE=$ddl_property if (defined $ddl_property);
     $FLAG_STDOUT=$stdout if (defined $stdout);
    my $pro=XML::XORT::Util::GeneralUtil::Properties->new($DDL_FILE);
    %hash_ddl=$pro->get_properties_hash();

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


 bless $self, $type;
 return $self;
}


# usage: $validate_obj->load();
=head2 load

  Arg [1]    : none

  Example    : $obj->validate(-validate_level=>1);
  Description: public method which validate the XORT-format xml is valid to DB schema
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut

sub validate (){
   my $self=shift;
   my ($validate) =
     XML::XORT::Util::GeneralUtil::Structure::rearrange(['validate_level'], @_);


   if ($validate eq $VALIDATION_NO_DB || $validate eq $VALIDATION_DB) {
     $validate_level=$validate;
   }
   else {
     print "\nvalidator_level must be either $VALIDATION_NO_DB for no db connection or $VALIDATION_DB for db connection";
     exit(1);
   }

   my $file=$self->{file};
   my $db=$self->{db};

    my @temp=split(/\/+/, $file);
    my $temp_file=$temp[$#temp];
    $log_file=$tmp."/".'validator_no_db_'.$temp_file.".log";

    $parser = XML::Parser::PerlSAX->new(Handler=>MyHandler->_new( ));
   $parser->parse (Source=>{SystemId=>$file});

}

 my $node_DOM;
 my $node_DOM_current;
 my $doc=new XML::DOM::Document();
 package MyHandler;
 use XML::XORT::Util::DbUtil::DB;
 use XML::DOM;

 # keys: all the foreign keys
 my %hash_foreign_key;

 sub _new {
  my $type=shift;
  my $self={};
  $self->{'file'}=shift;
  return bless {}, $type;
 }

 sub start_document {
   #all the variable defined in new method is unreachable for all other method
   # so here is good place to initiate some varables
    my (@temp,$is_symbol, $db_xref, $op_table, $op_column, %hash_table_col);

   # open (LOG0, $log_file) or die "unable to open the log file for validator_no_db:$log_file";
    if ($FLAG_STDOUT!=1) {
        print "\nyou can find the log info here:\n$log_file\n";
	open FILEH, ">>$log_file";	
	select FILEH;
        autoflush FILEH 1;
     }
     else {
	select STDOUT;
        autoflush STDOUT 1;
     }

    $node_DOM=$doc->createElement('chado');
    $node_DOM_current=$node_DOM;
 }




 sub start_element {
    my ($self, $element) = @_;
    #characters() may be called more than once for each element because of entity
     $level++;
     $hash_level_sub_detect{$level}=1;
     $element_name=$element->{'Name'};
     print "\nstart_element:$element_name" if ($DEBUG==1);

    # store the transaction information
    if (defined $hash_ddl{$element_name} && $hash_level_name{$level-1} eq $root_element){
       $hash_trans{'table'}=$element_name;
    }
     my $line=$parser->location()->{LineNumber};
=head
     #part of  DOM structure for extra structure validation
     my $node_element=$doc->createElement($element_name);
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
	  }

      }
      elsif ($name_parent ne $root_element) { #parent: col, then grandparent also must be table: 
         my $ref_col=&_get_table_columns($element_name);
         my $name_grandparent=$node_DOM_current->getParentNode()->getParentNode()->getTagName();
         my $key=$name_grandparent.":".$name_parent."_ref_table";
         print "\n3 wrong nesting:$name_grandparent:$name_parent:$element_name: at $line" if ($hash_ddl{$key} ne $element_name);
      }
    }
    elsif ( ! defined $hash_ddl{$element_name} && $element_name ne $root_element){ #self:col
      my $ref_col=&_get_table_columns($name_parent);
      if (! (defined $hash_ddl{$name_parent})){#parent is not table
          print "\nwrong nest here:COLS element:$element_name nested within COLS element:$name_parent at $line";
      }
      else { #parent is table, and all existed previous sibling must be cols of SAME parent, also should be NO text value like this: <feature>a<name>b</name></feature>
         #print "\n$name_parent\t$element_name";
         print "\ncol:$element_name nested with WRONG parent:$name_parent at $line" if (!(defined  $ref_col->{$element_name}));
         my $sibling=$node_DOM_current->getPreviousSibling();
         my $name_sibling;
         my $attribute_op_parent=($node_DOM_current->getParentNode())->getAttribute($ATTRIBUTE_OP);
         #print "\nelement_name:$element_name\n" if ($element_name eq "organism_dbxref");
         while (defined $sibling ){
            if ($sibling->getNodeType()==ELEMENT_NODE()){
               $name_sibling=$sibling->getTagName();
               if ( defined $hash_ddl{$name_sibling}){
                  print "\nerror here:link table $name_sibling should always AFTER instead of before cols:$element_name of parent:$name_parent at line:$line" ;
                  last;
    	       }
               elsif ($name_sibling eq $element_name){
                  my $attribute_op_self=$node_DOM_current->getAttribute($ATTRIBUTE_OP);
                  my $attribute_op_sibling=$sibling->getAttribute($ATTRIBUTE_OP);
                  if (!($attribute_op_parent eq $OP_UPDATE && ($attribute_op_self eq $OP_UPDATE || $attribute_op_sibling eq $OP_UPDATE))){
                    print "\ndumplicate cols:$element_name for same table:$name_parent at $line\n";  last;
		  }
	       }

             }
             $sibling=$sibling->getPreviousSibling();
         }
     }
   }
=cut
     # save the id attributed into local_id
     my $local_id=$element->{'Attributes'}->{$ATTRIBUTE_ID};
     my $db_id;
     my $op=$element->{'Attributes'}->{$ATTRIBUTE_OP};
     my $ref=$element->{'Attributes'}->{$ATTRIBUTE_REF};
    if ($local_id && $local_id ne ''){
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
      $ref=~ s/\&amp;/\&/g;
      $ref=~ s/\&lt;/</g;
      $ref=~ s/\&gt;/>/g;
      $ref=~ s/\&quot;/\"/g;
      $ref=~ s/\&apos;/\'/g;
      $ref=~ s/\\/\\\\/g;
       $hash_level_ref{$level}=$ref;
       $AoH_ref[$level]{$element_name}=$ref;
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
         my (undef, $element_name_temp)=split(/\./, $key);
         if ($element_name eq $element_name_temp && $AoH_op[$level]{$element_name} ne 'update'){
           delete $AoH_data[$level]{$key};
	 }
         elsif ($element_name eq $element_name_temp && $AoH_op[$level]{$element_name} eq 'update'){
           delete $AoH_data_new[$level]{$key};
	 }
    }


    # if self is table_element
    if (defined $hash_ddl{$element_name} ){
       $replace_local_id--;
       $replace_db_id--;
       # check if parent_element is table_element
       # when come to subordinary table(e.g cvrelationship), and previous sibling element is not table column(if is, it alread out it)  output primary table(e.g cvterm)
       $table_name=$element_name;
       if (  defined $hash_ddl{$hash_level_name{$level-1}}){
	  print "\nstart to output the module table:$hash_level_name{$level-1}, level:$level before parse sub table:$table_name" if ($DEBUG==1);
          my  $hash_data_ref;
          # here test for 'ref' attribute
          if (defined $AoH_ref[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_ref[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key}){
                  $hash_data_ref=&_get_ref_data($hash_level_name{$level-1}, $hash_id{$hash_id_key});
	       }
               else {
                 my $temp_db_id=&_get_accession( $AoH_ref[$level-1]{$hash_level_name{$level-1}},$hash_level_name{$level-1}, $level-1);
                 if (defined $temp_db_id){
                      $hash_data_ref=&_get_ref_data($element_name, $temp_db_id );
		 }
               }


	  }
          else {
               $hash_data_ref=&_extract_hash($AoH_data[$level], $hash_level_name{$level-1});
          }


	 if (%$hash_data_ref){
           my  $hash_ref=&_data_check($hash_data_ref,  $hash_level_name{$level-1}, $level, \%hash_level_id, \%hash_level_name );
           # set the key for %hash_id in the format of table_name:local_id
           my $hash_id_key;
           my $db_id_value;
           if (defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
              $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
           }
           # here for different type of op, deal with the $hash_data_ref and return the $db_id
           if ($hash_level_op{$level-1} eq 'update'){
             my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level], $hash_level_name{$level-1});
                $db_id=&_check_local_db($hash_ref, $hash_level_name{$level-1});
                if (!(defined $db_id)){
                        $db_id=$replace_db_id;
                        my $db_id_key=$hash_level_name{$level-1}.":".$replace_db_id;
                        $HoH_data{$db_id_key}=$hash_ref;

                        $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
		}
                #even in db, need to verify that it is not DELETED in previous transaction
                else {
                    my $temp_key=$hash_level_name{$level-1}.":".$db_id;
                    if (exists $hash_db_id_deleted{$temp_key}){
                         $db_id=undef;
		    }
                }

               #save the pair of local_id/db_id
	       if (defined $db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
                 my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
                 $db_id_value=$hash_level_name{$level-1}.":".$db_id;
                 if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
		 }
                 $hash_id{$hash_id_key}=$db_id;
	       }
	       if (defined $db_id){
                  $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	       }
               else {
                  print  "\nyou try to update a record which do not exist in db now";
                  &_create_log(\%hash_trans, $hash_ref, $hash_level_name{$level-1});
               }
           }
           elsif ($hash_level_op{$level-1} eq 'delete'){
             my $db_id_key;
                   $db_id=&_check_local_db($hash_ref, $hash_level_name{$level-1});
                   if ($db_id){
                       $db_id_key=$hash_level_name{$level-1}.":".$db_id;
                       delete $HoH_data{$db_id_key};
                       $hash_db_id_deleted{$db_id_key}=1;
                       delete $AoH_db_id[$level-1]{$hash_level_name{$level-1}};
                       foreach my $key (keys %hash_id){
                              my ($temp_table, $temp)=split(/\:/, $key);
	   	              if ($hash_id{$key} eq $db_id && $temp_table eq $hash_level_name{$level-1}){
                                 delete $hash_id{$key};
                                 last;
		              }
	               }
		   }
           }
           elsif ($hash_level_op{$level-1} eq 'insert'){
                     $db_id=&_check_local_db($hash_ref, $hash_level_name{$level-1});
                     if ($db_id) {
                        my $db_id_key=$hash_level_name{$level-1}.":".$db_id;
                       if (!(defined $hash_db_id_deleted{$db_id_key})){
                          print  "\nyou try to insert a duplicate record into db";
                         &_create_log(\%hash_trans, $hash_ref, $hash_level_name{$level-1});
		       }
		     }
                     else {
                        $db_id=$replace_db_id;
                        my $db_id_key=$hash_level_name{$level-1}.":".$replace_db_id;
                        $HoH_data{$db_id_key}=$hash_ref;

                        $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
                        #save the pair of local_id/db_id
	                if ($db_id ne '' && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
                              my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
                              if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                                print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
	                      }
                              $hash_id{$hash_id_key}=$db_id;
	                }
                     }
          }
          elsif ($hash_level_op{$level-1} eq 'lookup'){
                my $db_id_key;
                $db_id=&_check_local_db($hash_ref, $hash_level_name{$level-1});
                    $db_id=&_check_local_db($hash_ref, $hash_level_name{$level-1});
                    if (!$db_id){
                       $db_id=$replace_db_id;
                       $db_id_key=$hash_level_name{$level-1}.":".$db_id;
                       $HoH_data{$db_id_key}=$hash_ref;
		    }
                    $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
                    if (defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
                        my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
                        if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                            print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
		        }
                        $hash_id{$hash_id_key}=$db_id;
		    }
          }
          elsif ($hash_level_op{$level-1} eq 'force'){
             my $db_id_key;
                  $db_id=&_check_local_db($hash_ref,$hash_level_name{$level-1});

               if (!$db_id){
                    $db_id=$replace_db_id;
                    $db_id_key=$hash_level_name{$level-1}.":".$db_id;
                    $HoH_data{$db_id_key}=$hash_ref;
	       }

             #save the pair of local_id/db_id
	     if ($db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level-1]{$hash_level_name{$level-1}}: at line:$line";
	       }
               $hash_id{$hash_id_key}=$db_id;
	     }
             $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;

           }
 	 }
        }

        my  $table_col=$hash_ddl{$table_name};
        my @array_col=split(/\s+/, $table_col);
        undef %hash_table_col;
        foreach my $i(0..$#array_col){
	   $hash_table_col{$array_col[$i]}=1;
         #  print "\ncol:$array_col[$i]";
        }

        if (!(defined $AoH_op[$level]{$element_name})){
            $op='force';
            $hash_level_op{$level}=$op;
            $AoH_op[$level]{$element_name}=$op;
        }
    }
   # otherwise, check if it is colum, if not, exit and show error. 
   elsif ( $element_name ne  $root_element  ) {

     #  print "\ntable:$hash_level_name{$level-1}:\tcolumn:$element_name";
     my $col_ref=&_get_table_columns($hash_level_name{$level-1});
     #not column element name
     if (!(exists $col_ref->{$element_name})){
        print  "\n invalid element...... element:$element_name";
        print  "\ntable:$hash_level_name{$level-1}:\tcolumn:$element_name";
        print  "\n invalid element...... element:$element_name" if ($DEBUG==1);
        print  "\ntable:$hash_level_name{$level-1}:\tcolumn:$element_name"  if ($DEBUG==1);
        #&_create_log(\%hash_trans, \%hash_id, $log_file);
        foreach my $key(keys %$col_ref){
            print "\ncharacter invalid column, key:$key:value:$col_ref->{$key}";
	}
       exit(1);

     }
     #column element
     else {
        my $temp_key=$hash_level_name{$level-1}.".".$element_name;
        if ($AoH_op[$level-1]{$hash_level_name{$level-1}} ne 'update'){
           delete $AoH_data[$level]{$temp_key};
	}
        else {
	  if ($AoH_op[$level]{$hash_level_name{$level}} eq 'update'){
            delete $AoH_data_new[$level]{$temp_key};
	  }
          else {
            delete $AoH_data[$level]{$temp_key};
          }
        }
     }
   }
 }

sub characters {
    my( $self, $properties ) = @_;
     my $data = $properties->{'Data'};

     $data =~ s/\&amp;/\&/g;
     $data =~ s/\&lt;/</g;
     $data =~ s/\&gt;/>/g;
     $data =~ s/\&quot;/\"/g;
     $data =~ s/\&apos;/\'/g;
     $data =~ s/\\/\\\\/g;
     #$data =~ s/\&amp;nbsp;/\s/g;
    chomp($data);
    my $data_length=length $data;

    # data will be in @AoH_data: index of array: $level, key of hash: $table_name.$column

   $character.=$data;

}



sub end_element {
  my ($self, $element) = @_;
  my $parent_element=$hash_level_name{$level-1};
  my $element_name=$element->{Name};
  my $table;
  my $table_name_id=$table_name."_id";
  my $hash_ref;

  print "\nend_element_name:$element_name"  if ($DEBUG==1);
   # come to end of document
  if ($element_name eq $root_element){
    return;
  }


     #here deal witht the character here no matter what.
     chomp $character if defined $character;
     $character=~s/^\s+//g if defined $character;
    # $character= utf8($character)->latin1;
     if ($element_name ne $root_element && defined $hash_ddl{$parent_element}){
        my $hash_ref_cols=&_get_table_columns($parent_element);
        if  (defined $hash_ref_cols->{$element_name} && defined $character &&  ($character =~/\S/ ||  $character eq '-') && $character ne "\t"){
        # if  (defined $hash_ref_cols->{$element_name} ){
           my  $key=$hash_level_name{$level-1}.".".$element_name;
             # treat differently for update and other operation
                if ($AoH_op[$level-1]{$parent_element} eq 'update'){
		  if ($AoH_op[$level]{$element_name} eq 'update'){
    
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
                      print  "\nTry to update a column which the op for table is not update.....";
                  }
	        }
         #print "\n\nkey:$key\tvalue:$AoH_data[$level]{$key}\tlevel:$level";


          #here to save all the currrent transaction information in case of abnormal transaction happen, and undef at end of each trans
           if (!(defined $hash_ddl{$element_name}) && $hash_level_name{$level-2} eq $root_element){
                $hash_trans{$element_name}=$AoH_data[$level]{$key};
            }
       }
     }
    undef $character;



   my $line=$parser->location()->{LineNumber};
=head
   #DOM structure for extra validation
   my $node_temp=$node_DOM_current;
   $node_DOM_current=$node_DOM_current->getParentNode();
   if ($node_DOM_current->getNodeName() eq $root_element){
      #$node_DOM_current->removeChild ($node_temp);
	  $node_temp->dispose;
   }
=cut
  if (defined $hash_ddl{$element_name} && $hash_level_name{$level-1} eq $root_element){
     undef %hash_trans;
  }

   # ------------------------------------------------------------
   # here come to the end of table
   # -------------------------------------------------------------
   # self: table_element
   if ($hash_ddl{$element_name}) {
        my $hash_ref=undef;
        my $hash_ref_new=undef;
        my $db_id;
        my $hash_ref_cols=&_get_table_columns($element_name);

        # if sub_element is not table_element, and is  col of this table, extract data
        # for nesting case, which $hash_level_name{$level+1} is table_element already done in start_element
        if (defined $hash_ref_cols->{$hash_level_name{$level+1}} && !$hash_ddl{$hash_level_name{$level+1}} && !(defined $AoH_ref[$level]{$hash_level_name{$level}})){
            my  $hash_data_ref=&_extract_hash($AoH_data[$level+1], $element_name);
            # for empty hash_ref, do nothing
            if ($hash_data_ref){
               my  $hash_ref=&_data_check($hash_data_ref, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
               # here for different type of op, deal with the $hash_data_ref and return the $db_id
               if ($hash_level_op{$level} eq 'update'){
                  my $db_id_key;
                  my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level+1], $element_name);
                  #  my  $hash_data_ref_new=&_data_check($hash_ref_new_temp, $element_name, $level+1, \%hash_level_id, \%hash_level_name );

                  $db_id=&_check_local_db($hash_ref, $element_name);
		  if (!(defined $db_id)){
                                $db_id=$replace_db_id;
                                $db_id_key=$element_name.":".$db_id;
                                $HoH_data{$db_id_key}=$hash_ref;
                                $AoH_db_id[$level]{$element_name}=$db_id;
                                if (defined $AoH_local_id[$level]{$element_name}){
                                   my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                                   if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                                       print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
	 	                   }
                                   $hash_id{$hash_id_key}=$db_id;
				}
		  }
            } # end of 'update'
            elsif ($hash_level_op{$level} eq 'delete'){
               my $db_id_key;
               $db_id=&_check_local_db($hash_ref, $element_name);
               if ($db_id){
                  foreach my $key (keys %hash_id){
                    my ($temp_table, $temp)=split(/\:/, $key);
	            if ($hash_id{$key} eq $db_id && $element_name eq $temp_table){
                       delete $hash_id{$key};
                       last;
	  	    }
	         }
                  $db_id_key=$element_name.":".$db_id;
                  $hash_db_id_deleted{$db_id_key}=1;
                  delete $HoH_data{$db_id_key};
                  delete $AoH_db_id[$level]{$element_name};
	       }
             } #end of  'delete'
             elsif ($hash_level_op{$level} eq 'insert'){
                     my $db_id_key;
                     $db_id=&_check_local_db($hash_ref, $element_name);
                     if ($db_id ){
                        $db_id_key=$element_name.":".$db_id;
                        if (!(defined $hash_db_id_deleted{$db_id_key})){
                            print  "\nyou try to insert duplicate record at line:$line";
                            &_create_log(\%hash_trans, $hash_ref , $element_name );
                        }
	   	     }
                     else {
                            $db_id=$replace_db_id;
                            $db_id_key=$element_name.":".$db_id;
                            $HoH_data{$db_id_key}=$hash_ref;
                            $AoH_db_id[$level]{$element_name}=$db_id;
                            if (defined $AoH_local_id[$level]{$element_name}){
                                 my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                                 if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                                   print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
		                 }
                                 $hash_id{$hash_id_key}=$db_id;
	        	    }
                     }
             } # end of 'insert'
             elsif ($hash_level_op{$level} eq 'lookup'){
                     my $db_id_key;
                  $db_id=&_check_local_db($hash_ref, $element_name);
                 if (!(defined $db_id)){
                     $db_id=$replace_db_id;
                     $db_id_key=$element_name.":".$db_id;
                     if (!(defined  $hash_db_id_deleted{$db_id_key})){
                        $HoH_data{$db_id_key}=$hash_ref;
                        $AoH_db_id[$level]{$element_name}=$db_id;
                        if (defined $AoH_local_id[$level]{$element_name}){
                           my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                           if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                              print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
	 	           }
                           $hash_id{$hash_id_key}=$db_id;
		        }
		   }
		 }
                 else{
                      $db_id_key=$element_name.":".$db_id;
                      if (defined  $hash_db_id_deleted{$db_id_key}){
                            print  "\nthe record you try to lookup already had been deleted at line $line";
                            &_create_log(\%hash_trans, $hash_ref , $element_name );
		      }
                 }
             } # end of 'lookup'
             elsif ($hash_level_op{$level} eq 'force'){
                   my $db_id_key;
                   $db_id=&_check_local_db($hash_ref, $element_name);
                   if (!$db_id){
                         $db_id=$replace_db_id;
                         $db_id_key=$element_name.":".$db_id;
                         delete $hash_db_id_deleted{$db_id_key};
                         $HoH_data{$db_id_key}=$hash_ref;
                         $AoH_db_id[$level]{$element_name}=$db_id;
			 if (defined $AoH_local_id[$level]{$element_name}) {
                             my  $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                             if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                                print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
                                #warn "\nhash_id_key:$hash_id_key\texist db_id:$hash_id{$hash_id_key}, new db_id:$db_id\telement:$element_name";
	    	             }
                             $hash_id{$hash_id_key}=$db_id;
			 }
		   }
                   else {
                      $db_id_key=$element_name.":".$db_id;
                      if (defined $hash_db_id_deleted{$db_id_key}){
                         delete $hash_db_id_deleted{$db_id_key};
		      }
                   }
             } # end of force

             # save the pair of local_id/db_id
             # if ($hash_level_op{$level} ne 'update' && $db_id && defined $AoH_local_id[$level]{$element_name}){
             if ($db_id && defined $AoH_local_id[$level]{$element_name} && $AoH_op[$level]{$element_name} ne 'delete'){
                 my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                 if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
		 }
                 $hash_id{$hash_id_key}=$db_id;
	     }
             if ($db_id){
                 $AoH_db_id[$level]{$element_name}=$db_id;
	     }
             print "\nend_element is $element_name table element, and sub element is col of this table"  if ($DEBUG==1);
             print "\nlocal_id:$AoH_local_id[$level]{$element_name}:\tdb_id:$db_id:"  if ($DEBUG==1);
          }
        }
        #for case using ref attribuate to ref object, self is still table_element. Key difference: use ref to retrieve $hash_data_ref
	elsif (defined $AoH_ref[$level]{$hash_level_name{$level}} ){
          my  $hash_id_key=$element_name.":".$AoH_ref[$level]{$hash_level_name{$level}};
          my  $hash_data_ref;
          if (defined $hash_id{$hash_id_key}){
              $hash_data_ref=&_get_ref_data($element_name, $hash_id{$hash_id_key});
  	  }
          # to see whether it is accession number
          else {
             my $temp_db_id;
             #if ($AoH_ref[$level]{$hash_level_name{$level}} =~ /([a-zA-Z]+)\:([a-zA-Z0-9]+)(\.\d)*/){
                $temp_db_id=&_get_accession( $AoH_ref[$level]{$hash_level_name{$level}},$hash_level_name{$level}, $level);
             #}
             #my $temp_db_id=&_get_accession($AoH_ref[$level]{$hash_level_name{$level}}, $element_name, $level);
             if ($temp_db_id){
                $hash_data_ref=&_get_ref_data($element_name, $temp_db_id );
	     }
          }

          # for empty hash_ref, do nothing
          if ($hash_data_ref){
            my  $hash_ref=&_data_check($hash_data_ref, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
            # here for different type of op, deal with the $hash_data_ref and return the $db_id
            if ($hash_level_op{$level} eq 'update'){
               my $db_id_key;
               my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level+1], $element_name);
               #  my  $hash_data_ref_new=&_data_check($hash_ref_new_temp, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
                  $db_id=&_check_local_db($hash_ref, $element_name);
		  if (!(defined $db_id)){
                                $db_id=$replace_db_id;
                                $db_id_key=$element_name.":".$db_id;
                                $HoH_data{$db_id_key}=$hash_ref;
                                $AoH_db_id[$level]{$element_name}=$db_id;
                                if (defined $AoH_local_id[$level]{$element_name}){
                                   my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                                   if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                                      print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
	  	                   }
                                   $hash_id{$hash_id_key}=$db_id;
				}
		  }
 

            }
            elsif ($hash_level_op{$level} eq 'delete'){
               my $db_id_key;
               $db_id=&_check_local_db($hash_ref, $element_name);
               if ($db_id){
                  foreach my $key (keys %hash_id){
                    my ($temp_table, $temp)=split(/\:/, $key);
	            if ($hash_id{$key} eq $db_id && $element_name eq $temp_table){
                       delete $hash_id{$key};
                       last;
	  	    }
	         }
                  $db_id_key=$element_name.":".$db_id;
                  $hash_db_id_deleted{$db_id_key}=1;
                  delete $HoH_data{$db_id_key};
                  delete $AoH_db_id[$level]{$element_name};
	       }

            }
            elsif ($hash_level_op{$level} eq 'insert'){
               print  "\nit is invalid xml to have 'insert' and 'ref' appear together at line $line";
               &_create_log(\%hash_trans, $hash_ref, $element_name);
            }
            elsif ($hash_level_op{$level} eq 'lookup'){
                     my $db_id_key;
                  $db_id=&_check_local_db($hash_ref, $element_name);
                 if (!(defined $db_id)){
                     $db_id=$replace_db_id;
                     $db_id_key=$element_name.":".$db_id;
                     if (!(defined  $hash_db_id_deleted{$db_id_key})){
                        $HoH_data{$db_id_key}=$hash_ref;
                        $AoH_db_id[$level]{$element_name}=$db_id;
                        if (defined $AoH_local_id[$level]{$element_name}){
                           my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                           if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                               print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
	  	           }
                           $hash_id{$hash_id_key}=$db_id;
		        }
		   }
		 }
                 else{
                      $db_id_key=$element_name.":".$db_id;
                      if (defined  $hash_db_id_deleted{$db_id_key}){
                            print  "\nthe record you try to lookup already had been deleted at line $line";
                            &_create_log(\%hash_trans, $hash_ref , $element_name );
		      }
                 }
           }
            elsif ($hash_level_op{$level} eq 'force'){
                   my $db_id_key;
                   $db_id=&_check_local_db($hash_ref, $element_name);
                   if (!$db_id){
                         $db_id=$replace_db_id;
                         $db_id_key=$element_name.":".$db_id;
                         delete $hash_db_id_deleted{$db_id_key};
                         $HoH_data{$db_id_key}=$hash_ref;
                         $AoH_db_id[$level]{$element_name}=$db_id;
			 if (defined $AoH_local_id[$level]{$element_name}) {
                             my  $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
                             if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                                print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
		             }
                             $hash_id{$hash_id_key}=$db_id;
			 }
		   }
                   else {
                      $db_id_key=$element_name.":".$db_id;
                      if (defined $hash_db_id_deleted{$db_id_key}){
                         delete $hash_db_id_deleted{$db_id_key};
		      }
                   }
            }

            # save the pair of local_id/db_id
            # if ($hash_level_op{$level} ne 'update' && $db_id && defined $AoH_local_id[$level]{$element_name}){
            if ($db_id && defined $AoH_local_id[$level]{$element_name} && $AoH_op[$level]{$element_name} ne 'delete'){
               my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
               if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $db_id){
                    print "\nyou define two different record with same local_id:$AoH_local_id[$level]{$element_name}: at line:$line";
	       }
               $hash_id{$hash_id_key}=$db_id;
	    }
            if ($db_id){
               $AoH_db_id[$level]{$element_name}=$db_id;
	    }
               print "\nend_element is $element_name table element, and sub element is col of this table"  if ($DEBUG==1);
               print "\nlocal_id:$AoH_local_id[$level]{$element_name}:\tdb_id:$db_id:"  if ($DEBUG==1);
         }
	}

        #if parent: column element, substitute the foreign key value with db_id
	if (!$hash_ddl{$hash_level_name{$level-1}} && $hash_level_name{$level-1} ne $root_element){
           my $key=$hash_level_name{$level-2}.".".$hash_level_name{$level-1};
	   if ($hash_level_op{$level-2} eq 'update'){
               if ($hash_level_op{$level-1} eq 'update'){
                   $AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
	       }
               else {
                   $AoH_data_new[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
               }
	    }
           else {
               $AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
           }
          print "\nsubstitute it with db_id:$AoH_db_id[$level]{$element_name}:level:$level-1:key:$key:" if ($DEBUG==1);
	}
   } # end of self: table element
   # self: column element
   else {
      my $temp_foreign=$hash_level_name{$level-1}.":".$element_name."_ref_table";
      my $key=$hash_level_name{$level-1}.".".$element_name;
      my $primary_table=$hash_ddl{$temp_foreign};
      print "\n$element_name is column_element"  if ($DEBUG==1);
       #if is foreign key, and next level eleme nt is the primary table
      if (defined $hash_ddl{$temp_foreign} && defined $hash_level_name{$level+1} && $hash_ddl{$temp_foreign} eq $hash_level_name{$level+1} &&  $hash_ddl{$temp_foreign} ne '' && (defined $hash_level_sub_detect{$level+1})){
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
             my $id;
             if ($AoH_data[$level]{$key} =~ /([a-zA-Z]+)\:([a-zA-Z0-9]+)(\.\d)*/){
                $id=1;
             }
             #my $id=&_get_accession($AoH_data[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data[$level]{$key}=$id;
                 if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $id){
                    print "\nyou define two different record with same local_id:: at line:$line";
		 }
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print  "\n$element_name: can't retrieve the id based on the accession:$AoH_data[$level]{$key} at line:$line";
                 #&_create_log(\%hash_trans, \%hash_id, $log_file);
             }
           }
          else {
                print  "\n$element_name:$AoH_data[$level]{$key}: is not accession, or local_id:$AoH_data[$level]{$key} is not defined yet at line:$line";
               # &_create_log(\%hash_trans, \%hash_id , $log_file );
          }
           print "\nend_element: self:col, table_op:not update"  if ($DEBUG==1);
       	}
        #table:update, col:update
        elsif ($hash_level_op{$level-1} eq 'update' && $hash_level_op{$level} eq 'update' ){
          my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data_new[$level]{$key};
	  if (defined $hash_id{$hash_id_key}){
              $AoH_data_new[$level]{$key}=$hash_id{$hash_id_key};
	  }
          elsif(defined $hash_accession_entry{$primary_table}) {
             my $id;
             if ($AoH_data_new[$level]{$key} =~ /([a-zA-Z]+)\:([a-zA-Z0-9]+)(\.\d)*/){
                $id=1;
             }
             #my $id=&_get_accession($AoH_data_new[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data_new[$level]{$key}=$id;
                 if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $id){
                    print "\nyou define two different record with same local_id:: at line:$line";
		 }
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print  "\n$element_name: can't retrieve the id based on the accession:$AoH_data_new[$level]{$key} at line:$line";
                # &_create_log(\%hash_trans, \%hash_id,  $log_file);
             }
          }
          else {
                print  "\n$element_name:$AoH_data_new[$level]{$key} is not accession, or local_id:$AoH_data_new[$level]{$key} is not defined yet at line:$line";
                #&_create_log(\%hash_trans, \%hash_id, $log_file);
          }
          print "\nend_element: self:col, table_op:update, col_op:update"  if ($DEBUG==1);
        }
        #table: update, col: not upate
        else {
           my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data[$level]{$key};
	   if (defined $hash_id{$hash_id_key}){
              $AoH_data[$level]{$key}=$hash_id{$hash_id_key};
	    }
           elsif(defined $hash_accession_entry{$primary_table}) {
             my $id;
             if ($AoH_data[$level]{$key} =~ /([a-zA-Z]+)\:([a-zA-Z0-9]+)(\.\d)*/){
                $id=1;
             }
             #my $id=&_get_accession($AoH_data[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data[$level]{$key}=$id;
                 if (defined $hash_id{$hash_id_key} && $hash_id{$hash_id_key} != $id){
                    print "\nyou define two different record with same local_id:: at line:$line";
		 }
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print  "\n$element_name: can't retrieve the id based on the accession:$AoH_data[$level]{$key} at line:$line";
                # &_create_log(\%hash_trans, \%hash_id, $log_file);
             }
           }
          else {
                print  "\n$element_name $AoH_data[$level]{$key} is not accession, or local_id:$AoH_data[$level]{$key} is not defined yet at line:$line";
                # &_create_log(\%hash_trans, \%hash_id, $log_file);

          }
         print "\nend_element: self:col, table_op:update, col_op:not update" if ($DEBUG==1);
        }
       print "\nprimary table:$hash_ddl{$temp_foreign}:sub element:$hash_level_name{$level+1}" if ($DEBUG==1);
       print "\n\n$element_name is foreign key, no sub element, has data, db_id:$AoH_data[$level]{$key}" if ($DEBUG==1);
      }
      # foreign key, no sub element, but NO data, error .......
      elsif (defined $hash_ddl{$temp_foreign} && $hash_ddl{$temp_foreign} ne $hash_level_name{$level+1} && $hash_ddl{$temp_foreign} ne '' && !$AoH_db_id[$level+1]{$primary_table} && ($AoH_data[$level]{$key} eq '')) {
        print  "\n\n$element_name: is foreign key, no sub element, not data, error .....at line $line";
        #&_create_log(\%hash_trans, \%hash_id, $log_file);
      }
       # not foreign key, do nothing
      elsif (!(defined $hash_ddl{$temp_foreign}) || !$hash_ddl{$temp_foreign}){
        # print "\n$element_name: is not foreign key, do nothing .....:$temp_foreign";
      }

   }
  delete $hash_level_sub_detect{$level+1};

  $level--;

}


sub end_document {
    #clean the load.log 
    system("delete load.log") if -e 'load.log';

}


#sub entity_reference {
# my ($self, $properties) = @_;
 #do nothing
#}


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
    my $result;

  # print "\nelement_name in extract :$element:";
  #  print "\n\nnew table data...";
    foreach my $key (keys %$hash_ref){
     #  print "\nkey:$key:\tvalue:$hash_ref->{$key}:\telement:$element";
    }



    my $content=$element.".";
    foreach my $value (keys %$hash_ref){
	if (index($value, $content) ==0 ){
            my $start=length $content;
            my $key=substr($value, $start);
          #  print "\ncontent:$content:value:$value:\tkey:$key:";
            $result->{$key}=$hash_ref->{$value};
            delete $hash_ref->{$value};
	}
    }

    if (!(defined %$result)){
     #  return ;
    }

    foreach my $key (keys %$hash_ref){
      # print "\nleft key:$key:\tvalue:$hash_ref{$key}:";
    }
   # print "\n\nelement_name:$element";
    return $result;
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
    my $hash_level_id=shift;
    my $hash_level_name_ref=shift;
    my %result;

    my $line=$parser->location()->{LineNumber};
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

    my $table_non_null=$table."_non_null_cols";
    my @temp=split(/\s+/, $hash_ddl{$table_non_null});
    my $table_id_string=$table."_primary_key";
    my $table_id=$hash_ddl{$table_id_string};
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
            print "\nyou try to retrieve more than ONE not_null column using context_retrive at line:$line for column:$hash_context_retrieved{$hash_ddl{$temp_key}} and $temp[$i] from table:$table" if defined $hash_context_retrieved{$hash_ddl{$temp_key}};
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
            $hash_ref->{$temp[$i]}=$retrieved_value;
	  }
         elsif (!(defined $hash_non_null_default{$temp[$i]}) && $DELETE_BATCH!=1) {
             print  "\n\ncan not find the value for required element:$temp[$i] of table:$table from context .....";
             &_create_log(\%hash_trans, $hash_ref, $table); 
          }
      }
      elsif ($temp[$i] ne $table_id &&  !(defined $hash_ref->{$temp[$i]}) && !(defined $hash_foreign_key{$temp[$i]}) && !(defined $hash_non_null_default{$temp[$i]})  && $DELETE_BATCH!=1) {
          print  "\n\nyou missed the required element:$temp[$i] for table:$table, also it is not foreign key";
          &_create_log(\%hash_trans, $hash_ref, $table);

      }
    }

    #   delete $hash_ref->{$value};


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
  #  print "\ncontext_retrieve:level:$level:primary_table:$primary_table";
    for ( my $i=$level-1; $i>=0; $i--){
  #    print "\ncontext check hash_level_name:$hash_level_name_ref->{$i}";
      if ($primary_table eq $hash_level_name_ref->{$i}){
        print "\ncontext_retrieve:level:$level:primary_table:$primary_table:value:$AoH_db_id[$i]{$primary_table}" if ($DEBUG==1); 
        $result= $AoH_db_id[$i]{$primary_table};
        last;
      }
    }
    print "\nresult is:$result"  if ($DEBUG==1);
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
  my $hash_table_column_ref=undef;
        foreach my $i(0..$#array_col){
          if ($array_col[$i] ne ''){
	   $hash_table_column_ref->{$array_col[$i]}=1;
	 }
         #  print "\ncol:$array_col[$i]";
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

  my ($dbname, $acc, $version, $db_id, $stm_select, $stm_insert);

  if ($accession =~ /([a-zA-Z]+)\:([a-zA-Z0-9]+)(\.\d)*/){
      my @temp=split(/\:/, $accession);
      $dbname=$temp[0];
      if ($temp[1] =~/\./){
         my @temp1=split(/\./, $temp[1]);
         $acc=$temp1[0];
         $version=$temp1[1];
      }
      else {
         $acc=$temp[1];
         $version='';
      }

    my %hash_ref_cv=(cvname=>'pub type');
    my $cv_id=&_check_local_db(\%hash_ref_cv, 'cv');
    if (!$cv_id){
        $replace_db_id--;
        $cv_id=$replace_db_id;
        my $db_id_key="cv:".$cv_id;
        $HoH_data{$db_id_key}=\%hash_ref_cv;
    }

    my %hash_ref_cvterm=(name=>'curator note', cv_id=>$cv_id);
    my $cvterm_id=&_check_local_db(\%hash_ref_cvterm, 'cvterm');
    if (!$cvterm_id){
        $replace_db_id--;
        $cvterm_id=$replace_db_id;
        my $db_id_key="cvterm:".$cvterm_id;
        $HoH_data{$db_id_key}=\%hash_ref_cvterm;
    }


    my %hash_ref_organism=(genus=>'Drosophila', species=>'melanogaster', taxgroup=>'0');
    my $organism_id=&_check_local_db(\%hash_ref_organism, 'organism');
    if (!$organism_id){
        $replace_db_id--;
        $organism_id=$replace_db_id;
        my $db_id_key="organism:".$organism_id;
        $HoH_data{$db_id_key}=\%hash_ref_organism;
    }

    if ($table eq 'dbxref'){
       my %hash_ref_dbxref=(dbname=>$dbname, accession=>$acc, version=>$version);
       my $dbxref_id=&_check_local_db(\%hash_ref_dbxref, 'dbxref');
       if (!$dbxref_id){
           $replace_db_id--;
           $dbxref_id=$replace_db_id;
           my $db_id_key=$table.":".$dbxref_id;
           $HoH_data{$db_id_key}=\%hash_ref_dbxref;
       }
       $AoH_db_id[$level]{$element_name}=$dbxref_id;
       if (defined $AoH_local_id[$level]{$table}){
           my $hash_id_key=$table.":".$AoH_local_id[$level]{$table};
           $hash_id{$hash_id_key}=$dbxref_id;
       }
       $replace_db_id--;
       return $dbxref_id;
    }

    if ($table eq 'feature'){
       my %hash_ref_feature=(uniquename=>$accession, organism_id=>$organism_id);
       my $feature_id=&_check_local_db(\%hash_ref_feature, 'feature');
       if (!$feature_id){
           $replace_db_id--;
           $feature_id=$replace_db_id;
           my $db_id_key=$table.":".$feature_id;
           $HoH_data{$db_id_key}=\%hash_ref_feature;
       }
       $AoH_db_id[$level]{$element_name}=$feature_id;
       if (defined $AoH_local_id[$level]{$table}){
           my $hash_id_key=$table.":".$AoH_local_id[$level]{$table};
           $hash_id{$hash_id_key}=$feature_id;
       }
       $replace_db_id--;
       return $feature_id;
    }
  }
  else {
        print "\nsorry, the accession:$accession is not correct format as: db:acc[.version]";
          &_create_log(\%hash_trans, \%hash_id, $table);
          #exit(1);
  }
  return;
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


 foreach my $key (keys %HoH_data){
   my ($table_temp, $id_temp)=split(/\:/, $key);
   if ($table eq $table_temp && $id eq $id_temp){
       return $HoH_data{$key};
   }
 }

return;
}

=head2 _check_local_db

  Arg [1]    : hash reference contains data already parse to for specific record
  Arg [2]    : table name

  Example    :
  Description: private method
               since the validator can only have select operation, all the new data will store in %HoH_data,
               here to check again this local database, if exist, return the table_name:db_id

  Returntype : string, table_name:db_id or null
  Exceptions : Thrown is invalid arguments are provided
  Pre        :

=cut

sub _check_local_db(){
   my $hash_ref=shift;
   my $table=shift;

   # only need the unique_cols information to idenfity a record
   my $hash_ref_input;

   my $unique_string=$table."_unique";
   my $unique_default=$table."_non_null_default";
   my %hash_default;
   if (defined $hash_ddl{$unique_default}){
     my @array_default=split(/\s+/, $hash_ddl{$unique_default});
     for my $i(0..$#array_default){
         $hash_default{$array_default[$i]}=1;
     }
   }
   my @array_unique=split(/\s+/, $hash_ddl{$unique_string});
   for my $i(0..$#array_unique){
     if (defined $hash_ref->{$array_unique[$i]}){
        $hash_ref_input->{$array_unique[$i]}=$hash_ref->{$array_unique[$i]};
     }
     elsif (!(defined $hash_default{$array_unique[$i]}) && $DELETE_BATCH!=1) {

        print  "\nrecord for this table:$table missed value for the unique column:$array_unique[$i]";
        &_create_log(\%hash_trans, $hash_ref, $table);
        return ;
     }
   }

   my $db_id;
   foreach my $key1(keys %HoH_data){
     my ($table_temp, $db_id_temp)=split(/\:/, $key1);
     if ($table_temp eq $table){

          $db_id=$db_id_temp;
          my $hash_ref_temp=$HoH_data{$key1};
          return if (ref($hash_ref_temp) ne "HASH");
          foreach my $key2 (keys %$hash_ref_input) {
            #return undefined if: not defined, or != for real, or 'ne' for string
	    if (!(defined $hash_ref_input->{$key2}) || !(defined $hash_ref_temp->{$key2})){
                 undef $db_id;
                 last ;
	    }
            else {
	      if (($hash_ref_input->{$key2} =~/^\d+$/ || $hash_ref_temp->{$key2} =~/^\d+$/) && $hash_ref_temp->{$key2} != $hash_ref_input->{$key2}){
                 undef $db_id;
                 last ;
	      }
              elsif ($hash_ref_temp->{$key2} ne $hash_ref_input->{$key2}){
                 undef $db_id;
                 last ;
	      }
	    }

#  	      if (!(defined $hash_ref_input->{$key2} && ($hash_ref_temp->{$key2} eq $hash_ref_input->{$key2} || $hash_ref_temp->{$key2} == $hash_ref_input->{$key2}))){
#                 undef $db_id;
#                 last ;
#   	      }
          }
          if (defined $db_id){
             return $db_id;
          }
     }
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
   my $hash_data=shift;
   my $table=shift;
   print "\nit will use this log_file:$log_file: to recover the process if you set the -is_recovery=1" if ($DEBUG==1);


   print  "\nsorry, for some reason, this process stop before finish the following main transaction(child of root):$hash_trans->{table}";
   my $line=$parser->location()->{LineNumber};
   print  "\nproblem around the following line:$line\n";
   print "\nproblem around the following line:$line\n";
   foreach my $key (keys %$hash_trans){
     if ($key ne 'table'){
         print  "\nelement:$key\tvalue:$hash_trans->{$key}";
    }
   }

   print  "\n\ntable name for this specific record:$table\n";
   foreach my  $key (keys %$hash_data){
      print  "$key\t$hash_data->{$key}\n";
   }
   print "\n\n";
   #exit(1);
}


1;




