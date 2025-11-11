=head1 NAME

         XML::XORT::Dumper::DumperSpec - module to handle DumperSpec, which is helper of DumperXML module.

=head1 SYNOPSIS

         my $dumpspec_obj=XML::XORT::Dumper::DumperSpec->new(-dbname=>'chado');
         $dumpspec_obj->format_sql(-node=>$node_ref);

=head1 DESCRIPTION

        This is the basic module which help DumperXML module to deal with dumpspec

=cut

=head1 CONTACT

        Pinglei Zhou, FlyBase fellow at Harvard University (zhou@morgan.harvard.edu)

=cut

=head1 METHODS

=cut


package XML::XORT::Dumper::DumperSpec;
 use XML::XORT::Util::DbUtil::DB;
 use XML::XORT::Util::GeneralUtil::Properties;
 use XML::DOM;
 use XML::XORT::Util::GeneralUtil::Constants;
 use strict;
#use XML::XQL::DOM;
#use XML::XQL::Strict;
#use XML::XQL;
#use Cache::MemoryCache;
#load the ddl information
my %hash_ddl;
#my $pro=XML::XORT::Util::GeneralUtil::Properties->new('ddl');
# %hash_ddl=$pro->get_properties_hash();
my $dbh_obj;

my $TABLES_PSEUDO='table_pseudo';
my %hash_tables_pseudo;
#my $cache_node_name=new Cache::MemoryCache;
#my $cache_dump_test_type=new Cache::MemoryCache;
#my $cache_attribute=new Cache::MemoryCache;
my %cache_node_name;
my %cache_dump_test_type;
my %cache_attribute;

#global variable, attribute of test or dump
my $DUMP_ALL='all';
my $DUMP_COL='cols';
my $DUMP_SELECT='select';
my $DUMP_REF='ref';
my $DUMP_NO='no_dump';
my $DUMP_YES='yes_dump';

my $TEST_YES='yes';
my $TEST_NO='no';
my $TEST_ANY='any';
my $TEST_NONE='none';
my $TEST_GREATER_THAN='gt';
my $TEST_GREATER_EQUAL='ge';
my $TEST_LESS_THAN='lt';
my $TEST_LESS_EQUAL='le';
my $TEST_IN='in';
my $TEST_NOT_IN='nti';

my $TYPE_DUMP='dump';
my $TYPE_TEST='test';
my $ROOT_NODE='chado';

my $APP_DATA_NODE='_appdata';
my $SQL_NODE='_sql';
#new attribute to limit the numbers
my $ATTRIBUTE_LIMIT='limit';

my $DEBUG=0;
my $FN_ARG='fn_arg';
my %hash_op=(
    'gt'=>'>',
    'ge'=>'>=',
    'lt'=>'<',
    'le'=>'<=',
    'like'=>' like ',
     'nl'=>' not like ',
    'yes'=>'=',
    'no'=>'<>',
    'eq'=>'=',
    'ne'=>'<>',
    'in'=>' in ',
    'nti'=>' not in ',
    'ms'=>' ~ ',
    'mi'=>' ~* ',
    'ns'=>' !~ ',
    'ni'=>' !~* ',
);
#negation operation will be constructed differently from others for <or>
my %hash_op_negation=(
    'no'=>'<>',
    'ne'=>'<>',
    'nl'=>' not like ',
);

my $constant_obj=XML::XORT::Util::GeneralUtil::Constants->new();
my $conf= $constant_obj->get_constant('CONF');
my $tmp= $constant_obj->get_constant('TMP');




 sub new (){
  my $type=shift;
  my $self={};

#  my ($dbname,$ddl_file) =XML::XORT::Util::GeneralUtil::Structure::rearrange(['dbname','ddl_property'], @_);
#  $self->{'dbname'}=$dbname;
#  $self->{'ddl_property'}=$ddl_file;
#  my $dbh_pro=XML::XORT::Util::GeneralUtil::Properties->new($self->{'dbname'});
#  my    %dbh_hash=$dbh_pro->get_dbh_hash();
#  $dbh_hash{'ddl_property'}=$self->{'ddl_property'};
#  $dbh_obj=XML::XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
#  $dbh_obj->open();

#  my $pro=XML::XORT::Util::GeneralUtil::Properties->new($self->{'ddl_property'});
#  %hash_ddl=$pro->get_properties_hash();
my $hash_ddl_ref;my $node_root;
  ($dbh_obj, $hash_ddl_ref,$node_root)=XML::XORT::Util::GeneralUtil::Structure::rearrange(['dbh','hash_ddl','node'], @_);
  %hash_ddl=%$hash_ddl_ref;
   # load the elements which need to be filtered out
   my @array_pseudo=split(/\s+/, $hash_ddl{$TABLES_PSEUDO});
   foreach my $value(@array_pseudo){
   $hash_tables_pseudo{$value}=1;

   }
  &_cache_object($node_root);
  bless $self, $type;
  return $self;
 }


 sub get_table_sql(){
   my $node=shift;
 }



 sub get_subtable_sql(){
    my $node;
 }

 sub get_subtable_nodes(){
   my $node=shift;
   my $array_nodes_ref;
   return $array_nodes_ref;
 }


=head2 format_sql_id

  Arg [1]    : varchar node reference
  Example    :
  Description: public method to format the node into sql, it will use all the constraints that 
               explicit or implicit have test attribute
               identical with format_sql except that it will only select 'id' column
  Returntype : sql statement, which only select 'id'
  Exceptions : Thrown is invalid arguments are provided

=cut

 sub format_sql_id(){
    my $self=shift;
    my $node=shift;

    my %hash_tables;
    my %hash_where;
    my %hash_alias_no;
    my $node_name=$node->getNodeName();
    my $string_primary_key=$node_name."_primary_key";
    my $table_id=$hash_ddl{$string_primary_key};
    my $query;
 
    my $tables;
    my $where_list;
    my $what_list;
    my $limit_list;
    my $alias_table;
    #here start to figure out what to dump
    #first one always start with "table_0"
    my $alias=$node_name."_0";
   my $attribute_limit=$node->getAttribute($ATTRIBUTE_LIMIT);
   my $attribute_fn_arg=$node->getAttribute($FN_ARG);
   if (defined $attribute_fn_arg){
       $alias_table=$node_name.$attribute_fn_arg. " ".$alias;
   }
   else {
       $alias_table=$node_name." ".$alias;
   }


    #always add the table_alias string to has_tables before calling _format_sql
    $hash_tables{$alias_table}=1;
    $hash_alias_no{$node_name}=0;
    &_format_sql($node, \%hash_tables, \%hash_where, \%hash_alias_no);

    foreach my $key (keys %hash_tables){
      if (defined $tables){
        $tables=$tables." , ".$key;
      }
      else {
        $tables=$key;
      }
    }

    foreach my $key (keys %hash_where){
      if (defined $where_list){
         $where_list=$where_list. " and ".$key;
      }
      else {
         $where_list=$key;
      }
    }
    if (defined $attribute_limit && $attribute_limit =~/^\d+$/){
        $limit_list=" limit ".$attribute_limit;
    }

    # here add this new feature which can handle the _sql element on April 29,2003
    # this will over-rule all other constraints
    if (defined $hash_where{$SQL_NODE}){
      my $sql_stm=$hash_where{$SQL_NODE};

      my @array_select=split(/\s*select\s*/, $sql_stm);
      my @array_from=split(/\s*from\s*/, $array_select[1]);
      my $what=$array_from[0];
      #this is rest of $sql_id
      my $right_sql=" from ".$array_from[1];
      my @temp=split(/\s*\,\s*/, $what);

      my $alias;
      my $sql_id;
      #here to figure out the alias for table_id if there is any
      if ($what =~/\./){
         foreach my $col (@temp){
            ($alias, undef)=split(/\./, $col);
        }
      }
      if (defined $alias){
        $sql_id=("select $alias.$table_id $right_sql");
      }
      else {
        $sql_id=("select $table_id $right_sql");
      }
      return $sql_id;
    }

    $what_list=$alias.".".$table_id;

    if (defined $tables && defined $where_list && defined $hash_ddl{$node_name}){
      $query=("select $what_list from $tables where  $where_list");
      $query=$query.$limit_list if (defined $limit_list);
        return $query;
    }
    # no constraint for this table
    elsif( defined $hash_ddl{$node_name}) {
      $query=("select $what_list from $alias_table");
      $query=$query.$limit_list if (defined $limit_list);
        return $query;
    }

    return;
 }

=head2 format_sql

  Arg [1]    : varchar node reference
  Example    :
  Description: public method to format the node into sql, it will use all the constraints that 
               explicit or implicit have test attribute
  Returntype : sql statement
  Exceptions : Thrown is invalid arguments are provided

=cut

 sub format_sql(){
    my $self=shift;
    my $node=shift;

    my %hash_tables;
    my %hash_where;
    my %hash_alias_no;
    my $node_name=$node->getNodeName();
    my $string_primary_key=$node_name."_primary_key";
    my $table_id=$hash_ddl{$string_primary_key};

    my $query;


    my $tables;
    my $where_list;
    my $limit_list;
    my $what_list;
    #here start to figure out what to dump
    #first one always start with "table_0"
    my $alias=$node_name."_0";
   my $attribute_limit=$node->getAttribute($ATTRIBUTE_LIMIT);
   my $attribute_fn_arg=$node->getAttribute($FN_ARG);
   warn "\nattribute_fn_arg for node:$node_name:$attribute_fn_arg\n" if ($DEBUG==1);
   my $alias_table;
   if (defined $attribute_fn_arg){
       $alias_table=$node_name.$attribute_fn_arg. " ".$alias;
   }
   else {
       $alias_table=$node_name." ".$alias;
   }

    #always add the table_alias string to has_tables before calling _format_sql
    $hash_tables{$alias_table}=1;
    $hash_alias_no{$node_name}=0;
    &_format_sql($node, \%hash_tables, \%hash_where, \%hash_alias_no);
    foreach my $key (keys %hash_tables){
      if (defined $tables){
        $tables=$tables." , ".$key;
      }
      else {
        $tables=$key;
      }
    }

    # here add this new feature which can handle the _sql element on April 29,2003
    if (defined $hash_where{$SQL_NODE}){
      return $hash_where{$SQL_NODE};
    }


    foreach my $key (keys %hash_where){
      if (defined $where_list){
         $where_list=$where_list. " and ".$key;
      }
      else {
         $where_list=$key;
      }
    }
    if (defined $attribute_limit && $attribute_limit =~/^\d+$/){
        $limit_list=" limit ".$attribute_limit;
    }

    my $attribute_dump=$node->getAttribute("dump");
    my @array_table_cols;
    warn "\nattribute_dump:$attribute_dump:\n" if ($DEBUG==1);
    if (!(defined $attribute_dump) || $attribute_dump eq ''){
       $attribute_dump=$DUMP_ALL;
    }
    if ($attribute_dump eq $DUMP_ALL || $attribute_dump eq $DUMP_COL){
      @array_table_cols=split(/\s+/, $hash_ddl{$node_name});
    }
    elsif ($attribute_dump eq $DUMP_REF){
      my $table_unique=$node_name."_unique";
      @array_table_cols=split(/\s+/, $hash_ddl{$table_unique});
      #also need to add the primary key
      push @array_table_cols, $table_id;
    }
    elsif ($attribute_dump eq $DUMP_SELECT){
      my $nodes=$node->getChildNodes();
      my @temp_cols=split(/\s+/, $hash_ddl{$node_name});
      my %hash_cols;
      foreach (@temp_cols){
         $hash_cols{$_}=1;
      }
      for my $i (1..$nodes->getLength()){
         my $child_node=$nodes->item($i-1);
         my $child_node_name=$child_node->getNodeName();
         if ($child_node->getNodeType() eq ELEMENT_NODE && defined $hash_cols{$child_node_name}){
             my $attribute_dump=_get_attribute_value($child_node);
             warn "\nattribute_dump for ELEMENT:$child_node_name:$attribute_dump:"  if ($DEBUG==1);
             if ($attribute_dump eq $DUMP_SELECT){
               push @array_table_cols, $child_node_name;
	     }
	 }
      }
      #also need to add the primary key
      push @array_table_cols, $table_id;
    }

    for my $i(0..$#array_table_cols){
      if (defined $what_list){
         $what_list=$what_list." , ".$alias.".".$array_table_cols[$i];
      }
      else {
         $what_list=$alias.".".$array_table_cols[$i];
      }
    }

     # there is constraint for this table
    if (defined $tables && defined $where_list && defined $hash_ddl{$node_name}){
      $query=("select $what_list from $tables where  $where_list");
      warn "\n\n\nformat_sql:query:node_name:$node_name\n$query" if ($DEBUG==1);
      $query=$query.$limit_list if (defined $limit_list);
        return $query;
    }
    # no constraint for this table
    elsif( defined $hash_ddl{$node_name}) {
      $query=("select $what_list from $alias_table");
      $query=$query.$limit_list if (defined $limit_list);
      warn "\n\n\nformat_sql:query:node_name:$node_name\n$query" if ($DEBUG==1);
        return $query;
    }



    return;
 }


