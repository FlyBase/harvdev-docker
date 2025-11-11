create table prediction_evidence (
   prediction_evidence_id varchar(50) not null,
   primary key (prediction_evidence_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   evidence_id int not null,
   foreign key (evidence_id) references feature (feature_id),
   analysis_id int not null,
   foreign key (analysis_id) references analysis (analysis_id),
   unique (feature_id, evidence_id, analysis_id)
);

create table alignment_evidence (
   alignment_evidence_id varchar(50) not null,
   primary key (alignment_evidence_id), 
   feature_id int not null,
   foreign key (feature_id) references feature (feature_id),
   evidence_id int not null,
   foreign key (evidence_id) references feature (feature_id),
   analysis_id int not null,
   foreign key (analysis_id) references analysis (analysis_id),
   unique (feature_id, evidence_id, analysis_id)
);


create table _appdata (
  _appdata_id not null,
  primary key (_appdata_id), 
);

create table featureslice (
       featureslice_id serial not null,
       primary key (featureslice_id),
       feature_id int not null,
       foreign key (feature_id) references feature (feature_id) on delete cascade,
       srcfeature_id int,
       foreign key (srcfeature_id) references feature (feature_id) on delete set null,
       fmin int,
       is_fmin_partial boolean not null default 'false',
       fmax int,
       is_fmax_partial boolean not null default 'false',
       strand smallint,
       phase int,
       residue_info text,
       locgroup int not null default 0,
       rank     int not null default 0,
       unique (feature_id, locgroup, rank)
);