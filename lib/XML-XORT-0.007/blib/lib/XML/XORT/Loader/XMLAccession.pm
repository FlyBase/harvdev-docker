=head1 NAME

         XML::XORT::Loader::XMLAccession - module to handle global accession, which is helper of Loader module.

=head1 SYNOPSIS

         my $accession_obj=XML::XORT::Loader::XMLAccession->new(-dbname=>'chado',
                                                               -accession_file=>'config_accession.xml',
                                                               -debug=>$DEBUG);
         my $accession_id=$accession_obj->parse_accession($table_name, $accession, $op);

=head1 DESCRIPTION

        This is the helper module which help Loader module to deal with global id retrive

=cut

=head1 CONTACT

        Pinglei Zhou, FlyBase fellow at Harvard University (zhou@morgan.harvard.edu)

=cut

=head1 METHODS

=cut

package XML::XORT::Loader::XMLAccession;
use XML::Parser::PerlSAX;
use XML::XORT::Util::DbUtil::DB;
use XML::DOM;
use XML::XORT::Dumper::DumperSpec;
use XML::XORT::Util::DbUtil::DB;
use XML::XORT::Util::GeneralUtil::Properties;
use XML::XORT::Util::GeneralUtil::Constants;
use XML::XORT::Loader::XMLParser;

use strict;
my %hash_ddl;
my $property_file;
my $dbh;
my $parser = new XML::DOM::Parser;

my $OP_FORCE='force';
my $OP_UPDATE='update';
my $OP_INSERT='insert';
my $OP_DELETE='delete';
my $OP_LOOKUP='lookup';
my $OP="op";

my $pattern;
my $i;
my $j;
my $k;
my $op;
my $TABLE="table";
my $PATTERN="pattern";
my $PATH="path";
my $GLOBAL_ID="global_id";
my $RANK="rank";
my @save;
my $dumpspec_obj;

my $node_path;
my $node_table;
my $config_acc_temp;
my $config_acc;
my $acc;
my $DEBUG=1;

#retrieve some constants
my $constant_obj=XML::XORT::Util::GeneralUtil::Constants->new();
my $conf= $constant_obj->get_constant('CONF');
my $tmp= $constant_obj->get_constant('TMP');

my $DDL_FILE='ddl';

 sub new (){
   my $type=shift;
   my $self={};
   $self->{'db'}=shift;
   $self->{'file'}=shift;
   $config_acc=$self->{'file'};
   $DEBUG=shift;
   my $ddl_file=shift;
   if (defined $ddl_file && $ddl_file =~/\w+/ && $ddl_file ne $DDL_FILE && !(-e $ddl_file)){
      warn "\nthe ddl file you provide does not exist:\n$ddl_file" and die ();
   }
   elsif (defined $ddl_file && $ddl_file =~/\w+/ && ($ddl_file eq $DDL_FILE || -e  $ddl_file)){
      $DDL_FILE=$ddl_file ;
   }
   $property_file=$self->{'db'};
   my $dbh_pro=XML::XORT::Util::GeneralUtil::Properties->new($property_file);
   my    %dbh_hash=$dbh_pro->get_dbh_hash();
         $dbh_hash{'ddl_property'}=$DDL_FILE;
   $dbh=XML::XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
   $dbh->open();
   my $ddl_pro=XML::XORT::Util::GeneralUtil::Properties->new($DDL_FILE);
   %hash_ddl=$ddl_pro->get_properties_hash();

   $dumpspec_obj=XML::XORT::Dumper::DumperSpec->new(-dbh=>$dbh,-hash_ddl=>\%hash_ddl);
   bless $self, $type;
   return $self;
 }


=head2 parse_accession

  Arg [1]    : table name
  Arg [2]    : accession
  Arg [3]    : operation type
  Example    : $obj->parse_accesion('feature', 'CG1456','look_up')
               will try to look up feature_id with 'uniquename=CG1456'
  Description: This method help to retrive the primary table id value from database based on the accession
               accesion is some value UNIQUELY represent a record in the database, e.g. CGnnnnn as uniquename in feature table, FBgn as accession in dbxref table
               for same table, there maybe more than one value to represent same record, e.g pub table: uniquename:type_id or miniref
  Returntype : primary key value or null if no
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : 