=head2 _format_sql

  Arg [1]    : varchar node reference
  Example    :
  Description: private method to format the node into sql, it will use all the constraints that 
               explicit or implicit have test attribute
  Returntype : sql statement
  Exceptions : Thrown is invalid arguments are provided

=cut
 sub _format_sql(){
   my $node=shift;
   my $hash_tables_ref=shift;
   my $hash_where_ref=shift;
   my $hash_alias_no_ref=shift;
   my $attribute_test=shift;

   my %hash_data_yes;
   my %hash_data_no;
   warn "\n\nnode:", $node->getNodeName(), "\n\n" if ($DEBUG==1);
   #&_traverse($node);
   #figure out attribute_test
   #my $type=&_get_node_type($node);
    my $type=$cache_dump_test_type{$node};
   if (defined $type && $type eq $TYPE_TEST){
     if (!(defined $attribute_test) || $attribute_test eq '' && ($node->getAttribute($TYPE_TEST) eq '')){
          $attribute_test=&_get_attribute_value($node);
     }
   }
   warn "\nattribute_test value in _format_sql:$attribute_test\ttype:$type" if ($DEBUG==1);

   #has_test to control whether there is any column constrait data 1:yes, 0:no, this could help to set join: if has column_constraint, then set join, i.e. feature_relationship.subjfeature_id=feature.feature_id
   my $has_test=0;
   my $has_link_test=0;

   if (defined $attribute_test){
      $has_test=1;
   }

   my $node_name=$node->getNodeName();
   my $nodes=$node->getChildNodes();
   my @array_cols;
   my %hash_cols;
   @array_cols=split(/\s+/, $hash_ddl{$node_name});
   for my $i(0..$#array_cols){
       $hash_cols{$array_cols[$i]}=1;
   }
   my $string_primary_key=$node_name."_primary_key";
   my $table_id=$hash_ddl{$string_primary_key};

   #node suppose to be table_node
   if (!(defined $hash_ddl{$node_name})) {
      warn "\n$node_name is not table node" if ($DEBUG==1);
      return;
   }
   else {
     warn "\nentrance node of _format_sql:", $node_name, "\tattribute_test:$attribute_test\n" if ($DEBUG==1);
   }

   #here to figure out the alias for table, it will store into %hash_tables, format: table_0, table_1..., increase number while nesting
   my $alias;
   my $alias_count=0;
   my $alias_table;
   foreach my $value(keys %$hash_tables_ref){
      my @array_alias=split(/\s/, $value);
      my $len_key=length $array_alias[1];
      my $len_node_name=length $node_name;
      if ($len_key >$len_node_name){
         my $remain=substr($array_alias[1], $len_node_name+1);
         warn "\nnode:$node_name:\texist key:$array_alias[1]:\tremain:$remain:$len_key:$len_node_name:" if ($DEBUG==1);
         if ($remain =~/^\d/ && $remain>$alias_count){
            $alias_count=$remain;
	 }
      }
   }

   $alias=$node_name."_".$alias_count;



   for my $i (1..$nodes->getLength()){
      my $child_node=$nodes->item($i-1);
      my $child_node_name=$child_node->getNodeName();
      my $attribute;
       #only need the column_element
      if ($child_node->getNodeType()==ELEMENT_NODE && !(defined $hash_ddl{$child_node_name}) && defined $hash_cols{$child_node_name}){
         warn "\ntable:$node_name\texist col:$child_node_name" if ($DEBUG==1);
         $attribute=$child_node->getAttribute($TYPE_TEST);
          warn "\n2.entrance node of _format_sql:", $node_name, "\tattribute_test:$attribute_test\tattribute:$attribute:\n" if ($DEBUG==1);
         if (!(defined $attribute) || $attribute eq '' ){
             $attribute=$attribute_test;
	 }

         if ((defined $attribute && $attribute ne '' ) || defined $attribute_test){
           #if no test attribute, default will be the same as parents
	  # if (!(defined $attribute)){
          #    $attribute=$attribute_test;
	  # }

            # here get all child_node of column_element node, could be:TEXT, FOREIGN_KEY, OR node  
	   my %hash_or;
            my $nodes_1=$child_node->getChildNodes();
            for my $i (1..$nodes_1->getLength()){
              my $child_node_1=$nodes_1->item($i-1);
              my $child_node_name_1=$child_node_1->getNodeName();
              #text data
              if ($child_node_1->getNodeType ==TEXT_NODE){
                   my $text=$child_node_1->getData();
                   if (defined $text && $text ne '' && $text =~/\w/ && $text ne "\t" && $text ne "\n"){
                     $text=&_format_data($node_name, $child_node_name, $text) if ($attribute ne $TEST_IN && $attribute ne $TEST_NOT_IN);

                     if (defined $hash_op{$attribute}){
                         my $stm=$alias.".".$child_node_name.$hash_op{$attribute}.$text;
                         $hash_where_ref->{$stm}=1;
                        # $hash_tables_ref->{$alias_table}=1;
                         $has_test=1;
		     }

		   }
	      }
              #foreign key referencing object, i.e cvterm of feature..type_id..cvterm
              elsif ($child_node_1->getNodeType ==ELEMENT_NODE && defined $hash_ddl{$child_node_name_1}){
                   # my $alias_count_sub=&_get_max_alias_no($hash_tables_ref, $child_node_name_1);

                   my    $alias_count_sub;
                   if (defined  $hash_alias_no_ref->{$child_node_name_1}){
                      $alias_count_sub=$hash_alias_no_ref->{$child_node_name_1}+1;
		   }
                    else {
                      $alias_count_sub=0;
                    }
                    $hash_alias_no_ref->{$child_node_name_1}=$alias_count_sub;

                    my $alias_table_sub=$child_node_name_1." ".$child_node_name_1."_".$alias_count_sub;
                       $hash_tables_ref->{$alias_table_sub}=1;
                    my $alias_sub=&_format_sql($child_node_1, $hash_tables_ref, $hash_where_ref, $hash_alias_no_ref, $attribute);

                    if (defined $alias_sub){
                       my $string_primary_key=$child_node_name_1."_primary_key";
                       my $table_id_sub=$hash_ddl{$string_primary_key};
                       my $temp_sub;
                       if (defined $hash_op{$attribute}){
                        $temp_sub=$alias.".".$child_node_name.$hash_op{$attribute}.$alias_sub.".".$table_id_sub;
                        $hash_where_ref->{$temp_sub}=1;
                        #$hash_tables_ref->{$alias_table}=1;
                        $hash_tables_ref->{$alias_table_sub}=1;
		       }
		    }
	      }
              #<or></or> depend on the test value 'yes' or 'no', it will have different join set
              elsif ($child_node_1->getNodeType ==ELEMENT_NODE && $child_node_name_1 eq 'or'){  
		my $or_value;
		$or_value=$child_node_1->getFirstChild()->getData();
		$or_value=&_format_data($node_name, $child_node_name, $or_value) if ($attribute ne $TEST_IN && $attribute ne $TEST_NOT_IN);
		warn "\nor value:$or_value" if ($DEBUG==1);
		$hash_or{$or_value}=1; 
	       }
	    }
   my $stm;
                  if (defined $hash_op{$attribute}){
                    #treat differently for negation
                   if (defined $hash_op_negation{$attribute}){
		    foreach my $key (keys %hash_or){
		      if (defined $stm){
                         $stm=$stm." and ".$alias.".".$child_node_name.$hash_op{$attribute}.$key;
		      }
                      else {
                         $stm=$alias.".".$child_node_name.$hash_op{$attribute}.$key;
                      }
                    }
                   }
                   else {
		    foreach my $key (keys %hash_or){
		      if (defined $stm){
                         $stm=$stm." or ".$alias.".".$child_node_name.$hash_op{$attribute}.$key;
		      }
                      else {
                         $stm=$alias.".".$child_node_name.$hash_op{$attribute}.$key;
                      }
                    }
                   }

                  }

                  if (defined $stm){
                      $stm="(".$stm.")";
                      $hash_where_ref->{$stm}=1;
                      #$hash_tables_ref->{$alias_table}=1;
                      $has_test=1;
		    }
	  }
       }  # end of for col element
      # here add this to handle the _sql 
      elsif ($child_node_name eq $SQL_NODE){
            my $sql_stm=$child_node->getFirstChild->getData();
             #&_validate_sql_element($sql_stm, $child_node);
             $hash_where_ref->{$SQL_NODE}=$sql_stm;
             $has_test=1;
      }
      #link table, then first output the 
      elsif (defined $hash_ddl{$child_node_name} && !(defined $hash_cols{$child_node_name})){
         warn "\nstart to deal with link table ....:$child_node_name" if ($DEBUG==1);
         my $attribute_test_link=$child_node->getAttribute('test');
         my $attribute_fn_arg_link=$child_node->getAttribute($FN_ARG);
         #only those with 'test' will be considered
         if (($attribute_test_link ne '' && defined $attribute_test_link) || defined $attribute_test){
	     if (!(defined $attribute_test_link) || $attribute_test_link eq ''){
               $attribute_test_link=$attribute_test;
	     }
             warn "\nattribute_test_link:$attribute_test_link" if ($DEBUG==1);
             my %hash_tables_link;
             my %hash_where_link;
             my $node_name=$node->getNodeName();

             my $join_key=&_get_join_foreign_key($child_node);
             warn "\njoin_key:$join_key" if ($DEBUG==1);
             warn "\ntable:$child_node_name has MORE than ONE forein keys refering to parent table:$node_name without explicit constraint:\n$join_key\n" and exit(1) if ($join_key =~/\:/);
             my $join_string;
             my $alias_no_link;

             if (defined $hash_alias_no_ref->{$child_node_name}){
                  $alias_no_link=$hash_alias_no_ref->{$child_node_name}+1;
	     }
             else {
                  $alias_no_link=0;
             }
             $hash_alias_no_ref->{$child_node_name}=$alias_no_link;
             my $link_alias=$child_node_name."_".$alias_no_link;
;
             my $link_alias_table;
             if (defined $attribute_fn_arg_link){
                  $link_alias_table=$child_node_name.$attribute_fn_arg_link." ".$link_alias;
	      }
             else {
                  $link_alias_table=$child_node_name." ".$link_alias;
             }


               $join_string=$alias.".".$table_id."=".$link_alias.".".$join_key;
               $hash_where_link{$join_string}=1;
               $hash_tables_link{$link_alias_table}=1;
              warn "\njoin_string in link:$join_string\nlink_alias_table:$link_alias_table" if ($DEBUG==1);
              &_format_sql($child_node, \%hash_tables_link, \%hash_where_link,$hash_alias_no_ref, $attribute_test_link);


     
            my $query_link;
            my $tables_list_link;
            my $where_list_link;
            foreach my $key (keys %hash_tables_link){
              if (defined $tables_list_link){
                $tables_list_link=$tables_list_link." , ".$key;
              }
              else {
                $tables_list_link=$key;
              }
            }
            warn "\ntables_link:$tables_list_link" if ($DEBUG==1);

            foreach my $key (keys %hash_where_link){
             if (defined $where_list_link){
               $where_list_link=$where_list_link. " and ".$key;
             }
             else {
               $where_list_link=$key;
             }
           }
           if (defined $tables_list_link && defined $where_list_link){
             $query_link=("select * from $tables_list_link where  $where_list_link");
             warn "\nquery_link:$query_link" if ($DEBUG==1);
             if ($attribute_test_link eq 'yes'){
               $query_link="exists (".$query_link.")";
	     }
             elsif ($attribute_test_link eq 'no'){
               $query_link="not exists (".$query_link.")";
	    }
            warn "\n\nquery_link:$query_link" if ($DEBUG==1);
            $hash_where_ref->{$query_link}=1;
            $has_link_test=1;
           }
	}
      } # end of link table
   }

   if ($has_test ==1 || $has_link_test ==1){
     #$hash_tables_ref->{$alias_table}=1;
     warn "\n$alias\n\n" if($DEBUG==1);
     return $alias;
   }

   else {
      return;
   }

 }


