
     
create table tableinfo (
     tableinfo_id serial not null,
     primary key (tableinfo_id),
     name varchar(30) not null,
     is_view int not null default 0,
     view_on_table_id int null,
     superclass_table_id int null,
     is_updateable int not null default 1,
     modification_date date not null default now(),
     constraint tableinfo_c1 unique (name)
);
     
create table contact (
     contact_id serial not null,
     primary key (contact_id),
     name varchar(30) not null,
     description varchar(255) null,
     constraint contact_c1 unique (name)
);
     
     
create table db (
     db_id serial not null,
     primary key (db_id),
     name varchar(255) not null,
     contact_id int,
     foreign key (contact_id) references contact (contact_id) on delete cascade INITIALLY DEFERRED,
     description varchar(255) null,
     urlprefix varchar(255) null,
     url varchar(255) null,
     constraint db_c1 unique (name)
);
     
     
create table dbxref (
     dbxref_id serial not null,
     primary key (dbxref_id),
     db_id int not null,
     foreign key (db_id) references db (db_id) on delete cascade INITIALLY DEFERRED,
     accession varchar(255) not null,
     version varchar(255) not null default '',
     description text,
     constraint dbxref_c1 unique (db_id,accession,version)
);
     
create table project (
     project_id serial not null,  
     primary key (project_id),
     name varchar(255) not null,
     description varchar(255) not null,
     constraint project_c1 unique (name)
);
     
     
create table cv (
     cv_id serial not null,
     primary key (cv_id),
     name varchar(255) not null,
     definition text,
     constraint cv_c1 unique (name)
);
     
     
     
create table cvterm (
     cvterm_id serial not null,
     primary key (cvterm_id),
     cv_id int not null,
     foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
     name varchar(1024) not null,
     definition text,
     dbxref_id int,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
     is_obsolete int not null default 0,
     is_relationshiptype int not null default 0,
     constraint cvterm_c1 unique (name,cv_id,is_obsolete),
     constraint cvterm_c2 unique (dbxref_id)
);
     
     
create table cvterm_relationship (
     cvterm_relationship_id serial not null,
     primary key (cvterm_relationship_id),
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     subject_id int not null,
     foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     object_id int not null,
     foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     constraint cvterm_relationship_c1 unique (subject_id,object_id,type_id)
);
     
     
     