=cut

 sub parse_accession (){
    my $self=shift;
    my $table_input=shift;
    $acc=shift;
    my $op=shift;
    $op=$OP_LOOKUP if !(defined $op);
    my $table;
my $global_id;
my @array_op;
    if ($op eq $OP_FORCE ){
         @array_op=($OP_LOOKUP, $OP_INSERT);
    }
    else {
         @array_op=($op);
    }

 print "\nmax rank for table:$table_input is:", &_get_max_rank($table_input);
 for $i(0..&_get_max_rank($table_input)){
   &_pattern_match($table_input, $i);
   for my $j (0..$#array_op){
      $op=$array_op[$j];
      $node_table=&_get_rank_node($table_input, $i, $op);
      print "\nnode_name:",$node_table->getNodeName() if (defined $node_table);
      if (defined $node_table){
          my $op_config=$node_table->getAttribute($OP);
          print "\nop_config:$op_config:" if ($DEBUG==1);
          print "\nnode for table:$table_input, rank:$i:\n\n", $node_table->toString() if ($DEBUG==1);
          my $query=$dumpspec_obj->format_sql_id($node_table);
          print "\nquery to retrieve record for global id:\n$query\n" if ($DEBUG==1);
          my $ref_array=$dbh->get_all_arrayref($query);
          print "\nnumber of return record for this reference:",$#{$ref_array} if ($DEBUG==1);
          if ($#{$ref_array} <0 && ($op eq $OP_FORCE || $op eq $OP_INSERT) && ($op_config eq $OP_FORCE || $op_config eq $OP_INSERT)){
             my $node_string="<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE chado SYSTEM \"/users/zhou/work/flybase/xml/chado_stan.dtd\">\n<chado>\n".$node_table->toString()."\n</chado>";
             print "\n\nto_string:\n", $node_string;
             #print "\n\nquery:\n$query";
             my $file_write=">".$tmp."/config_accession_temp.xml";
             my $file_read=$tmp."/config_accession_temp.xml";
             open (OUT1, $file_write) or die "unable to open file";
             print OUT1 $node_string;
             close(OUT1);
             print "\nstart to load the temp_chadoxml....."  if ($DEBUG==1);
             my $parse_obj=XML::XORT::Loader::XMLParser->new($self->{'db'}, $file_read) if ($DEBUG==1);
             $parse_obj->load(-is_recovery=>'0');
             $global_id=$dbh->get_one_value($query);

             last;
	  }
          elsif ($#{$ref_array} ==0){
             $global_id=$ref_array->[0][0];
             print "\ngolbal_id:$global_id\nquery:\n$query" if ($DEBUG==1);
             last;
          }
 	  elsif ($#{$ref_array} >0){
             print "for query:$query,\nthere are more than ONE record for this global accession, you need to narrow it to one";
             undef $global_id;
	  }
	}

         return $global_id if defined $global_id;
       }

    }


  $dbh->close();
  $dumpspec_obj->close();
  print "\nfinished the XMLAccession" if ($DEBUG==1);

  return $global_id;
 #return;

 }

=head2 _get_max_rank

  Arg [1]    : table name

  Example    :
  Description: private method to get max number of rank for this table in config_accession.xml file

  Returntype : int, max rank  or null if no
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : 

=cut

 sub _get_max_rank(){
   my $table_input=shift;
   my $rank=0;
   my $rank_temp=0;
   my $table;
   my $node_path;

   my  $doc = $parser->parsefile ($config_acc);
   my  $root=$doc->getDocumentElement();
   my  $nodes=$root->getElementsByTagName($GLOBAL_ID);
   for  $i(1..$nodes->getLength()){
         my $node=$nodes->item($i-1);
        my $nodes1=$node->getChildNodes();
	 for $j(1..$nodes1->getLength()){
            my $node1=$nodes1->item($j-1);
            if ($node1->getNodeType ==ELEMENT_NODE){
               $table=($node1->getFirstChild)->getData() if ($node1->getNodeName() eq $TABLE);
               $rank_temp=($node1->getFirstChild)->getData() if ($node1->getNodeName() eq $RANK);
	    }
	 }

	 if ($table eq $table_input){
             $rank=$rank_temp if ($rank_temp>$rank);
	  }
    }

    return $rank;
 }

=head2 _pattern_match

  Arg [1]    : table name
  Arg [2]    : rank
  Example    :
  Description: private method, for different table, different rank,pattern_match the global_id and create a temp config_accession.xml

  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : 