=head2 _get_max_alias_no

  Arg [1]    : varchar node reference
  Example    :
  Description: private method to the max alias number
               since it will alias table in the format of table_name_#, the same table, 
               it will use same alias format except increase the #
  Returntype : int, max_alias no.
  Exceptions : Thrown is invalid arguments are provided

=cut
 sub _get_max_alias_no(){
    my $hash_tables_ref=shift;
    my $table=shift;
    my $alias_no=0;

   foreach my $value(keys %$hash_tables_ref){
      my @array_alias=split(/\s/, $value);
      my $len_key=length $array_alias[1];
      my $len_table=length $table;
      if ($len_key >$len_table){
         my $remain=substr($array_alias[1], $len_table+1);
         if ($remain =~/^\d/ && $remain>$alias_no){
            $alias_no=$remain;
	 }
      }
   }

   return $alias_no;
 }

=head2 format_query

  Arg [1]    : varchar node reference
  Example    : 
  Description: public method to format dump spec into query via subquery mechanism,
               select * from feature where tye_id in (select cvterm_id from cvterm where termname='gene')
  Returntype : sql statement.
  Exceptions : Thrown is invalid arguments are provided

=cut

 sub format_query(){
    my $self=shift;
    my $node=shift;
    return &_format_query($node);
 }

=head2 _format_query

  Arg [1]    : varchar node reference
  Example    :
  Description: private method for get_id to recursively get the table_id
  Returntype : int, sql statement.
  Exceptions : Thrown is invalid arguments are provided

=cut

 sub _format_query(){
   my $node=shift;

   my %hash_data_yes;
   my %hash_data_no;
   warn "\n\nnode:", $node->getNodeName();

   my $node_name=$node->getNodeName();
   my $nodes=$node->getChildNodes();
   my @array_cols;
   my %hash_cols;
   @array_cols=split(/\s+/, $hash_ddl{$node_name});
   for my $i(0..$#array_cols){
       $hash_cols{$array_cols[$i]}=1;
   }
   for my $i (1..$nodes->getLength()){
      my $child_node=$nodes->item($i-1);
      my $child_node_name=$child_node->getNodeName();
       #only need the column_element
      if ($child_node->getNodeType()==ELEMENT_NODE && !(defined $hash_ddl{$child_node_name}) && defined $hash_cols{$child_node_name}){
         my $attribute=$child_node->getAttribute('test');
         if ($attribute ne '' & defined $attribute){
            my $nodes_1=$child_node->getChildNodes();
            for my $i (1..$nodes_1->getLength()){
              my $child_node_1=$nodes_1->item($i-1);
              my $child_node_name_1=$child_node_1->getNodeName();
              #text data
              if ($child_node_1->getNodeType ==TEXT_NODE){
                   my $text=$child_node_1->getData();
                   if (defined $text && $text ne '' && $text =~/\w/ && $text ne "\t" && $text ne "\n"){
                        $hash_data_yes{$child_node_name}=$text;
		   }
	      }
              #foreign key referencing object
              elsif ($child_node_1->getNodeType ==ELEMENT_NODE && defined $hash_ddl{$child_node_name_1}){
                    my $temp_value=&_format_query($child_node_1);
                    if (defined $temp_value){
                        $hash_data_yes{$child_node_name}=$temp_value;
		    }
	      }
              #<or></or>
              elsif ($child_node_1->getNodeType ==ELEMENT_NODE && $child_node_name_1 eq 'or'){
                  my $or_nodes=$child_node->getElementsByTagName('or');
                  my %hash_or;
                  my $or_value;
                  for my $j (1..$or_nodes->getLength()){
                        my $temp_value=$or_nodes->item($j-1)->getFirstChild()->getData();
                        if ($or_value){
                            $or_value=$or_value."\|".$temp_value;
			}
                        else {
                           $or_value=$temp_value;
                        }
		  }
                  $hash_data_yes{$child_node_name}=$or_value;
	      }
	    }
	 }
     }
   }

   my $table_id_string=$node_name."_primary_key";
   my $table_id=$hash_ddl{$table_id_string};
   #my $table_id=$node_name."_id";

   my $hash_ref=&_data_type_checker(\%hash_data_yes, $node_name);
   my $stm_select;
   my $where_list;
   foreach my $key(keys %$hash_ref){
     warn "\nvalue:$hash_ref->{$key}" if ($DEBUG==1);
     my @array_value=split(/\|/, $hash_ref->{$key});
     my $value;
     for my $i(0..$#array_value){
       if (defined $value && $i<500){
          $value=$value." , ".$array_value[$i];
       }
       elsif($i <500) {
          $value=$array_value[$i];
       }

     }

     if (defined $where_list){
        $where_list=$where_list."  and ". $key." in (". $value.")";
     }
     else {
        $where_list=$key." in (".$value.")";
     }
   }
  $stm_select="select $table_id from $node_name where $where_list";
  warn "\nformat_query stm_select:$stm_select" if ($DEBUG==1);

  return $stm_select;

 }




=head2 get_id

  Arg [1]    : varchar node reference
  Example    :
  Description: public method to retrive the id for a table_node, which set constraint by dumpspec node
  Returntype : int, sql statement.
  Exceptions : Thrown is invalid arguments are provided

=cut

 sub get_id(){
   my $self=shift;
   my $node=shift;
   return &_get_id($node);

 }

=head2 _get_id

  Arg [1]    : varchar node reference
  Example    :
  Description: private method to retrive the id for a table_node, which set constraint by dumpspec node
  Returntype : int, sql statement.
  Exceptions : Thrown is invalid arguments are provided

=cut

 sub _get_id(){
   my $node=shift;

   my %hash_data_yes;
   my %hash_data_no;
   warn "\n\nnode:", $node->getNodeName();

   my $node_name=$node->getNodeName();
   my $nodes=$node->getChildNodes();
   my @array_cols;
   my %hash_cols;
   @array_cols=split(/\s+/, $hash_ddl{$node_name});
   for my $i(0..$#array_cols){
       $hash_cols{$array_cols[$i]}=1;
   }
   for my $i (1..$nodes->getLength()){
      my $child_node=$nodes->item($i-1);
      my $child_node_name=$child_node->getNodeName();
       #only need the column_element
      if ($child_node->getNodeType()==ELEMENT_NODE && !(defined $hash_ddl{$child_node_name}) && defined $hash_cols{$child_node_name}){
         my $attribute=$child_node->getAttribute('test');
         if ($attribute ne '' & defined $attribute){
            my $nodes_1=$child_node->getChildNodes();
            for my $i (1..$nodes_1->getLength()){
              my $child_node_1=$nodes_1->item($i-1);
              my $child_node_name_1=$child_node_1->getNodeName();
              #text data
              if ($child_node_1->getNodeType ==TEXT_NODE){
                   my $text=$child_node_1->getData();
                   if (defined $text && $text ne '' && $text =~/\w/ && $text ne "\t" && $text ne "\n"){
                        $hash_data_yes{$child_node_name}=$text;
		   }
	      }
              #foreign key referencing object
              elsif ($child_node_1->getNodeType ==ELEMENT_NODE && defined $hash_ddl{$child_node_name_1}){
                    my $temp_value=&_get_id($child_node_1);
                    if (defined $temp_value){
                        $hash_data_yes{$child_node_name}=$temp_value;
		    }
	      }
              #<or></or>
              elsif ($child_node_1->getNodeType ==ELEMENT_NODE && $child_node_name_1 eq 'or'){
                  my $or_nodes=$child_node->getElementsByTagName('or');
                  my %hash_or;
                  my $or_value;
                  for my $j (1..$or_nodes->getLength()){
                        my $temp_value=$or_nodes->item($j-1)->getFirstChild()->getData();
                        if ($or_value){
                            $or_value=$or_value."\|".$temp_value;
			}
                        else {
                           $or_value=$temp_value;
                        }
		  }
                  $hash_data_yes{$child_node_name}=$or_value;
	      }
	    }
	 }
     }
   }

   #my $table_id=$node_name."_id";
   my $table_id_string=$node_name."_primary_key";
   my $table_id=$hash_ddl{$table_id_string};

   my $hash_ref=&_data_type_checker(\%hash_data_yes, $node_name);
   my $stm_select;
   my $where_list;
   foreach my $key(keys %$hash_ref){
     warn "\nvalue:$hash_ref->{$key}" if ($DEBUG==1);
     my @array_value=split(/\|/, $hash_ref->{$key});
     my $value;
     for my $i(0..$#array_value){
       if (defined $value && $i<500){
          $value=$value." , ".$array_value[$i];
       }
       elsif($i <500) {
          $value=$array_value[$i];
       }

     }

     if (defined $where_list){
        $where_list=$where_list."  and ". $key." in (". $value.")";
     }
     else {
        $where_list=$key." in (".$value.")";
     }
   }
  $stm_select="select $table_id from $node_name where $where_list";
  warn "\nget_id stm_select:$stm_select" if ($DEBUG==1);

 # return $dbh_obj->get_one_value($stm_select);
    my $ref = $dbh_obj->get_all_arrayref($stm_select); 
    my $result;
      for my $i ( 0 .. $#{$ref} ) { 
         # for $j ( 0 .. $#{$ref->[$i]} ) { 
         # } 
          if (defined $result){
             $result=$result."\|".$ref->[$i][0];
	  }
          else {
            $result=$ref->[$i][0];
          }
      }
    return $result;
 }