create table cvtermpath (
     cvtermpath_id serial not null,
     primary key (cvtermpath_id),
     type_id int,
     foreign key (type_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
     subject_id int not null,
     foreign key (subject_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     object_id int not null,
     foreign key (object_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     cv_id int not null,
     foreign key (cv_id) references cv (cv_id) on delete cascade INITIALLY DEFERRED,
     pathdistance int,
     constraint cvtermpath_c1 unique (subject_id,object_id,type_id,pathdistance)
);
     
     
create table cvtermsynonym (
     cvtermsynonym_id serial not null,
     primary key (cvtermsynonym_id),
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     synonym_desc varchar(1024) not null,
     type_id int,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade  INITIALLY DEFERRED,
     constraint cvtermsynonym_c1 unique (cvterm_id,synonym_desc)
);
     
     
create table cvterm_dbxref (
     cvterm_dbxref_id serial not null,
     primary key (cvterm_dbxref_id),
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     dbxref_id int not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     is_for_definition int not null default 0,
     constraint cvterm_dbxref_c1 unique (cvterm_id,dbxref_id)
);
     
     
create table cvtermprop ( 
     cvtermprop_id serial not null, 
     primary key (cvtermprop_id), 
     cvterm_id int not null, 
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade, 
     type_id int not null, 
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade, 
     value text not null default '', 
     rank int not null default 0,
     unique(cvterm_id, type_id, value, rank) 
);
     
     
create table dbxrefprop (
     dbxrefprop_id serial not null,
     primary key (dbxrefprop_id),
     dbxref_id int not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) INITIALLY DEFERRED,
     value text not null default '',
     rank int not null default 0,
     constraint dbxrefprop_c1 unique (dbxref_id,type_id,rank)
);
     
     
create table organism (
     organism_id serial not null,
     primary key (organism_id),
     abbreviation varchar(255) null,
     genus varchar(255) not null,
     species varchar(255) not null,
     common_name varchar(255) null,
     comment text null,
     constraint organism_c1 unique (genus,species)
);
     
     
     
create table organism_dbxref (
     organism_dbxref_id serial not null,
     primary key (organism_dbxref_id),
     organism_id int not null,
     foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
     dbxref_id int not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     constraint organism_dbxref_c1 unique (organism_id,dbxref_id)
);
     
     
create table organismprop (
     organismprop_id serial not null,
     primary key (organismprop_id),
     organism_id int not null,
     foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     value text null,
     rank int not null default 0,
     constraint organismprop_c1 unique (organism_id,type_id,rank)
);
     
     
create table pub (
     pub_id serial not null,
     primary key (pub_id),
     title text,
     volumetitle text,
     volume varchar(255),
     series_name varchar(255),
     issue varchar(255),
     pyear varchar(255),
     pages varchar(255),
     miniref varchar(255),
     uniquename text not null,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     is_obsolete boolean default 'false',
     publisher varchar(255),
     pubplace varchar(255),
     constraint pub_c1 unique (uniquename)
);
     
     
create table pub_relationship (
     pub_relationship_id serial not null,
     primary key (pub_relationship_id),
     subject_id int not null,
     foreign key (subject_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     object_id int not null,
     foreign key (object_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     constraint pub_relationship_c1 unique (subject_id,object_id,type_id)
);
     
     
create table pub_dbxref (
     pub_dbxref_id serial not null,
     primary key (pub_dbxref_id),
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     dbxref_id int not null,
     is_current boolean not null default 'true',
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     constraint pub_dbxref_c1 unique (pub_id,dbxref_id)
);
     
     
create table pubauthor (
     pubauthor_id serial not null,
     primary key (pubauthor_id),
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     rank int not null,
     editor boolean default 'false',
     surname varchar(100) not null,
     givennames varchar(100),
     suffix varchar(100),
     constraint pubauthor_c1 unique (pub_id, rank)
);
     
     
create table pubprop (
     pubprop_id serial not null,
     primary key (pubprop_id),
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     value text not null,
     rank integer,
     constraint pubprop_c1 unique (pub_id,type_id,rank)
);
     
     
create table feature (
     feature_id serial not null,
     primary key (feature_id),
     dbxref_id int,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
     organism_id int not null,
     foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
     name varchar(255),
     uniquename text not null,
     residues text,
     seqlen int,
     md5checksum varchar(32),
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     is_analysis boolean not null default 'false',
     is_obsolete boolean not null default 'false',
     timeaccessioned timestamp not null default current_timestamp,
     timelastmodified timestamp not null default current_timestamp,
     constraint feature_c1 unique (organism_id,uniquename,type_id)
);
     
     
create table featureloc (
     featureloc_id serial not null,
     primary key (featureloc_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     srcfeature_id int,
     foreign key (srcfeature_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
     fmin int,
     is_fmin_partial boolean not null default 'false',
     fmax int,
     is_fmax_partial boolean not null default 'false',
     strand smallint,
     phase int,
     residue_info text,
     locgroup int not null default 0,
     rank int not null default 0,
     constraint featureloc_c1 unique (feature_id,locgroup,rank),
     constraint featureloc_c2 check (fmin <= fmax)
);
     
     
create table feature_pub (
     feature_pub_id serial not null,
     primary key (feature_pub_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint feature_pub_c1 unique (feature_id,pub_id)
);
     
create table featureloc_pub (
    featureloc_pub_id serial NOT NULL,
    primary key (featureloc_pub_id),
    featureloc_id int NOT NULL,
    foreign key (featureloc_id) references featureloc (featureloc_id) on delete cascade INITIALLY DEFERRED,
    pub_id int NOT NULL,
    foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
    constraint featureloc_pub_c1 unique (featureloc_id, pub_id)
);
     
create table featureprop (
     featureprop_id serial not null,
     primary key (featureprop_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     value text null,
     rank int not null default 0,
     constraint featureprop_c1 unique (feature_id,type_id,rank)
);
     
     
create table featureprop_pub (
     featureprop_pub_id serial not null,
     primary key (featureprop_pub_id),
     featureprop_id int not null,
     foreign key (featureprop_id) references featureprop (featureprop_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint featureprop_pub_c1 unique (featureprop_id,pub_id)
);
     
     
create table feature_dbxref (
     feature_dbxref_id serial not null,
     primary key (feature_dbxref_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     dbxref_id int not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     is_current boolean not null default 'true',
     constraint feature_dbxref_c1 unique (feature_id,dbxref_id)
);
     
     
create table feature_relationship (
     feature_relationship_id serial not null,
     primary key (feature_relationship_id),
     subject_id int not null,
     foreign key (subject_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     object_id int not null,
     foreign key (object_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     value text null,
     rank int not null default 0,
     constraint feature_relationship_c1 unique (subject_id,object_id,type_id,rank)
);
     
     
create table feature_relationship_pub (
     feature_relationship_pub_id serial not null,
     primary key (feature_relationship_pub_id),
     feature_relationship_id int not null,
     foreign key (feature_relationship_id) references feature_relationship (feature_relationship_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint feature_relationship_pub_c1 unique (feature_relationship_id,pub_id)
);
     
     
create table feature_relationshipprop (
     feature_relationshipprop_id serial not null,
     primary key (feature_relationshipprop_id),
     feature_relationship_id int not null,
     foreign key (feature_relationship_id) references feature_relationship (feature_relationship_id) on delete cascade,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     value text null,
     rank int not null default 0,
     constraint feature_relationshipprop_c1 unique (feature_relationship_id,type_id,rank)
);
     
     
create table feature_relationshipprop_pub (
     feature_relationshipprop_pub_id serial not null,
     primary key (feature_relationshipprop_pub_id),
     feature_relationshipprop_id int not null,
     foreign key (feature_relationshipprop_id) references feature_relationshipprop (feature_relationshipprop_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint feature_relationshipprop_pub_c1 unique (feature_relationshipprop_id,pub_id)
);
     
     
create table feature_cvterm (
     feature_cvterm_id serial not null,
     primary key (feature_cvterm_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     is_not  boolean not null default 'false',
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint feature_cvterm_c1 unique (feature_id,cvterm_id,pub_id)
);
     
     
create table feature_cvtermprop (
     feature_cvtermprop_id serial not null,
     primary key (feature_cvtermprop_id),
     feature_cvterm_id int not null,
     foreign key (feature_cvterm_id) references feature_cvterm (feature_cvterm_id) on delete cascade,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     value text null,
     rank int not null default 0,
     constraint feature_cvtermprop_c1 unique (feature_cvterm_id,type_id,rank)
);
     
     
create table feature_cvterm_dbxref (
     feature_cvterm_dbxref_id serial not null,
     primary key (feature_cvterm_dbxref_id),
     feature_cvterm_id int not null,
     foreign key (feature_cvterm_id) references feature_cvterm (feature_cvterm_id) on delete cascade,
     dbxref_id int not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     constraint feature_cvterm_dbxref_c1 unique (feature_cvterm_id,dbxref_id)
);
     
     
create table synonym (
     synonym_id serial not null,
     primary key (synonym_id),
     name varchar(255) not null,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     synonym_sgml varchar(255) not null,
     constraint synonym_c1 unique (name,type_id,synonym_sgml)
);
     
     
create table feature_synonym (
     feature_synonym_id serial not null,
     primary key (feature_synonym_id),
     synonym_id int not null,
     foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     is_current boolean not null default 'true',
     is_internal boolean not null default 'false',
     constraint feature_synonym_c1 unique (synonym_id,feature_id,pub_id)
);
     
create table genotype (
     genotype_id serial not null,
     primary key (genotype_id),
     uniquename text not null,      
     description varchar(255),
     constraint genotype_c1 unique (uniquename)
);
     
create table feature_genotype (
     feature_genotype_id serial not null,
     primary key (feature_genotype_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade,
     genotype_id int not null,
     foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
     chromosome_id int,
     foreign key (chromosome_id) references feature (feature_id) on delete set null,
     rank int not null,
     cgroup     int not null,
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
     constraint feature_genotype_c1 unique (feature_id, genotype_id, cvterm_id, chromosome_id, rank, cgroup)
);
     
create table environment (
     environment_id serial not NULL,
     primary key  (environment_id),
     uniquename text not null,
     description text,
     constraint environment_c1 unique (uniquename)
);
     
create table environment_cvterm (
     environment_cvterm_id serial not null,
     primary key  (environment_cvterm_id),
     environment_id int not null,
     foreign key (environment_id) references environment (environment_id) on delete cascade,
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
     constraint environment_cvterm_c1 unique (environment_id, cvterm_id)
);
     
create table phenotype (
     phenotype_id serial not null,
     primary key (phenotype_id),
     uniquename text not null,  
     observable_id int,
     foreign key (observable_id) references cvterm (cvterm_id) on delete cascade,
     attr_id int,
     foreign key (attr_id) references cvterm (cvterm_id) on delete set null,
     value text,
     cvalue_id int,
     foreign key (cvalue_id) references cvterm (cvterm_id) on delete set null,
     assay_id int,
     foreign key (assay_id) references cvterm (cvterm_id) on delete set null,
     constraint phenotype_c1 unique (uniquename)
);
     
create table phenotype_cvterm (
     phenotype_cvterm_id serial not null,
     primary key (phenotype_cvterm_id),
     phenotype_id int not null,
     foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
     cvterm_id int not null,
     rank int not null default 0,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
     constraint phenotype_cvterm_c1 unique (phenotype_id, cvterm_id, rank)
);
     
     
create table phenstatement (
     phenstatement_id serial not null,
     primary key (phenstatement_id),
     genotype_id int not null,
     foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
     environment_id int not null,
     foreign key (environment_id) references environment (environment_id) on delete cascade,
     phenotype_id int not null,
     foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade,
     constraint phenstatement_c1 unique (genotype_id,phenotype_id,environment_id,type_id,pub_id)
);
     
create table feature_phenotype (
     feature_phenotype_id serial not null,
     primary key (feature_phenotype_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade,
     phenotype_id int not null,
     foreign key (phenotype_id) references phenotype (phenotype_id) on delete cascade,
     constraint feature_phenotype_c1 unique (feature_id,phenotype_id)       
);
     
create table phendesc (
     phendesc_id serial not null,
     primary key (phendesc_id),
     genotype_id int not null,
     foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
     environment_id int not null,
     foreign key (environment_id) references environment ( environment_id) on delete cascade,
     description text not null,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade,
     constraint phendesc_c1 unique (genotype_id,environment_id,pub_id)
);
     
create table phenotype_comparison (
     phenotype_comparison_id serial not null,
     primary key (phenotype_comparison_id),
     genotype1_id int not null,
     foreign key (genotype1_id) references genotype (genotype_id) on delete cascade,
     environment1_id int not null,
     foreign key (environment1_id) references environment (environment_id) on delete cascade,
     genotype2_id int not null,
     foreign key (genotype2_id) references genotype (genotype_id) on delete cascade,
     environment2_id int not null,
     foreign key (environment2_id) references environment (environment_id) on delete cascade,
     phenotype1_id int not null,
     foreign key (phenotype1_id) references phenotype (phenotype_id) on delete cascade,
     phenotype2_id int,
     foreign key (phenotype2_id) references phenotype (phenotype_id) on delete cascade,
     organism_id int not null,
     foreign key (organism_id) references organism (organism_id) on delete cascade,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade,
     constraint phenotype_comparison_c1 unique (genotype1_id,environment1_id,genotype2_id,environment2_id,phenotype1_id,pub_id)
);
     
create table phenotype_comparison_cvterm (
	phenotype_comparison_cvterm_id serial not null,
	primary key (phenotype_comparison_cvterm_id),
	phenotype_comparison_id int not null,
	foreign key (phenotype_comparison_id) references phenotype_comparison (phenotype_comparison_id) on delete cascade,
	cvterm_id int not null,
	foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade,
	rank int not null default 0,
	constraint phenotype_comparison_cvterm_c1 unique (phenotype_comparison_id, cvterm_id)
);   
     
create table analysis (
     analysis_id serial not null,
     primary key (analysis_id),
     name varchar(255),
     description text,
     program varchar(255) not null,
     programversion varchar(255) not null,
     algorithm varchar(255),
     sourcename varchar(255),
     sourceversion varchar(255),
     sourceuri text,
     timeexecuted timestamp not null default current_timestamp,
     constraint analysis_c1 unique (program,programversion,sourcename)
);
     
     
     
create table analysisprop (
     analysisprop_id serial not null,
     primary key (analysisprop_id),
     analysis_id int not null,
     foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     value text,
     constraint analysisprop_c1 unique (analysis_id,type_id,value)
);
     
     
     
create table analysisfeature (
     analysisfeature_id serial not null,
     primary key (analysisfeature_id),
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     analysis_id int not null,
     foreign key (analysis_id) references analysis (analysis_id) on delete cascade INITIALLY DEFERRED,
     rawscore double precision,
     normscore double precision,
     significance double precision,
     identity double precision,
     constraint analysisfeature_c1 unique (feature_id,analysis_id)
);
     
     
create table expression (
     expression_id serial not null,
     primary key (expression_id),
     description text
);
     
     
     
create table feature_expression (
     feature_expression_id serial not null,
     primary key (feature_expression_id),
     expression_id int not null,
     foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     unique(expression_id,feature_id)       
);
     
create table expression_cvterm (
     expression_cvterm_id serial not null,
     primary key (expression_cvterm_id),
     expression_id int not null,
     foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     rank int not null,
     cvterm_type varchar(255),
     
     unique(expression_id,cvterm_id)
);
     
     
create table expression_pub (
     expression_pub_id serial not null,
     primary key (expression_pub_id),
     expression_id int not null,
     foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     unique(expression_id,pub_id)       
);
     
     
create table eimage (
     eimage_id serial not null,
     primary key (eimage_id),
     eimage_data text,
     eimage_type varchar(255) not null,
     image_uri varchar(255)
);
     
     
create table expression_image (
     expression_image_id serial not null,
     primary key (expression_image_id),
     expression_id int not null,
     foreign key (expression_id) references expression (expression_id) on delete cascade INITIALLY DEFERRED,
     eimage_id int not null,
     foreign key (eimage_id) references eimage (eimage_id) on delete cascade INITIALLY DEFERRED,
     unique(expression_id,eimage_id)
);
     
     
create table featuremap (
     featuremap_id serial not null,
     primary key (featuremap_id),
     name varchar(255),
     description text,
     unittype_id int null,
     foreign key (unittype_id) references cvterm (cvterm_id) on delete set null INITIALLY DEFERRED,
     constraint featuremap_c1 unique (name)
);
     
     
     
create table featurerange (
     featurerange_id serial not null,
     primary key (featurerange_id),
     featuremap_id int not null,
     foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     leftstartf_id int not null,
     foreign key (leftstartf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     leftendf_id int,
     foreign key (leftendf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
     rightstartf_id int,
     foreign key (rightstartf_id) references feature (feature_id) on delete set null INITIALLY DEFERRED,
     rightendf_id int not null,
     foreign key (rightendf_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     rangestr varchar(255)
);
     
     
create table featurepos (
     featurepos_id serial not null,
     primary key (featurepos_id),
     featuremap_id serial not null,
     foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     map_feature_id int not null,
     foreign key (map_feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     mappos float not null
);
     
     
create table featuremap_pub (
     featuremap_pub_id serial not null,
     primary key (featuremap_pub_id),
     featuremap_id int not null,
     foreign key (featuremap_id) references featuremap (featuremap_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED
);
     
     
create table library (
     library_id serial not null,
     primary key (library_id),
     organism_id int not null,
     foreign key (organism_id) references organism (organism_id),
     name varchar(255),
     uniquename text not null,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id),
     constraint library_c1 unique (organism_id,uniquename,type_id)
);
     
     
create table library_synonym (
     library_synonym_id serial not null,
     primary key (library_synonym_id),
     synonym_id int not null,
     foreign key (synonym_id) references synonym (synonym_id) on delete cascade INITIALLY DEFERRED,
     library_id int not null,
     foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     is_current boolean not null default 'true',
     is_internal boolean not null default 'false',
     constraint library_synonym_c1 unique (synonym_id,library_id,pub_id)
);
     
     
create table library_pub (
     library_pub_id serial not null,
     primary key (library_pub_id),
     library_id int not null,
     foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint library_pub_c1 unique (library_id,pub_id)
);
     
     
create table libraryprop (
     libraryprop_id serial not null,
     primary key (libraryprop_id),
     library_id int not null,
     foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
     type_id int not null,
     foreign key (type_id) references cvterm (cvterm_id),
     value text null,
     rank int not null default 0,
     constraint libraryprop_c1 unique (library_id,type_id,rank)
);
     
     
create table library_cvterm (
     library_cvterm_id serial not null,
     primary key (library_cvterm_id),
     library_id int not null,
     foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id),
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id),
     constraint library_cvterm_c1 unique (library_id,cvterm_id,pub_id)
);
     
     
create table library_feature (
     library_feature_id serial not null,
     primary key (library_feature_id),
     library_id int not null,
     foreign key (library_id) references library (library_id) on delete cascade INITIALLY DEFERRED,
     feature_id int not null,
     foreign key (feature_id) references feature (feature_id) on delete cascade INITIALLY DEFERRED,
     constraint library_feature_c1 unique (library_id,feature_id)
);

create table stock (
       stock_id serial not null,
       primary key (stock_id),
       dbxref_id int,
       foreign key (dbxref_id) references dbxref (dbxref_id) on delete set null INITIALLY DEFERRED,
       organism_id int not null,
       foreign key (organism_id) references organism (organism_id) on delete cascade INITIALLY DEFERRED,
       name varchar(255),
       uniquename text not null,
       description text,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       is_obsolete boolean not null default 'false',
       constraint stock_c1 unique (organism_id,uniquename,type_id)
);


create table stock_pub (
       stock_pub_id serial not null,
       primary key (stock_pub_id),
       stock_id int not null,
       foreign key (stock_id) references stock (stock_id)  on delete cascade INITIALLY DEFERRED,
       pub_id int not null,
       foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
       constraint stock_pub_c1 unique (stock_id,pub_id)
);

create table stockprop (
       stockprop_id serial not null,
       primary key (stockprop_id),
       stock_id int not null,
       foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       constraint stockprop_c1 unique (stock_id,type_id,rank)
);


create table stockprop_pub (
     stockprop_pub_id serial not null,
     primary key (stockprop_pub_id),
     stockprop_id int not null,
     foreign key (stockprop_id) references stockprop (stockprop_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint stockprop_pub_c1 unique (stockprop_id,pub_id)
);


create table stock_relationship (
       stock_relationship_id serial not null,
       primary key (stock_relationship_id),
       subject_id int not null,
       foreign key (subject_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       object_id int not null,
       foreign key (object_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
       type_id int not null,
       foreign key (type_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
       value text null,
       rank int not null default 0,
       constraint stock_relationship_c1 unique (subject_id,object_id,type_id,rank)
);


create table stock_relationship_pub (
      stock_relationship_pub_id serial not null,
      primary key (stock_relationship_pub_id),
      stock_relationship_id int not null,
      foreign key (stock_relationship_id) references stock_relationship (stock_relationship_id) on delete cascade INITIALLY DEFERRED,
      pub_id int not null,
      foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
      constraint stock_relationship_pub_c1 unique (stock_relationship_id,pub_id)
);

create table stock_dbxref (
     stock_dbxref_id serial not null,
     primary key (stock_dbxref_id),
     stock_id int not null,
     foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
     dbxref_id int not null,
     foreign key (dbxref_id) references dbxref (dbxref_id) on delete cascade INITIALLY DEFERRED,
     is_current boolean not null default 'true',
     constraint stock_dbxref_c1 unique (stock_id,dbxref_id)
);

create table stock_cvterm (
     stock_cvterm_id serial not null,
     primary key (stock_cvterm_id),
     stock_id int not null,
     foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
     cvterm_id int not null,
     foreign key (cvterm_id) references cvterm (cvterm_id) on delete cascade INITIALLY DEFERRED,
     pub_id int not null,
     foreign key (pub_id) references pub (pub_id) on delete cascade INITIALLY DEFERRED,
     constraint stock_cvterm_c1 unique (stock_id,cvterm_id,pub_id)
);

create table stock_genotype (
       stock_genotype_id serial not null,
       primary key (stock_genotype_id),
       stock_id int not null,
       foreign key (stock_id) references stock (stock_id) on delete cascade,
       genotype_id int not null,
       foreign key (genotype_id) references genotype (genotype_id) on delete cascade,
       constraint stock_genotype_c1 unique (stock_id, genotype_id)
);

create table stockcollection (
	stockcollection_id serial not null, 
        primary key (stockcollection_id),
	type_id int not null,
        foreign key (type_id) references cvterm (cvterm_id) on delete cascade,
        contact_id int null,
        foreign key (contact_id) references contact (contact_id) on delete set null INITIALLY DEFERRED,
	name varchar(255),
	uniquename text not null,
	constraint stockcollection_c1 unique (uniquename,type_id)
);

create table stockcollectionprop (
    stockcollectionprop_id serial not null,
    primary key (stockcollectionprop_id),
    stockcollection_id int not null,
    foreign key (stockcollection_id) references stockcollection (stockcollection_id) on delete cascade INITIALLY DEFERRED,
    type_id int not null,
    foreign key (type_id) references cvterm (cvterm_id),
    value text null,
    rank int not null default 0,
    constraint stockcollectionprop_c1 unique (stockcollection_id,type_id,rank)
);

create table stockcollection_stock (
    stockcollection_stock_id serial not null,
    primary key (stockcollection_stock_id),
    stockcollection_id int not null,
    foreign key (stockcollection_id) references stockcollection (stockcollection_id) on delete cascade INITIALLY DEFERRED,
    stock_id int not null,
    foreign key (stock_id) references stock (stock_id) on delete cascade INITIALLY DEFERRED,
    constraint stockcollection_stock_c1 unique (stockcollection_id,stock_id)
);