=cut

 sub _pattern_match(){
    my $table_input=shift;
    my $rank_input=shift;
    my ($table, $rank);

    # split the accesion based on the pattern, then create a temp config_accession.xml file
    my @temp=split(/\//, $config_acc);
    $config_acc_temp=$tmp."/config_accession.xml";
    open (IN, $config_acc) or die "unable to open $config_acc";
    my $config_acc_temp1=">".$config_acc_temp;
    open (OUT,$config_acc_temp1) or die "unable to open file";
      my $parser = new XML::DOM::Parser;
      my  $doc = $parser->parsefile ($config_acc);
      my  $root=$doc->getDocumentElement();

      #my $nodes=$root->getChildNodes();
      my $nodes=$doc->getElementsByTagName($GLOBAL_ID);
      for  $i(1..$nodes->getLength()){
         my $node_temp=$nodes->item($i-1);
         #get all pattern and table node
         my $nodes_1=$node_temp->getChildNodes() if ($node_temp->getNodeType()==ELEMENT_NODE);
             undef $pattern;
             undef $table;
         for my $j(1..$nodes_1->getLength()){
             my $node=$nodes_1->item($j-1);
             my $node_type=$node->getNodeType();
             my $node_name=$node->getNodeName();
             #print "\nnode_type:$node_type:node_name:$node_name" if ($node->getNodeType()==ELEMENT_NODE);
             # here come to child of GLOBAL_ID, e.g pattern, rank, path, table ...
             if ($node->getNodeType()==ELEMENT_NODE) {
	       if ($node->getNodeName() eq $PATTERN){
                 undef @save;
                 $pattern=($node->getFirstChild())->getData();
                 print "\npattern:$pattern" if ($DEBUG==1);
                 print "\nbefore match:$acc:";
                 $acc=~ /$pattern/;
                 print "\n1:$1:\t2:$2:\t3:$3:\t4:$4:\tacc:$acc:" if ($DEBUG==1);
                    push @save, "aaaa";
                    push @save, $1;
                    push @save, $2;
                    push @save, $3;
	       }
	       if ($node->getNodeName() eq $TABLE){
                  $table=($node->getFirstChild())->getData();
                  print "\ntable:$table" if ($DEBUG==1);
	        }
               if ($node->getNodeName() eq $PATH){
                  print "\npath node:", $node->getNodeName(), "\n" if ($DEBUG==1);
	       }
               if ($node->getNodeName() eq $RANK){
                  $rank=($node->getFirstChild())->getData();
                  print "\npath node:", $node->getNodeName(), "\n" if ($DEBUG==1);
	       }
	     }
	 }
         if ($table eq $table_input && $rank eq $rank_input){
            while (<IN>){
                my $value=$_;
                 for my $i(1..$#save ){
                     $value=~ s/\$$i/$save[$i]/;
                 }
                   print OUT $value;
             }
            last;
	 }
       }
     close(OUT);


 }

=head2 _get_rank_node

  Arg [1]    : table name
  Arg [2]    : rank
  Example    :
  Description: private method, return the DOM tree node represent the tree of specific rank of specif operation

  Returntype : node reference or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : 

=cut

 sub _get_rank_node(){
   my $table_input=shift;
   my $rank_input=shift;
   my $op=shift;
   my $rank;
   my $table;
   my $node_table;

   # in _pattern_match, if no path for this specific rank, then config_acc_temp will be empty
   return if ( -z $config_acc_temp);
   my $doc = $parser->parsefile ($config_acc_temp);
   my $root=$doc->getDocumentElement();
   my $nodes=$root->getElementsByTagName($GLOBAL_ID);
   for my $i(1..$nodes->getLength()){
         my $node=$nodes->item($i-1);
        my $nodes1=$node->getChildNodes();
	 for $j(1..$nodes1->getLength()){
            my $node1=$nodes1->item($j-1);
            if ($node1->getNodeType ==ELEMENT_NODE){
               $table=($node1->getFirstChild)->getData() if ($node1->getNodeName() eq $TABLE);
               $rank=($node1->getFirstChild)->getData() if ($node1->getNodeName() eq $RANK);
               $node_path=$node1 if ($node1->getNodeName() eq $PATH);
	    }
	 }
         print "\ntable:$table:input_table:$table_input:node_path:rank:$rank", $node_path->getNodeName() if ($DEBUG==1);
	 if ($table eq $table_input && $rank_input eq $rank){
            my $nodes2=$node_path->getChildNodes();
            for my  $j(1..$nodes2->getLength()){
                $node_table=$nodes2->item($j-1);
               if ($node_table->getNodeType()==ELEMENT_NODE){
		 if ($node_table->getNodeName() eq $table_input){
                     my $op_config=$node_table->getAttribute($OP);
                     print "\nop:$op, op_config:$op_config:node_name:",$node_table->getNodeName() if ($DEBUG==1);
                     if ($op eq $op_config){
                       # last;
                       return $node_table;
		 }
	       }
	    }
            undef $node_table;
         }
        }
       }
   return $node_table;
 }

1;