#return: table/column/no
 sub node_spec_type(){
 }

#link table: parent is table_node and self if table_node, and self has foreign key refer to parent table_node
#return 1 if yes, 0 otherwise
 sub is_link_table(){
 }

=head2 get_join_foreigh_key

  Arg [1]    : link_table node reference
  Example    :
  Description: if want to dump link table, figure out  which is used to join with main table 
                i.e. feature_relationship.subjfeature_id or feature_relationship.objfeature_id
  Returntype : column key or null if no
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut


 sub get_join_foreign_key () {
   my $self=shift;
   my $node=shift;

   my $is_link_table=0;
   if (!(defined $node)){
     warn "\nnode not defined";
     return;
   }
   my $result;
  # my $link_table_node_type=&_get_node_type($node);
    my $link_table_node_type=$cache_dump_test_type{$node};
   # first test if it is link_table, then get the foreign key
   if (defined $node && $node->getNodeType() == ELEMENT_NODE){
     my $parent_node=$node->getParentNode();
     my $node_name=$node->getNodeName();
     my $first_child_node;
     if (defined $parent_node){
       my $parent_node_name=$parent_node->getNodeName();
       my $table_module=$parent_node_name."_module";
       my @array_link_table=split(/\s+/, $hash_ddl{$table_module});
       my %hash_foreign_key;
       if (defined $hash_ddl{$node_name} && defined $hash_ddl{$parent_node_name}){
         for my $i(0..$#array_link_table){
                my ($table, $foreign_key)=split(/\:/, $array_link_table[$i]);
               if (defined $table && $table eq $node_name){
                   $hash_foreign_key{$foreign_key}=1;
                   $is_link_table=1;
	       }
          }
       }
       else {
               warn "\nnot link table " ;
               return ;
       }
       $first_child_node=$node->getFirstChild();
       if (defined $first_child_node) {
         my $first_child_node_name=$first_child_node->getNodeName();
            if ($is_link_table ==1){
                my $nodes=$node->getChildNodes();
                for my $i(1..$nodes->getLength()){
                    my $child_node=$nodes->item($i-1);

                    if ($child_node->getNodeType() ==ELEMENT_NODE ){
                       my $child_node_name=$child_node->getNodeName();
                       #remove those appear as test constraint
                       #my $child_node_type=&_get_node_type($child_node);
                        my $child_node_type=$cache_dump_test_type{$child_node};
                       if ( $link_table_node_type eq $child_node_type){
                            if (defined $hash_foreign_key{$child_node_name}){
                                  delete $hash_foreign_key{$child_node_name};
                            }
			  }
		    }
		}
                # if there are more than one join key, i.e feature_relationship, if no constraint at all, then it will have objefeature_id and subjfeature_id
	        foreach my $key(keys %hash_foreign_key){
		  if (defined $result){
                      $result=$result.":".$key;
		    }
                   else {
                      $result=$key;
                   }
	        }
                warn "\njoin foreign key:$result for table:", $node->getNodeName() if ($DEBUG==1);
                return $result;
	    }
	}
      #not feature_relationship table, but other link table, then all foreign key will become join key
      else {
	if ($is_link_table==1){
	  foreach my $key (keys %hash_foreign_key){
	    if (defined $result){
                $result=$result.":".$key;
	      }
             else {
                $result=$key;
             }
             warn "\nin get join key:$key" if ($DEBUG==1);
	  }
          return $result;
        }
      }
     }
     else {
        warn "\nparent node is not defined" if ($DEBUG==1);
        return;
     }
   }
   else {
     warn "\nnode not defined or is not ELEMENT_NODE" if ($DEBUG==1);
     return ;
   }
 }


=head2 _get_join_foreigh_key

  Arg [1]    : link_table node reference
  Example    :
  Description: private method, if want to dump link table, figure out  which is used to join with main table 
                i.e. feature_relationship.subjfeature_id or feature_relationship.objfeature_id
  Returntype : column key or null if no
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut

 sub _get_join_foreign_key () {
   my $node=shift;

   my $is_link_table=0;

   if (!(defined $node)){
     warn "\nnode not defined" if ($DEBUG==1);
     return;
   }
   my $result;
   #my $link_table_node_type=&_get_node_type($node);
    my $link_table_node_type=$cache_dump_test_type{$node};

   # first test if it is link_table, then get the foreign key
   if (defined $node && $node->getNodeType() == ELEMENT_NODE){
     my $parent_node=$node->getParentNode();
     #my $node_name=$node->getNodeName();
     #my $node_name=$cache_node_name->get($node);
      my $node_name=$cache_node_name{$node};
     my $first_child_node;
     if (defined $parent_node){
       #my $parent_node_name=$parent_node->getNodeName();
       #my $parent_node_name=$cache_node_name->get($parent_node);
       my $parent_node_name=$cache_node_name{$parent_node};
       my $table_module=$parent_node_name."_module";
       my @array_link_table=split(/\s+/, $hash_ddl{$table_module});
       my %hash_foreign_key;
       if (defined $hash_ddl{$node_name} && defined $hash_ddl{$parent_node_name}){
         for my $i(0..$#array_link_table){
                my ($table, $foreign_key)=split(/\:/, $array_link_table[$i]);
               if (defined $table && $table eq $node_name){
                   $hash_foreign_key{$foreign_key}=1;
                   $is_link_table=1;
	       }
          }
       }
       else {
               warn "\nnot link table " if ($DEBUG==1);
               return ;
       }
       $first_child_node=$node->getFirstChild();
       if (defined $first_child_node) {
         my $first_child_node_name=$first_child_node->getNodeName();
            if ($is_link_table ==1){
                my $nodes=$node->getChildNodes();
                for my $i(1..$nodes->getLength()){
                    my $child_node=$nodes->item($i-1);

                    if ($child_node->getNodeType() ==ELEMENT_NODE){
                       #my $child_node_name=$child_node->getNodeName();
                       #my $child_node_name=$cache_node_name->get($child_node);
                        my $child_node_name=$cache_node_name{$child_node};
                       #my $child_node_type=&_get_node_type($child_node);
                        my $child_node_type=$cache_dump_test_type{$child_node};
                       warn "\nin _get_join_key:link_table_node_type:$link_table_node_type:child_node_type:$child_node_type:$child_node_name" if ($DEBUG==1);
                       if ($link_table_node_type eq $child_node_type){
                            #remove those appear as test constraint
                            if (defined $hash_foreign_key{$child_node_name}){
                                  delete $hash_foreign_key{$child_node_name};
                            }
			  }
		    }
		}
	        foreach my $key(keys %hash_foreign_key){
		  if (defined $result){
                      $result=$result.":".$key;
		  }
                  else {
                      $result=$key;
                  }
	        }
                warn "\njoin foreign key:$result: for table:", $node->getNodeName() if ($DEBUG==1);
                return $result;
	    }
	}
      #not feature_relationship table, but other link table, then all foreign key will become join key
      else {
	if ($is_link_table==1){
	  foreach my $key (keys %hash_foreign_key){
	    if (defined $result){
                $result=$result.":".$key;
	      }
             else {
                $result=$key;
             }
             warn "\nin get join key:$key" if ($DEBUG==1);
	  }
          return $result;
        }
      }
     }
     else {
        warn "\nparent node is not defined" if ($DEBUG==1);
        return;
     }
   }
   else {
     warn "\nnode not defined or is not ELEMENT_NODE" if ($DEBUG==1);
     return ;
   }
 }


=head2 get_join_foreigh_key_node

  Arg [1]    : link_table node reference
  Example    :
  Description: public method, if want to dump link table, figure out  which is used to join with main table 
               i.e. feature_relationship.subjfeature_id or feature_relationship.objfeature_id
               Algorithmas: 1. it is foreign key, 2. ONLY one child element_node, and the child_element_node is column_element_node
               new version can return more than ONE node ????
  Returntype : column key node or null if no
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut


 sub get_foreign_key_node () {
   my $self=shift;
   my $node=shift;
   my $link_table_node_type=shift;
   my $is_link_table=0;
   my $is_join_key=0;
   if (!(defined $node)){
     warn "\nnode not defined";
     return;
   }

  # my $link_table_node_type=&_get_node_type($node);

   # first test if it is link_table, then get the foreign key
   if (defined $node && $node->getNodeType() == ELEMENT_NODE){
     my $parent_node=$node->getParentNode();
     my $first_child_node;
     if (defined $parent_node){
       my $parent_node_name=$parent_node->getNodeName();
       $first_child_node=$node->getFirstChild();
       if (defined $first_child_node){
         my $first_child_node_name=$first_child_node->getNodeName();
         my $node_name=$node->getNodeName();
        if (defined $hash_ddl{$node_name} && defined $hash_ddl{$parent_node_name}){
            my $table_module=$parent_node_name."_module";
            my @array_link_table=split(/\s+/, $hash_ddl{$table_module});
            my %hash_foreign_key;
            for my $i(0..$#array_link_table){
               my ($table, $foreign_key)=split(/\:/, $array_link_table[$i]);
               if (defined $table && $table eq $node_name){
                   $hash_foreign_key{$foreign_key}=1;
                   $is_link_table=1;
	       }
	    }
            if ($is_link_table ==1){
                my $nodes=$node->getChildNodes();
                for my $i(1..$nodes->getLength()){
                    my $child_node=$nodes->item($i-1);
                    if ($child_node->getNodeType() ==ELEMENT_NODE){
                       my $child_node_name=$child_node->getNodeName();
                       #my $child_node_type=&_get_node_type($child_node);
                        my $child_node_type=$cache_dump_test_type{$child_node};
                       #return the first child node that is foreign key
                       warn "\nlink_table_node_type:$link_table_node_type:child_node_type:$child_node_type:child_node:", $child_node->getNodeName() if ($DEBUG==1);
                       if (defined $hash_foreign_key{$child_node_name} && $link_table_node_type eq $child_node_type){
                           return $child_node;
                       }
		    }
		}
                #search all child, and can't find the foreign key, so return null;
                warn "\nunable to find foreign node for node:", $node->getNodeName();
                return;
	    }
            else {
               warn "\nnot link table " if ($DEBUG==1);
               return ;
            }
	}
      }
      #no constraint, then return null
      else {
        return;
      }
     }
     else {
        warn "\nparent node is not defined" ;
        return;
     }
   }
   else {
     warn "\nnode not defined or is not ELEMENT_NODE";
     return ;
   }
 }


=head2 _get_join_foreigh_key_node

  Arg [1]    : link_table node reference
  Example    :
  Description: private method, if want to dump link table, figure out  which is used to join with main table 
               i.e. feature_relationship.subjfeature_id or feature_relationship.objfeature_id
               Algorithmas: 1. it is foreign key, 2. ONLY one child element_node, and the child_element_node is column_element_node
               new version can return more than ONE node ????
  Returntype : column key node or null if no
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut


 sub _get_foreign_key_node () {

   my $node=shift;
   my $link_table_node_type=shift;

   my $is_link_table=0;
   my $is_join_key=0;
   if (!(defined $node)){
     warn "\nnode not defined";
     return;
   }
   warn "\nentrance node for _get_foreign_key_node:", $node->getNodeName() if ($DEBUG==1);

   # first test if it is link_table, then get the foreign key
   if (defined $node && $node->getNodeType() == ELEMENT_NODE){
     my $parent_node=$node->getParentNode();
     my $first_child_node;
     if (defined $parent_node){
        my $parent_node_name=$parent_node->getNodeName();
        $first_child_node=$node->getFirstChild();
        if (defined $first_child_node){
        my $first_child_node_name=$first_child_node->getNodeName();
        my $node_name=$node->getNodeName();
        if (defined $hash_ddl{$node_name} && defined $hash_ddl{$parent_node_name}){
            my $table_module=$parent_node_name."_module";
            my @array_link_table=split(/\s+/, $hash_ddl{$table_module});
            my %hash_foreign_key;
            for my $i(0..$#array_link_table){
               my ($table, $foreign_key)=split(/\:/, $array_link_table[$i]);
               if (defined $table && $table eq $node_name){
                   $hash_foreign_key{$foreign_key}=1;
                   $is_link_table=1;
	       }
	    }
            if ($is_link_table ==1){
                my $nodes=$node->getChildNodes();
                for my $i(1..$nodes->getLength()){
                    my $child_node=$nodes->item($i-1);
                    if ($child_node->getNodeType() ==ELEMENT_NODE){
                       my $child_node_name=$child_node->getNodeName();
                       #my $child_node_type=&_get_node_type($child_node);
                        my $child_node_type=$cache_dump_test_type{$child_node};
                       #any child that is foreign key, will be returned, here only return the first one, what happen there is more than one ?
                       if (defined $hash_foreign_key{$child_node_name} && $link_table_node_type eq $child_node_type){
                           warn "\n_get_foreign_key node name:", $child_node->getNodeName();
                           return $child_node;
                       }
		    }
		}
                #search all child, and can't find the foreign key, so return null;
                warn "\nunable to find foreign node for node:", $node->getNodeName() if ($DEBUG==1);
                return;
	    }
            else {
               warn "\nnot link table ";
               return ;
            }
	}
      }
      #no constraint, then return null
      else {
        warn "\nno constraint...";
        return;
      }
     }
     else {
        warn "\nparent node is not defined";
        return;
     }
   }
   else {
     warn "\nnode not defined or is not ELEMENT_NODE";
     return ;
   }
 }

=head2 _get_link_table_node

  Arg [1]    : link_table node reference
  Example    :
  Description: based on the name(suppose to be link table, i.e feature_relationship is link table of feature) and node,
               get see whether has link_table node as child node of the input node
               here at most get one node, can be more than one in the next version ?????
  Returntype : column key node or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut


 sub get_link_table_node (){
     my $self=shift;
     my $node=shift;
     my $link_table=shift;
     my $type=shift;

     warn "\nnode:", $node->getNodeName(), "\tlink_table:$link_table\ttype:$type";
     my $node_type;


     if (defined $node && $node->getNodeType() ==ELEMENT_NODE){
           my $nodes=$node->getChildNodes();
           for my $i(1..$nodes->getLength()){
               my $child_node=$nodes->item($i-1);
               if ($child_node->getNodeType() ==ELEMENT_NODE){
                   my $child_node_name=$child_node->getNodeName();
                   #$node_type=&_get_node_type($child_node);
                    $node_type=$cache_dump_test_type{$child_node};
                   warn "\nnode_type is:$node_type for node:", $child_node->getNodeName();
                   if (defined $hash_ddl{$child_node_name} && $child_node_name eq $link_table && $type eq $node_type){
                         #&_traverse($child_node);
                         return $child_node;
		   }
	       }
           }
           return;
     }
     else {
       warn "\nnode not defined or not ELEMENT_NODE";
     }
   return;
 }


=head2 get_primary_table_node

  Arg [1]    : column_element_node reference
  Example    :
  Description: for column_element_node, to get the primay_table_node, eg. subjfeature_id to get feature_node
               algorithms: 1.This is  ONLY ONE child_element_node,2.foreign key of parent, and primary key of child_element_node
  Returntype : primary table node reference or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut


 sub get_primary_table_node(){
    my $self=shift;
    my $node=shift;
    my $child_node_number=0;
    my $primary_table_node;
    my $child_node;
    if (defined $node){
        my $node_name=$node->getNodeName();
        my $parent_node=$node->getParentNode();
        my $parent_node_name=$parent_node->getNodeName();
        my $nodes=$node->getChildNodes();
        for my $i(1..$nodes->getLength()){
           $child_node=$nodes->item($i-1);
           if ($child_node->getNodeType() ==ELEMENT_NODE){
                 my $child_node_name=$child_node->getNodeName();
                 my $table_ref=$parent_node_name.":".$node_name."_ref_table";
                 if (defined $hash_ddl{$child_node_name} && defined $hash_ddl{$child_node_name} && $hash_ddl{$table_ref} eq $child_node_name){                         return $child_node;

		  }
	   }
        }
       # if ($child_node_number ==1){
          # return $primary_table_node;
       #   return $child_node;
       # }
       # else {
       #    print "\ndump spec error: have more than reference node for node:", $node_name;
       #    return ;
       # }
    }
    else {
      warn "\nnode not defined";
      return;
    }
 }


=head2 _get_primary_table_node

  Arg [1]    : column_element_node reference
  Example    :
  Description: private method, for column_element_node, to get the primay_table_node, eg. subjfeature_id to get feature_node
               algorithms: 1.This is  ONLY ONE child_element_node,2.foreign key of parent, and primary key of child_element_node
  Returntype : primary table node reference or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut

 sub _get_primary_table_node(){
    my $node=shift;
    my $child_node_number=0;
    my $primary_table_node;
    my $child_node;
    if (defined $node){
        my $node_name=$node->getNodeName();
        my $parent_node=$node->getParentNode();
        my $parent_node_name=$parent_node->getNodeName();
        my $nodes=$node->getChildNodes();
        for my $i(1..$nodes->getLength()){
           $child_node=$nodes->item($i-1);
           if ($child_node->getNodeType() ==ELEMENT_NODE){
                 my $child_node_name=$child_node->getNodeName();
                 my $table_ref=$parent_node_name.":".$node_name."_ref_table";
                 if (defined $hash_ddl{$child_node_name} && defined $hash_ddl{$child_node_name} && $hash_ddl{$table_ref} eq $child_node_name){                         return $child_node;
                        # $primay_table_node= $child_node;
                        # $child_node_number ++;
                        # print "\nchild_node_number:", $child_node_number;
                        # print "\nprimary_table_name:", $child_node->getNodeName();
		  }
	   }
        }
       # if ($child_node_number ==1){
          # return $primary_table_node;
       #   return $child_node;
       # }
       # else {
       #    print "\ndump spec error: have more than reference node for node:", $node_name;
       #    return ;
       # }
    }
    else {
      warn "\nnode not defined";
      return;
    }
 }


=head2 get_nested_node

  Arg [1]    : node reference
  Arg [2]    : path
  Arg [3]    : type: test/dump
  Example    : <feature_relationship dump="all">
                    <subjfeature_id test="yes">
                       <feature>
                           <type_id>
                              <cvterm>
                                  <termname>transcript</termname>
                              </cvterm>
                           </type_id>
                       </feature>
                     </subjfeature_id>
               </feature_relationship>
               get_nested_node($feature_relationship_node, 'feature_relationship:subjfeature_id:feature', 'test') will get feature node
               get_nested_node($feature_relationship_node, 'feature_relationship:subjfeature_id:feature', 'dump') will get null node


  Description:  method to retrieve node based on the node, path & type
               algorithms: except the node self, all child node, the type will be same as the input type
  Returntype : nested node reference or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : input is link table

=cut
=head
sub get_nested_node(){
   my $self=shift;
   my $node=shift;
   my $path=shift;
   my $type=shift;

  if (!(defined $type) ) {
             warn "\nmiss type in get_nested_node";
             return ;
  }
   if (defined $node ){
     if ($node->getNodeType() ne ELEMENT_NODE){
        warn "\nthis node is ELEMENT_NODE";
        return;
     }
   }


   my @elements=split(/\:/,$path);
   my $query='';
   for my $i(1..$#elements){
      $query=$query."\/".$elements[$i] ;
      $query=~s/^\///;
   }

  my @result = XML::XQL::solve ($query, $node);
  for my $j(0..$#result){
      #my $node_type=&_get_node_type($result[$j]);
       my $node_type=$cache_dump_test_type{$result[$j]};
      if ($node_type eq $type){
         return $result[$j];
      }
  }
  return;
}
=cut
#=head obsolete, we use XQL to quickly locate the node
sub get_nested_node(){
   my $self=shift;
   my $node=shift;
   my $path=shift;
   my $type=shift;

  if (!(defined $type) ) {
             warn "\nmiss type in get_nested_node";
             return ;
  }
   if (defined $node ){
     if ($node->getNodeType() ne ELEMENT_NODE){
        warn "\nthis node is ELEMENT_NODE";
        return;
     }
   }


   my $nodes;
   my $child_node;
   my $child_node_name;
   my $child_node_type;
   my $node_name;
   my $success=0;

   my@array_path=split(/:/, $path);
   my $size=$#array_path+1;
   my $level=0;
   # to retrieve test node, it need guarantee that no dump attribute, for dump node, no test attribute
   my $attribute;

 if (defined $node){
   $node_name=$node->getNodeName();
   if ($type eq $TYPE_DUMP && $node->getNodeType ==ELEMENT_NODE && $node_name eq $array_path[$level]){
       $attribute=$node->getAttribute($TYPE_TEST);
   }
   elsif ($type eq $TYPE_TEST && $node->getNodeType ==ELEMENT_NODE && $node_name eq $array_path[$level]){
       $attribute=$node->getAttribute($TYPE_DUMP);
   }
   #warn "\nnode name:$node_name";
   if ($node_name eq $array_path[$level]){
     $level=$level+1;
     while ($level<$size){
       $success=0;
       $nodes=$node->getChildNodes();
       for my $i(1..$nodes->getLength()){
          #here node become child_node
          $node=$nodes->item($i-1);
          $child_node_name=$node->getNodeName();

          if ($node->getNodeType ==ELEMENT_NODE  && $child_node_name eq $array_path[$level] ){
              #$child_node_type=&_get_node_type($node);
               $child_node_type=$cache_dump_test_type{$node};warn "\nunable to find nested node:", $node->getNodeName() and exit if (not defined $child_node_type);
              if ($type eq $child_node_type){
                 $level=$level+1;
                 $success=1;
                 last;
	     }
	  }
       }
       #in order to retrieve nested node, it must follow all the path, type of child_node eq type
       if ($success==0){
              return;
       }
     }
   }
   else {
     warn "\nattribute in get_nested_node:$attribute:type:$type:\n" if ($DEBUG==1);
     return ;
   }
 }
   #&_traverse($node);
   return $node;
 }
#=cut


=head2 _traverse

  Arg [1]    : node reference
  Example    :
  Description: private method to print out node
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : 

=cut

sub _traverse {
    my($node)= @_;
    if ($node->getNodeType == ELEMENT_NODE) {

      my $att_id=$node->getAttribute ('id');
      my $att_op=$node->getAttribute('op');
      my $att_id_string=undef;
      my $att_op_string=undef;
      if (defined $att_id && $att_id ne ''){
         $att_id_string=" id=\'". $att_id."\'";
      }
      if (defined $att_op && $att_op ne ''){
         $att_op_string=" op=\'". $att_op."\'";
      }
      print "<", $node->getNodeName, $att_id_string,  $att_op_string, ">";
      foreach my $child ($node->getChildNodes()) {
        _traverse($child);
      }
      print "</", $node->getNodeName, ">";
    } elsif ($node->getNodeType() == TEXT_NODE) {
      print $node->getData;
    }
  }


sub _cache_object {
  my($node)= @_;
  return if !(defined $node);
  my $type;
  my $attribute;
    if ($node->getNodeType==DOCUMENT_NODE){
      foreach my $child ($node->getChildNodes()) {
        &_cache_object($child);
      }
    }
    if ($node->getNodeType == ELEMENT_NODE ) {
      my $node_name=$node->getNodeName();
      $cache_node_name{$node}= $node_name;
     #here to figure out the type as dump or test
     if (defined $node->getParentNode() && $node->getParentNode()->getNodeName() eq $ROOT_NODE){
       $cache_dump_test_type{$node}=$TYPE_DUMP;

     }
     else {
       my %hash_type;
       my $flag=0;
       $hash_type{$TYPE_DUMP}=$TYPE_TEST;
       $hash_type{$TYPE_TEST}=$TYPE_DUMP;
       foreach my $key (keys %hash_type){
          $type=$node->getAttribute($key);
          if (defined $type && $type ne ''){
             $cache_dump_test_type{$node}= $key;
             $flag=1; last;
          }
       }
       if (!$flag){
        $type=$cache_dump_test_type{$node->getParentNode()};
        $cache_dump_test_type{$node}=$type;
      }
     }
      foreach my $child ($node->getChildNodes()) {
        _cache_object($child);
      }
    }
  }

=head2 _toString

  Arg [1]    : node reference
  Example    :
  Description: private method to get string represent of the node
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : 

=cut

sub _toString {
    my($node)= @_;
    my $result;
    if ($node->getNodeType == ELEMENT_NODE) {

      my $att_id=$node->getAttribute ('id');
      my $att_op=$node->getAttribute('op');
      my $att_id_string=undef;
      my $att_op_string=undef;
      if (defined $att_id && $att_id ne ''){
         $att_id_string=" id=\'". $att_id."\'";
      }
      if (defined $att_op && $att_op ne ''){
         $att_op_string=" op=\'". $att_op."\'";
      }
      $result=$result. "<". $node->getNodeName. $att_id_string.  $att_op_string. ">";
      foreach my $child ($node->getChildNodes()) {
        _toString($child);
      }
      $result=$result. "</".$node->getNodeName. ">";
    } elsif ($node->getNodeType() == TEXT_NODE) {
      $result=$result. $node->getData;
    }
    return $result;
  }

=head2 traverse

  Arg [1]    : node reference
  Example    :
  Description: public method to print out node
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre:       : 

=cut
sub traverse (){
  my $self=shift;
  my $node=shift;
  &_traverse($node);
}

=head2 get_app_data

  Arg [1]    : ROOT node reference
  Example    :
  Description: get the app_data information if there is any.
  Returntype : string or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut

sub get_app_data(){
   my $self=shift;
   my $node=shift;
   my $app_data_string;
   my $node_name;
   warn "\nnode_name:$node_name:\n" if ($DEBUG==1);
   if ($node->getNodeType == ELEMENT_NODE) {
      $node_name=$node->getNodeName();
      if ($node_name eq $ROOT_NODE){
         return &_get_app_data($node);
      }
      else {
        warn "\nyou can only retrieve app_data for root node";

      }
   }
  return;
}


=head2 _get_app_data

  Arg [1]    : ROOT node reference
  Example    :
  Description: private method to get the app_data information if there is any.
  Returntype : string or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut

sub _get_app_data(){
  my $node=shift;
  my $app_data_string;
  my $node_name;

  if ($node->getNodeType == ELEMENT_NODE) {
      $node_name=$node->getNodeName();
      if ($node_name eq $ROOT_NODE){
         #here to get all attribute
         my $attribute="";
         my $attribute_node;
         my $attribute_nodes=$node->getAttributes();
         for my $i(0..$attribute_nodes->getLength-1){
            $attribute_node=$attribute_nodes->item($i);
            $attribute=$attribute." ".$attribute_node->getName()."=\"".$attribute_node->getValue()."\"";
	 }
         $app_data_string="\n<".$node_name." ".$attribute.">";
         my $child_nodes=$node->getChildNodes();
         for my $i(1..$child_nodes->getLength()){
            my $child_node=$child_nodes->item($i-1);
            if ($child_node->getNodeType ==ELEMENT_NODE){
               my $child_node_name=$child_node->getNodeName();
               if ($child_node_name eq $APP_DATA_NODE){
                   $app_data_string=$app_data_string.&_get_app_data($child_node);
	       }
	    }
         }
        #$app_data_string=$app_data_string."</".$node_name.">";
      }
      elsif ($node_name eq $APP_DATA_NODE){
         my $attribute="";
         my $attribute_node;
         my $attribute_nodes=$node->getAttributes();
         for my $i(0..$attribute_nodes->getLength-1){
            $attribute_node=$attribute_nodes->item($i);
            $attribute=$attribute." ".$attribute_node->getName()."=\"".$attribute_node->getValue()."\"";
	 }
         $app_data_string="\n    <".$node_name." ".$attribute.">";
         my $child_nodes=$node->getChildNodes();
         for my $i(1..$child_nodes->getLength()){
            my $child_node=$child_nodes->item($i-1);
            if ($child_node->getNodeType ==ELEMENT_NODE){
               my $child_node_name=$child_node->getNodeName();
               if ($child_node_name eq $SQL_NODE){
                   $app_data_string=$app_data_string.&_get_app_data($child_node);
	       }
	    }
            elsif ($child_node->getNodeType ==TEXT_NODE){
                   $app_data_string=$app_data_string.&_get_app_data($child_node);
	    }
         }
         $app_data_string=$app_data_string."</".$node_name.">";
      }
      elsif ($node_name eq $SQL_NODE){
         my $parent_node=$node->getParentNode();
         if (defined $parent_node && $parent_node->getNodeName() eq $APP_DATA_NODE){
             my $sql_string=$node->getFirstChild()->getData();
             $app_data_string=&_get_sql_result($sql_string);
         }
      }
  }
  elsif ($node->getNodeType()==TEXT_NODE){
    my $parent_node=$node->getParentNode();
    if (defined $parent_node && $parent_node->getNodeName() eq $APP_DATA_NODE){
       $app_data_string=$app_data_string.$node->getData();
    }
  }
 return $app_data_string;
}


sub _get_sql_result(){
  my $sql=shift;
  my $result;
  $result=$dbh_obj->get_one_value($sql);


  return $result;
}

=head2 replace_dumpspec

  Arg [1]    : dumpspec file
  Arg [1]    : array reference
  Example    :
  Description: Given an ordered array of values (eg @vals below) corresponding to 
               similarly ordered fields (designated like $1,$2,$3,...) in a 
               preformatted form, substitute the values into the form fields.
  Returntype : string or null
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut

sub replace_dumpspec (){
  my $self=shift;
  my $file=shift;
  my $array_ref=shift;

  my $temp_spec=">".$tmp."/temp_dumpspec.xml";
  my @array_arg=@$array_ref;
  open (IN, $file ) or die "unable to open the dumpspec file";
  open (OUT, $temp_spec) or die "unable to write the temp_dumpspec.xm";
  while (<IN>){
   my $value=$_;
   if ($#array_arg >-1){
     for my $i(1..$#array_arg+1){
       my $new=$array_arg[$i-1];
       $value=~  s/\$$i/$array_arg[$i-1]/g;
      }
   }
   print OUT $value;
  }

close(IN);
close(OUT);
}


=head2 _get_node_type

  Arg [1]    : node reference
  Example    :
  Description:internal method to figure out the type of this node:it is for "test" or for "dump"
               if can not identify type by self, then base on parent_node type
  Returntype : string, test/dump
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut


sub _get_node_type(){
  my $node=shift;

  my $type;
  my $attribute;
  if (!(defined $node)){
     warn "\nnode not defined in _get_node_type";
     return;
  }
  elsif ($node->getParentNode()->getNodeName() eq $ROOT_NODE){
     $type=$TYPE_DUMP;
     return $type;
   }

  my %hash_type;
  $hash_type{$TYPE_DUMP}=$TYPE_TEST;
  $hash_type{$TYPE_TEST}=$TYPE_DUMP;
  foreach my $key (keys %hash_type){
    $type=$node->getAttribute($key);
    if (defined $type && $type ne ''){
       return $key;
    }
  }

  while (1){
    $node=$node->getParentNode();
    if (defined $node){
        foreach my $key (keys %hash_type){
           $type=$node->getAttribute($key);
           if (defined $type && $type ne ''){
                return $key;
           }
        }
    }
    else {
      return;
    }
  }

}


=head2 get_node_type

  Arg [1]    : node reference
  Example    :
  Description: public  method to figure out the type of this node:it is for "test" or for "dump"
               if can not identify type by self, then base on parent_node type
  Returntype : string, test/dump
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut

sub get_node_type(){
  my $self=shift;
  my $node=shift;

  my $type;
  my $attribute;
  if (!(defined $node)){
     warn "\nnode not defined in _get_node_type";
     return;
  }
  elsif ($node->getParentNode()->getNodeName() eq $ROOT_NODE){
     $type=$TYPE_DUMP;
     return $type;
   }

  my %hash_type;
  $hash_type{$TYPE_DUMP}=$TYPE_TEST;
  $hash_type{$TYPE_TEST}=$TYPE_DUMP;
  foreach my $key (keys %hash_type){
    $type=$node->getAttribute($key);
    if (defined $type && $type ne ''){
       return $key;
    }
  }

  while (1){
    $node=$node->getParentNode();
    if (defined $node){
        foreach my $key (keys %hash_type){
           $type=$node->getAttribute($key);
           if (defined $type && $type ne ''){
                return $key;
           }
        }
    }
    else {
      return;
    }
  }

}


=head2 _get_attribute_value

  Arg [1]    : node reference
  Example    :
  Description: internal method to figure out the attribute of 'test' or 'dump', not anything else.
               if can not identify type by self, then base on parent_node type,
               if is subelement of 'chado', and no attribute of dump, then it will be 'all'
  Returntype : string, test/dump
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut


sub _get_attribute_value(){
  my $node=shift;

  my $attribute;
  if (!(defined $node)){
     warn "\nnode not defined in _get_node_type";
     return;
  }
  elsif ($node->getParentNode()->getNodeName() eq $ROOT_NODE){
       $attribute=$node->getAttribute($TYPE_DUMP);
       if (!(defined $attribute)){
           $attribute=$DUMP_ALL;
           return $attribute;
       }
   }

  my %hash_type;
  $hash_type{$TYPE_DUMP}=$TYPE_TEST;
  $hash_type{$TYPE_TEST}=$TYPE_DUMP;
  foreach my $key (keys %hash_type){
    $attribute=$node->getAttribute($key);
    if (defined $attribute && $attribute ne ''){
       return $attribute;
    }
  }

  while (1){
    $node=$node->getParentNode();
    if (defined $node){
        foreach my $key (keys %hash_type){
           $attribute=$node->getAttribute($key);
           if (defined $attribute && $attribute ne ''){
                return $attribute;
           }
        }
    }
    else {
      return;
    }
  }

}


=head2 get_attribute_value

  Arg [1]    : node reference
  Example    :
  Description: public  method to figure out the attribute of 'test' or 'dump', not anything else.
               if can not identify type by self, then base on parent_node type,
               if is subelement of 'chado', and no attribute of dump, then it will be 'all'
  Returntype : string, test/dump
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut

sub get_attribute_value(){
  my $self=shift;
  my $node=shift;

  my $attribute;
  if (!(defined $node)){
     warn "\nnode not defined in _get_node_type";
     return;
  }
  elsif ($node->getParentNode()->getNodeName() eq $ROOT_NODE){
       $attribute=$node->getAttribute($TYPE_DUMP);
       if (!(defined $attribute)){
           $attribute=$DUMP_ALL;
           return $attribute;
       }
   }

  my %hash_type;
  $hash_type{$TYPE_DUMP}=$TYPE_TEST;
  $hash_type{$TYPE_TEST}=$TYPE_DUMP;
  foreach my $key (keys %hash_type){
    $attribute=$node->getAttribute($key);
    if (defined $attribute && $attribute ne ''){
       return $attribute;
    }
  }

  while (1){
    $node=$node->getParentNode();
    if (defined $node){
        foreach my $key (keys %hash_type){
           $attribute=$node->getAttribute($key);
           if (defined $attribute && $attribute ne ''){
                return $attribute;
           }
        }
    }
    else {
      return;
    }
  }
}


=head2 _validate_sql_element

  Arg [1]    : sql statement
  Arg [2]    : node reference
  Example    :
  Description:  this will validate the _sql element for dumpspec
                1. all selected cols come from parent_node s col
                2. selected cols match with the attribute 'dump' of parent, i.e, if dump='all', 
                   then it should include all cols, except the primary key
                3. _sql can only nested with root_element and table_element
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut


sub _validate_sql_element(){
  my $sql_stm=shift;
  my $node=shift;

  # set this to mark the status of validation
  my $IS_VALID=0;
  my $hash_ref_col;

  my $parent_node=$node->getParentNode() if (defined $node);
  my $parent_node_name=$node->getParentNode()->getNodeName() if (defined $node);
  if (defined $hash_ddl{$parent_node_name}){
     $hash_ref_col=&_get_table_columns($parent_node_name);
  }
  else {
     warn "\ninvalid _sql location, it can only be nested within table_element";
     exit(1);
  }

    my $string_primary_key=$parent_node_name."_primary_key";
    my $table_id=$hash_ddl{$string_primary_key};

    #here to check the "select"

      my @temp_select=split(/\s*select\s*/, $sql_stm);
      my @temp_from=split(/\s*from\s*/, $temp_select[1]);
      my $what=$temp_from[0];
      my @array_cols=split(/\s*\,\s*/, $what);
      my $alias;
      my $column;
      if ($what =~/\./){
         ($alias, $column)=split(/\./, $array_cols[0]);
         warn "\nthis column:$alias.$column does not belong to table:$parent_node_name" and exit if !(defined $hash_ref_col->{$column});
         for my $i (1..$#array_cols){
            my ($alias_temp, $column_temp)=split(/\./, $array_cols[$i]);
               warn "\nthis column:$alias_temp.$column_temp: does not belong to table:$parent_node_name\n" and exit if !(defined $hash_ref_col->{$column}) || ($alias ne $alias_temp);
        }
      }
      else {
	foreach my $i(0..$#array_cols){
           warn "\nthis column:$array_cols[$i] does not belong to table:$parent_node_name\n" and exit if !(defined $hash_ref_col->{$array_cols[$i]}) && $array_cols[$i] ne '*';
	}
      }

    # here to check the "from" 
      my @temp_where=split(/\s*where\s*/, $temp_from[1]);
      my $from_list=$temp_where[0];
      my @array_from=split(/\s*\,\s*/, $from_list);
      for my $i(0..$#array_from){
         if (!(defined $alias) && $array_from[$i] eq $parent_node_name){
                $IS_VALID=1;
                last;
         }

         if (defined $alias){
            my ($table_temp, $alias_temp)=split(/\s+/, $array_from[$i]);
	    if ($table_temp eq $parent_node_name && $alias_temp eq $alias){
                    $IS_VALID=1;
                    last;
	    }
	 }
      }

     #special case use * , i.e. select * from feature f, cvterm c
     if ($what eq '*' && $#array_from >0){
          warn "\nwhat:$what:this is not valid _sql node:$sql_stm\n";
          exit(1);
     }
      # for case: select * from cvterm c
      elsif ($what eq '*' && $#array_from ==0){
         $IS_VALID=1;
     }


     warn "\nIS_VALID:$IS_VALID:this is not valid _sql node:$sql_stm\n" and exit if ($IS_VALID ==0);
     #here to check the consistency of 'dump' attribute and 'cols select' in _sql, i.e, if dump eq 'DUMP_ALL', then need to select all cols
     my $attribute=&_get_attribute_value($parent_node);
     if ($attribute eq $DUMP_ALL){
        my %hash_cols;
        foreach my $value(@array_cols){
	  if (defined $alias){
             my ($alias_temp, $column_temp)=split(/\./, $value);
             $hash_cols{$column_temp}=1;
          }
          else {
            $hash_cols{$value}=1;
          }
        }
        foreach my $value(keys %$hash_ref_col){
	  if (!(defined $hash_cols{$value}) && $value ne $table_id && $what ne '*' ){
              warn "\nas dump:$DUMP_ALL, you need to include all cols, here you missed this col:$value\n";
              exit(1);
	  }
	}
     }



}


=head2 _validate_sql_element

  Arg [1]    : sql statement
  Arg [2]    : node reference
  Example    :  query 1: select * from feature_relationship where objfeature_id=47  and subjfeature_id 
                         in (select feature_0.feature_id from cvterm cvterm_0 , feature feature_0 
                         where  cvterm_0.termname= 'transcript' and feature_0.type_id=cvterm_0.cvterm_id)

                query 2: select fr0.subjfeature_id, fr0.objfeature_id from feature_relationship fr0, cvterm cvterm_0 , feature feature_0 
                         where fr0.objfeature_id=47 and fr0.subjfeature_id=feature_0.feature_id and cvterm_0.termname='transcript' 
                         and feature_0.type_id=cvterm_0.cvterm_id
  Description: method which format the first query into second query, which get ride of "in" to improve performance
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut


sub transform_in_query (){
  my $self=shift;
  my $in_query=shift;
  warn "\nin_query in transorm_in_query:\n", $in_query if ($DEBUG==1);

  my $out_query;
  my @array_where;
  my %hash_where;
  my %hash_tables;
  my %hash_what;
  my %hash_table_alias_no;
  my $join_key_right;
  my $join_key_left;
  my $what_list;
  my $table_list;
  my $where_list;



  my @array_query=split (/\s*in\s+\(/, $in_query);


  #deal with sub query
  my @temp_sub1=split(/\s*where\s*/, $array_query[1]);
  #get all where of subquery if there is any where statement
  if ($#temp_sub1 ==1){
     my @temp_sub2=split(/\s*and\s*/, $temp_sub1[1]);

     for my $i(0..$#temp_sub2){
       #last where with )
       if ($temp_sub2[$i] !~ /\)/){
          $hash_where{$temp_sub2[$i]}=1;
       }
       else {
          my @temp_sub3=split(/s*\)/, $temp_sub2[$i]);
          $hash_where{$temp_sub3[0]}=1;
       }
     }
  }

  #get all tables of subquery
  my @temp_sub4=split(/\s+from\s+/, $temp_sub1[0]);


  my @temp_sub5=split(/\s*,\s*/, $temp_sub4[1]);
  for my $i(0..$#temp_sub5){
    $hash_tables{$temp_sub5[$i]}=1;
    warn "\nsub table:$temp_sub5[$i]" if ($DEBUG==1);
  }
  my @temp_sub6=split (/\s*select\s+/, $temp_sub4[0]);
  $join_key_right=$temp_sub6[1];

  #here to figure all max number to mark table alias, if the alias is not in the format of .._.., then set default as 0
  foreach my $key (keys %hash_tables){
      my @temp_sub7=split(/\s+/, $key);

       #0:table 1:alias
      if ($#temp_sub7 ==1){
        my @temp_sub8=split(/\_/, $temp_sub7[1]);
        if ($#temp_sub8>0) {
	  if (!(defined $hash_table_alias_no{$temp_sub7[0]}) || $hash_table_alias_no{$temp_sub7[0]} <$temp_sub8[$#temp_sub8]){
              $hash_table_alias_no{$temp_sub7[0]}=$temp_sub8[$#temp_sub8]
	  }
        }
        else {
          $hash_table_alias_no{$temp_sub7[0]}=0;
        }
        warn "\ntable:$temp_sub7[0]: \talias no:$hash_table_alias_no{$temp_sub7[0]}" if ($DEBUG==1);
      }
      #no alias, set default alias no as 0
      else {
         $hash_table_alias_no{$temp_sub7[0]}=0;
      }
    }
 warn "\nlast alias no for table:feature:$hash_table_alias_no{'feature'}" if ($DEBUG==1);
#key: table, value: alias for post parsing
my %hash_main_table_alias;
#store the information before parsing, key: old_alias, value: new alias
my %hash_main_old_alias;

  # deal with the main query
  #get the table of main query
  my @temp_where=split(/\s+where\s+/, $array_query[0]);
  my @temp_from=split(/\s+from\s+/, $temp_where[0]);
  my @temp_select=split(/\s*select\s*/, $temp_from[0]);
  my @array_tables_main=split(/\s*,\s*/, $temp_from[1]);

  #parse the tables
  for my $i(0..$#array_tables_main){
    my $alias_no=0;
    my $alias_string;
    my $table_alias;
    warn "\ntable of main:$array_tables_main[$i]:\n" if ($DEBUG==1);
    #no alias in main query
    if ($array_tables_main[$i] !~/\s+/){
        my $temp_table=$array_tables_main[$i];
        warn "\nprevious alias no for table:$temp_table:$hash_table_alias_no{$temp_table}" if ($DEBUG==1);
        if (defined $hash_table_alias_no{$temp_table} && $hash_table_alias_no{$temp_table} =~/\d/){
           $alias_no=$hash_table_alias_no{$temp_table}+1;
	}
        $table_alias=$temp_table."_".$alias_no;
        $alias_string=$temp_table." ".$table_alias;
        warn "\ntable_alias:$table_alias:\talias_string:$alias_string" if ($DEBUG==1);
        $hash_tables{$alias_string}=1;
        $hash_main_table_alias{$temp_table}=$table_alias;
    }
    #there is alias
    else { #0: table, 1: alias
      warn "\nthere is alias in main table:$array_tables_main[$i]:" if ($DEBUG==1);
      my @temp_alias=split(/\s+/,$array_tables_main[$i]);
      #there is same table in subquery
      if ( defined $hash_table_alias_no{$temp_alias[0]}){
        #alias in the format of: ***_*
        if ($temp_alias[1] =~/\_/){
            my @temp_1=split(/\_/, $temp_alias[1]);
            $alias_no=$temp_1[1]+$hash_table_alias_no{$temp_alias[0]}+1;
            warn "\noriginal alias_no:$hash_table_alias_no{$temp_alias[0]}" if ($DEBUG==1);
            warn "\nin format of _:$alias_no:table:$temp_alias[0]:" if ($DEBUG==1);
	}
        else {
            $alias_no=$hash_table_alias_no{$temp_alias[0]}+1;
            warn "\nnot in format of _:$alias_no";
        }
        $hash_table_alias_no{$temp_alias[0]}=$alias_no;
        my $new_alias=$temp_alias[0]."_".$alias_no;
        $hash_main_table_alias{$temp_alias[0]}=$new_alias;
        $hash_main_old_alias{$temp_alias[1]}=$new_alias;

        $alias_string=$temp_alias[0]." ".$new_alias;
        $hash_tables{$alias_string}=1;
      }
      #no same table in subquery, then using the same alias
      else {
        $hash_main_table_alias{$temp_alias[0]}=$temp_alias[1];
        $hash_main_old_alias{$temp_alias[1]}=$temp_alias[1];
        $alias_string=$temp_alias[0]." ".$temp_alias[1];
        $hash_tables{$alias_string}=1;
      }

    }
  }

  #for all tables in main query, get all the cols, store in hash_cols, key:colums, value:table
  my %hash_cols;
  foreach my $key (keys %hash_main_table_alias){
    my @cols=split(/\s+/, $hash_ddl{$key});
    for my $i(0..$#cols){
      $hash_cols{$cols[$i]}=$key;
    }
  }

  #parse the where main query
  warn "\nwhere of main:$temp_where[1]" if ($DEBUG==1);
  my @temp_2=split(/\s+and\s+/, $temp_where[1]);
  #where case: =, like, <>, what else ?, last one will be something "in"
  for my $i(0..$#temp_2-1){
    warn "\nwhere of main:$temp_2[$i]" if ($DEBUG==1);
    my $op;
    my @temp_3;
    if ($temp_2[$i] =~/like/){
       @temp_3=split(/\s*like\s*/, $temp_2[$i]);
       $op="like";
    }
    if ($temp_2[$i] =~/\=/){
       @temp_3=split(/\s*\=\s*/, $temp_2[$i]);
       $op="\=";
    }
    if ($temp_2[$i] =~/\<\>/){
       @temp_3=split(/\s*\<\>\s*/, $temp_2[$i]);
       $op="\<\>";
    }
    my $new_alias;
    for my $j(0..$#temp_3){
      #it is cols, and no alias
      if ($temp_3[$j] !~/\./ && defined $hash_cols{$temp_3[$j]}){
        $temp_3[$j]=$hash_main_table_alias{$hash_cols{$temp_3[$j]}}.".".$temp_3[$j];
      }
      # contain ".", test if this is alias format or not
      elsif ($temp_3[$j] =~/\./){
         my @temp_4=split(/\./, $temp_3[$j]);
         if (defined $hash_main_old_alias{$temp_4[0]}){
             $temp_3[$j]=$hash_main_old_alias{$temp_4[0]}.".".$temp_4[1];
	 }
      }
    }

    my $where_stm=$temp_3[0].$op.$temp_3[1];
    $hash_where{$where_stm}=1;
  }
   #store the join stm
  warn "\njoin_left from main:$temp_2[$#temp_2]:\n" if ($DEBUG==1);
  if ($temp_2[$#temp_2] !~/\./){
    $join_key_left=$hash_main_table_alias{$hash_cols{$temp_2[$#temp_2]}}.".".$temp_2[$#temp_2];
  }
  else {
    my @temp_3=split(/\./, $temp_2[$#temp_2]);
    $join_key_left=$hash_main_old_alias{$temp_3[0]}.".".$temp_3[1];
  }
  my $join_stm=$join_key_right."=".$join_key_left;
  $hash_where{$join_stm}=1;

  #parse the what of main query
  if ($temp_select[1] =~/\*/){
    foreach my $key (keys %hash_main_table_alias){
       my @temp_cols=split(/\s+/, $hash_ddl{$key});
       for my $i(0..$#temp_cols){
          my $hash_what_key=$hash_main_table_alias{$key}.".".$temp_cols[$i];
          $hash_what{$hash_what_key}=1;
       }
    }
  }
  else {
      my @temp_select_1;
     if ($temp_select[1]!~/,/){
        push @temp_select_1, $temp_select[1];
     }
     else {
      @temp_select_1=split(/\s*,\s*/, $temp_select[1]);
     }
     for my $i(0..$#temp_select_1){
      #no alias
      my $temp_what;
      if ($temp_select_1[$i] !~/\./ && defined $hash_cols{$temp_select_1[$i]}){
         $temp_what=$hash_main_table_alias{$hash_cols{$temp_select_1[$i]}}.".".$temp_select_1[$i];
      }
      elsif($temp_select_1[$i] =~/\./){
         my @temp_select_2=split(/\./, $temp_select_1[$i]);
         if (defined $hash_main_old_alias{$temp_select_2[0]} && defined $hash_cols{$temp_select_2[1]}){
            $temp_what=$hash_main_old_alias{$temp_select_2[0]}.".".$temp_select_2[1];
	 }
      }
      warn "\ntemp_what:$temp_what" if ($DEBUG==1);
      $hash_what{$temp_what}=1;
     }
   }


  #finalize the statement
  foreach my $key(keys %hash_what){
    if (defined $what_list){
      $what_list=$what_list.",".$key;
    }
    else {
      $what_list=$key;
    }
  }

  foreach my $key(keys %hash_tables){
    if (defined $table_list){
      $table_list=$table_list.",".$key;
    }
    else {
      $table_list=$key;
    }
  }

  foreach my $key(keys %hash_where){
    if (defined $where_list){
      $where_list=$where_list." and ".$key;
    }
    else {
      $where_list=$key;
    }
  }

  $out_query="select ".$what_list." from ".$table_list." where ".$where_list;
  return $out_query;

}

# close the DB connection
sub close (){
  my $self=shift;
  $dbh_obj->close();
}



=head2 _get_table_columns

  Arg [1]    : table name
  Example    :
  Description: This util will return a hash ref which contains all the columns of this table
  Returntype : hash_ref
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

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
        }
  return $hash_table_column_ref;
}


=head2 _format_data

  Arg [1]    : table name
  Example    :
  Description: util to format the data, one col each time
  Returntype : hash_ref
  Exceptions : Thrown is invalid arguments are provided
  Pre:       :

=cut


 sub _format_data(){
   my $table=shift;
   my $column=shift;
   my $data=shift;

   my $data_type;


   if (defined $hash_ddl{$table}){
      my $data_type_string=$table."_data_type";
      my @temp=split(/;/, $hash_ddl{$data_type_string});
      for my $i(0..$#temp){
         my($col,$type)=split(/:/, $temp[$i]);
         if ($col eq $column){
            $data_type=$type;
            last;
         }
      }

    if ($data_type !~ /int|serial|float|smallint|integer|bigint|decimal|numeric|real|bigserial/  && $data !~ /^'.*'$/){
               $data="\'".$data."\'";
 
     }
   }
   else {
      warn "\ntable:$table not exist in db";
      return;
   }
       return $data;

 }

 #accessory method to that check data type, for anything that is not the (int, float, serial, small, bigint decimal numeric real bigserial) , value will be closed in ''
 # value of each col will be separated by "|"
# for boolean type, replace 0 with 'f' and 1 with 't'
 # $hash_ref=&_data_type_checker($hash_ref,$table_name);
sub _data_type_checker(){
    my $hash_ref=shift;
    my $table=shift;
    my %hash_boolean={
          '0'=>'f',
          '1'=>'t',
    };

    foreach my $key (keys %$hash_ref){
     #	print "\nbefore type check key:$key:\tvalue:$hash_ref->{$key}";
    }


    # here for updated columns, need to replace with new records to cascade the update(here is for non_unique key)
    
	#foreach my $value (keys %$hash_ref){
        #    if (defined $hash_new_value{$value}){
	#	$hash_ref->{$value}=$hash_new_value{$value};
	#    }
	#}


    my $data_type_name=$table."_data_type";
    my $data_type=$hash_ddl{$data_type_name};
    my @temp=split(/;/, $data_type);
    for my $i(0..$#temp){
        my @temp1=split(/:/, $temp[$i]);
	if ($temp1[1] !~ /int|serial|float|smallint|integer|bigint|decimal|numeric|real|bigserial/ ){
            # in case of boolean type, need to replace 0/1 with f/t ?
            if (defined($hash_ref->{$temp1[0]})){
              my $value=$hash_ref->{$temp1[0]};
              my @array_value=split(/\|/, $value);
              for my $j(0..$#array_value){
		if ($temp1[1]=~/boolean/ && $array_value[$j] !~ /^'$'/ && defined $hash_boolean{$array_value[$j]}){
                   $array_value[$j]="\'".$hash_boolean{$array_value[$j]}."\'";
                }
                elsif ($array_value[$j] !~ /^'$'/){
                   $array_value[$j]="\'".$array_value[$j]."\'";
		}
	      }
             #resemble the value
              my $new_value;
	      for my $j(0..$#array_value){
		if (defined $new_value){
                   $new_value=$new_value."\|".$array_value[$j];
		}
                else {
                   $new_value=$array_value[$j];
                }
	      }
              $hash_ref->{$temp1[0]}=$new_value;
            }
       	}
    }

   return $hash_ref;
}


1;
