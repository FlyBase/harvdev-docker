drop trigger feature_assignname_tr_i on feature;
create or replace function feature_assignname_fn_i() RETURNS TRIGGER AS '
DECLARE
  maxid      int;
  maxid_temp int;
  pos        int;
  id         varchar(255);
  maxid_fb   int;
  id_fb      varchar(255);
  message   varchar(255);
  exon_id int;
  f_row_g feature%ROWTYPE;
  f_row_e feature%ROWTYPE;
  f_row_t feature%ROWTYPE;
  f_row_p feature%ROWTYPE;
  f_type  cvterm.name%TYPE;
  f_type_id cvterm.cvterm_id%TYPE;
  letter_t varchar;
  letter_p varchar;
  d_id    db.db_id%TYPE;
  f_dbxref_id feature.dbxref_id%TYPE;
  f_dbxref_id_temp feature.dbxref_id%TYPE;
  fb_accession dbxref.accession%TYPE;
  d_accession dbxref.accession%TYPE;
  f_uniquename_temp feature.uniquename%TYPE;
  f_uniquename feature.uniquename%TYPE;
  f_uniquename_tr feature.uniquename%TYPE;
  f_uniquename_exon feature.uniquename%TYPE;
  f_uniquename_protein feature.uniquename%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  p_id                 pub.pub_id%TYPE;
  p_type_id            cvterm.cvterm_id%TYPE;
  c_cv_id              cv.cv_id%TYPE;
  f_s_id               feature_synonym.feature_synonym_id%TYPE;
  f_d_id               feature_dbxref.feature_dbxref_id%TYPE;
  fr_row feature_relationship%ROWTYPE;
  f_type_gene CONSTANT varchar :=''gene'';
  f_type_exon CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_snoRNA CONSTANT varchar :=''snoRNA'';
  f_type_ncRNA CONSTANT varchar :=''ncRNA'';
  f_type_snRNA CONSTANT varchar :=''snRNA'';
  f_type_tRNA CONSTANT varchar :=''tRNA'';
  f_type_rRNA CONSTANT varchar :=''rRNA'';
  f_type_miRNA CONSTANT varchar :=''miRNA'';
  f_type_pseudo CONSTANT varchar :=''pseudogene'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''alleleof'';
  f_type_remark CONSTANT varchar :=''remark'';
  f_dbname_gadfly CONSTANT varchar :=''Gadfly'';
  f_dbname_FB CONSTANT varchar :=''FlyBase'';
  o_genus  CONSTANT varchar :=''Drosophila'';
  o_species  CONSTANT varchar:=''melanogaster'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''synonym type'';
  p_miniref         CONSTANT varchar:=''gadfly3'';
  p_cvterm_name     CONSTANT varchar:=''computer file'';
  p_cv_name         CONSTANT varchar:=''pub type'';
BEGIN
  RAISE NOTICE ''enter f_i: feature.uniquename:%, feature.type_id:%'', NEW.uniquename, NEW.type_id;
  IF (NEW.uniquename like ''CG:temp%'' or NEW.uniquename like ''CR:temp%'') and  NEW.uniquename not like ''%-%''  THEN
      SELECT INTO f_type c.name from feature f, cvterm c, organism o where f.type_id=c.cvterm_id and f.uniquename=NEW.uniquename and f.organism_id =NEW.organism_id;
      IF f_type is NOT NULL THEN
        RAISE NOTICE ''in feature_assignname_fn_i type of this feature is:%'', f_type;
      END IF;
      IF f_type=f_type_gene THEN
          RAISE NOTICE ''in f_i, feature type is:%'', f_type;
          SELECT INTO f_row_g * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;
          IF f_row_g.uniquename like ''CG%'' THEN
               SELECT INTO maxid to_number(max(substring(accession from 3 for 7)), ''99999'') from dbxref dx, db d  where dx.db_id=d.db_id and  d.name=f_dbname_gadfly and accession like ''C_3____'' and accession not like ''%:%'' and accession not like ''%-%'';
               RAISE NOTICE ''in f_i, maxid before is:%'', maxid;
               IF maxid IS NULL THEN
                   maxid:=1;
               ELSE
                   maxid:=maxid+1;
               END IF;
               RAISE NOTICE ''maxid after is:%'', maxid;
               id:=lpad(maxid, 5, ''00000'');
               f_uniquename:=CAST(''CG''||id as TEXT);
          ELSIF f_row_g.uniquename like ''CR%'' THEN
               SELECT INTO maxid to_number(max(substring(accession from 3 for 7)), ''99999'') from dbxref dx, db d  where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession like ''C_3____'' and accession not like ''%:%'' and accession not like ''%-%'';
               IF maxid IS NULL THEN
                   maxid:=1;
               ELSE
                   maxid:=maxid+1;
               END IF;
               id:=lpad(maxid, 5, ''00000'');
               f_uniquename:=CAST(''CR''||id as TEXT);
          END IF;
          maxid_fb:=maxid+20000;
          SELECT INTO d_id db_id from db where name= f_dbname_gadfly;
          RAISE NOTICE ''db_id:%, uniquename:%, f_dbname_gadfly:%:'', d_id, f_uniquename, f_dbname_gadfly; 
               SELECT INTO f_dbxref_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename;
               if f_dbxref_id IS NULL THEN 
                 INSERT INTO dbxref (db_id, accession) values(d_id, f_uniquename);
                 SELECT INTO f_dbxref_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename;
               END IF;
               RAISE NOTICE ''dbxref_id:%'', f_dbxref_id;
               IF NEW.name like ''%temp%'' or NEW.name like ''CG%%'' or NEW.name like ''CR%%'' or NEW.name IS NULL  THEN
                   UPDATE feature set uniquename=f_uniquename, dbxref_id=f_dbxref_id, name=f_uniquename where feature_id=f_row_g.feature_id;
               ELSE
                   UPDATE feature set uniquename=f_uniquename, dbxref_id=f_dbxref_id where feature_id=f_row_g.feature_id;
               END IF;
               RAISE NOTICE ''old uniquename of this feature is:%'', f_row_g.uniquename;
               RAISE NOTICE ''new uniquename of this feature is:%'', f_uniquename;
               message:=CAST(''old uniquename:''||f_row_g.uniquename||'' new uniquename:''||f_uniquename AS TEXT);
               RAISE NOTICE ''message:%, f_row_g.feature_id:%, f_dbxref_id:%'', message, f_row_g.feature_id, f_dbxref_id;
               SELECT INTO f_d_id feature_dbxref_id from feature_dbxref where feature_id=f_row_g.feature_id and dbxref_id=f_dbxref_id;
               IF f_d_id IS NULL THEN
                 INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(f_row_g.feature_id, f_dbxref_id, ''false'');
               END IF;
               SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
               SELECT INTO s_id synonym_id from synonym where name=f_uniquename and type_id=s_type_id;
               IF s_id IS NULL THEN
                 INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename, f_uniquename, s_type_id);
                 SELECT INTO s_id synonym_id from synonym where name=f_uniquename and type_id=s_type_id;
               END IF;
               SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
               IF p_id IS NULL THEN
                 SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
                 IF p_type_id IS NULL THEN
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    IF c_cv_id IS NULL THEN
                        INSERT INTO cv(name) values(p_cv_name);
                        SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    END IF;
                    INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 END IF;
                 INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
                 SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
               END IF;
               SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_g.feature_id and synonym_id=s_id and pub_id=p_id;
               IF f_s_id IS NULL THEN
                  INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_g.feature_id, s_id, p_id, ''true'');
               END IF;
               RAISE NOTICE ''feature_id:%, synonym_id:%, pub_id:%'', f_row_g.feature_id, s_id, p_id;
              id_fb:=lpad(maxid_fb, 7, ''0000000'');
              fb_accession:=CAST(''FBgn''||id_fb AS TEXT);
              RAISE NOTICE ''fb_accession is:%'', fb_accession;
              SELECT INTO d_id db_id from db where name=f_dbname_FB;
              INSERT INTO dbxref(db_id, accession) values(d_id, fb_accession);
              SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
              INSERT INTO feature_dbxref(feature_id, dbxref_id) values(f_row_g.feature_id, f_dbxref_id);   
              RAISE NOTICE ''FBgn for feature:% is:%'', fb_accession, f_uniquename;
              message:=CAST(''FBgn:''||fb_accession||''for feature:''||f_uniquename AS TEXT);          
      END IF;
  END IF; 
  IF ((NEW.uniquename like ''CG%'' or NEW.uniquename like ''CR%'') and  (NEW.uniquename not like ''CG:temp%'' and  NEW.uniquename not like ''CR:temp%'') and  (NEW.uniquename like ''%-R%'' or NEW.uniquename like ''%-P%'' or NEW.uniquename like ''%:temp%'' ))  THEN
      SELECT INTO f_type c.name from feature f, cvterm c, organism o where f.type_id=c.cvterm_id and f.uniquename=NEW.uniquename and f.organism_id =NEW.organism_id;
      IF f_type is NOT NULL THEN
        RAISE NOTICE ''in f_i, type of this feature is:%'', f_type;
      END IF;
      IF (f_type=f_type_transcript or f_type=f_type_ncRNA or f_type=f_type_snoRNA or f_type=f_type_snRNA or f_type=f_type_tRNA or f_type=f_type_rRNA or f_type=f_type_pseudo or f_type=f_type_miRNA) THEN
          SELECT INTO f_row_t * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;
            IF f_row_t.dbxref_id IS  NULL THEN  
               RAISE NOTICE ''dbxref_id for this feature is null, NEW.uniquename:%'',NEW.uniquename;
               SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=NEW.uniquename;
               IF f_dbxref_id IS NULL THEN 
                  SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
                  INSERT INTO dbxref(db_id, accession ) values(d_id, NEW.uniquename);
                  SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=NEW.uniquename;
               END IF;
               IF f_row_t.name like ''%temp%'' or f_row_t.name IS NULL THEN
                 UPDATE feature set dbxref_id=f_dbxref_id, name=NEW.uniquename where feature_id=f_row_t.feature_id;
               ELSE
                 UPDATE feature set dbxref_id=f_dbxref_id  where feature_id=f_row_t.feature_id;
               END IF;
            ELSE
               f_dbxref_id:=f_row_t.dbxref_id;
            END IF;
            SELECT INTO f_dbxref_id_temp dbxref_id from feature_dbxref where feature_id=f_row_t.feature_id and dbxref_id=f_row_t.dbxref_id;
            IF f_dbxref_id_temp IS NULL THEN
                  INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(f_row_t.feature_id, f_dbxref_id, ''false'');
            END IF;
            RAISE NOTICE ''old uniquename of this feature is:%, dbxref_id is:%'', f_row_t.uniquename, f_dbxref_id;
            SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
            SELECT INTO s_id synonym_id from synonym where name=NEW.uniquename and type_id=s_type_id;
            IF s_id IS NULL THEN
                  INSERT INTO synonym(name, synonym_sgml, type_id) values(NEW.uniquename, NEW.uniquename, s_type_id);
                  SELECT INTO s_id synonym_id from synonym where name=NEW.uniquename and type_id=s_type_id;
            END IF;
            SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
            IF p_id IS NULL THEN
                 SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
                 IF p_type_id IS NULL THEN
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    IF c_cv_id IS NULL THEN
                        INSERT INTO cv(name) values(p_cv_name);
                        SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    END IF;
                    INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 END IF;
                 INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
                 SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
            END IF;
            SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_t.feature_id and synonym_id=s_id and pub_id=p_id;
            IF f_s_id IS NULL THEN
                 INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_t.feature_id, s_id, p_id, ''true'');
            END IF;
-- should NOT add any FBtr to exist transcripts, only add FBtr to NEW transcripts, which happen in tr_fr_i.sql. otherwise, it will dumplicate
/*           SELECT INTO maxid_fb to_number(substring(max(accession) from 5 for 11),''9999999'') from dbxref dx, db d where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBtr%'';  
           IF maxid_fb IS NULL OR maxid_fb< 70000  THEN
               maxid_fb:=70000;
           ELSE 
               maxid_fb:=maxid_fb+1;
           END IF;
           id_fb:=lpad(maxid_fb, 7, ''0000000'');
           fb_accession:=CAST(''FBtr''||id_fb AS TEXT);
           RAISE NOTICE ''fb_accession is:%'', fb_accession;
           SELECT INTO d_id db_id from db where name=f_dbname_FB;
           INSERT INTO dbxref(db_id, accession) values(d_id, fb_accession);
           SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d  where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
           INSERT INTO feature_dbxref(feature_id, dbxref_id) values(f_row_t.feature_id, f_dbxref_id);   
           RAISE NOTICE ''FBtr for feature:% is:%'', NEW.uniquename, fb_accession;
*/
      END IF;
      IF f_type=f_type_protein THEN
          SELECT INTO f_row_p * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;
            IF f_row_p.dbxref_id IS  NULL THEN  
               SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=NEW.uniquename;
               IF f_dbxref_id IS NULL THEN 
                  SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
                  INSERT INTO dbxref(db_id, accession ) values(d_id, NEW.uniquename);
                  SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d  where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=NEW.uniquename;  
               END IF; 
               IF f_row_p.name like ''%temp%'' or f_row_p.name IS NULL THEN
                  UPDATE feature set dbxref_id=f_dbxref_id, name=NEW.uniquename where feature_id=f_row_p.feature_id;
               ELSE
                  UPDATE feature set dbxref_id=f_dbxref_id where feature_id=f_row_p.feature_id;
               END IF;
            ELSE
               f_dbxref_id:=f_row_p.dbxref_id;
            END IF;
               SELECT INTO f_dbxref_id_temp dbxref_id from feature_dbxref where feature_id=f_row_p.feature_id and dbxref_id=f_row_p.dbxref_id;
               IF f_dbxref_id_temp IS NULL THEN
                  INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(f_row_p.feature_id, f_dbxref_id, ''false'');
               END IF;
               RAISE NOTICE ''old uniquename of this feature is:%'', f_row_p.uniquename; 
               SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
               SELECT INTO s_id synonym_id from synonym where name=NEW.uniquename and type_id=s_type_id;
               IF s_id IS NULL THEN
                  INSERT INTO synonym(name, synonym_sgml, type_id) values(NEW.uniquename, NEW.uniquename, s_type_id);
                  SELECT INTO s_id synonym_id from synonym where name=NEW.uniquename and type_id=s_type_id;
               END IF;
               SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
               IF p_id IS NULL THEN
                 SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
                 IF p_type_id IS NULL THEN
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    IF c_cv_id IS NULL THEN
                        INSERT INTO cv(name) values(p_cv_name);
                        SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    END IF;
                    INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 END IF;
                 INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
                 SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
               END IF;
               SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_p.feature_id and synonym_id=s_id and pub_id=p_id;
               IF f_s_id IS NULL THEN
                  INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_p.feature_id, s_id, p_id, ''true'');
               END IF;

-- Warning: should NOT add any FBpp to exist protein, only add FBpp to NEW protein, which happen in tr_f_u.sql. otherwise, it will dumplicate
/*
           SELECT INTO maxid_fb to_number(substring(max(accession) from 5 for 11),''9999999'') from dbxref dx, db d  where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBpp%'';  
           IF maxid_fb IS NULL OR maxid_fb< 70000  THEN
               maxid_fb:=70000;
           ELSE 
               maxid_fb:=maxid_fb+1;
           END IF;
           id_fb:=lpad(maxid_fb, 7, ''0000000'');
           fb_accession:=CAST(''FBpp''||id_fb AS TEXT);
           RAISE NOTICE ''fb_accession is:%'', fb_accession;
           SELECT INTO d_id db_id from db where name=f_dbname_FB;
           INSERT INTO dbxref(db_id, accession) values(d_id, fb_accession);
           SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
           INSERT INTO feature_dbxref(feature_id, dbxref_id) values(f_row_p.feature_id, f_dbxref_id);   
           RAISE NOTICE ''FBpp for feature:% is:%'', NEW.uniquename, fb_accession;
*/
      END IF;
      IF f_type=f_type_exon THEN
          SELECT INTO f_row_e * from feature where uniquename=NEW.uniquename and organism_id=NEW.organism_id;
          pos:=position('':'' in NEW.uniquename)-1;
          f_uniquename:=substring(NEW.uniquename from 1 for pos);
          RAISE NOTICE ''gene uniquename for this exon:% should be:%'', NEW.uniquename, f_uniquename;
          IF f_uniquename like ''CG_____'' or f_uniquename like ''CG____'' THEN 
             IF pos=7 THEN           
                 select INTO maxid max(to_number(substring(f2.uniquename from 9),''99'')) from feature f1, feature_relationship fr1, feature_relationship fr2, feature f2, cvterm c1 where f1.uniquename=f_uniquename and f1.feature_id=fr1.object_id and fr1.subject_id=fr2.object_id and fr2.subject_id=f2.feature_id and (f2.uniquename like ''CG%:_'' or f2.uniquename like ''CG%:__'') and f2.type_id=c1.cvterm_id and c1.name=f_type_exon;
                 select INTO maxid_temp max(to_number(substring(uniquename from 9),''99'')) from feature where (uniquename like ''CG%:_'' or uniquename like ''CG%:__'') and substring(uniquename from 1 for 7)=f_uniquename;
             ELSIF pos=6 THEN
                 select INTO maxid max(to_number(substring(f2.uniquename from 8),''99'')) from feature f1, feature_relationship fr1, feature_relationship fr2, feature f2, cvterm c1 where f1.uniquename=f_uniquename and f1.feature_id=fr1.object_id and fr1.subject_id=fr2.object_id and fr2.subject_id=f2.feature_id and (f2.uniquename like ''CG%:_'' or f2.uniquename like ''CG%:__'') and f2.type_id=c1.cvterm_id and c1.name=f_type_exon;
                 select INTO maxid_temp max(to_number(substring(uniquename from 8),''99'')) from feature where (uniquename like ''CG%:_'' or uniquename like ''CG%:__'') and substring(uniquename from 1 for 6)=f_uniquename;
             END IF;
          ELSIF  f_uniquename like ''CR_____'' or f_uniquename like ''CR____'' THEN
             IF pos=7 THEN
                select INTO maxid max(to_number(substring(uniquename from 8),''99'')) from feature f1, feature_relationship fr1, feature_relationship fr2, feature f2, cvterm c1 where f1.uniquename=f_uniquename and f1.feature_id=fr1.object_id and fr1.subject_id=fr2.object_id and fr2.subject_id=f2.feature_id and (f2.uniquename like ''CR%:_'' or f2.uniquename like ''CR%:__'') and f2.type_id=c1.cvterm_id and c1.name=f_type_exon;
                select INTO maxid_temp max(to_number(substring(uniquename from 8),''99'')) from feature where (uniquename like ''CR%:_'' or uniquename like  ''CR%:__'') and substring(uniquename from 1 for 7)=f_uniquename;
             ELSIF pos=6 THEN
                select INTO maxid max(to_number(substring(uniquename from 9),''99'')) from feature f1, feature_relationship fr1, feature_relationship fr2, feature f2, cvterm c1 where f1.uniquename=f_uniquename and f1.feature_id=fr1.object_id and fr1.subject_id=fr2.object_id and fr2.subject_id=f2.feature_id and (f2.uniquename like ''CR%:_'' or f2.uniquename like ''CR%:__'') and f2.type_id=c1.cvterm_id and c1.name=f_type_exon;
                select INTO maxid_temp max(to_number(substring(uniquename from 9),''99'')) from feature where (uniquename like ''CR%:_'' or uniquename like  ''CR%:__'') and substring(uniquename from 1 for 6)=f_uniquename;
             END IF;
          END IF;
          IF maxid_temp IS NOT NULL and maxid_temp>maxid THEN
             maxid:=maxid_temp;
          END IF;
          IF maxid IS NULL THEN
             RAISE NOTICE ''wrong exon uniquename:% for this gene:%'', maxid, f_uniquename;
          ELSE 
             RAISE NOTICE ''max exon uniquename:% for this gene:%'', maxid, f_uniquename;
          END IF;
          IF maxid IS NULL THEN
             exon_id:=1;
          ELSE 
             exon_id:=maxid+1;
          END IF;
          RAISE NOTICE ''new exon_id:%'', exon_id;
          f_uniquename_exon:=CAST(f_uniquename||'':''||exon_id AS TEXT);
          RAISE NOTICE ''new uniquename:% for old uniquename:%'', f_uniquename_exon, NEW.uniquename;
          IF NEW.name like ''%temp%'' THEN
             update feature set uniquename=f_uniquename_exon, name=f_uniquename_exon where feature_id=f_row_e.feature_id;
          ELSE
              update feature set uniquename=f_uniquename_exon where feature_id=f_row_e.feature_id;
          END IF;
          IF f_row_e.dbxref_id IS  NULL THEN 
               SELECT INTO d_id db_id from db where name= f_dbname_gadfly;
               INSERT INTO dbxref(db_id, accession ) values(d_id, f_uniquename_exon);
               SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_exon;
               IF f_row_e.name like ''%temp%'' or f_row_e.name IS NULL THEN
                 update feature set name=f_uniquename_exon, dbxref_id=f_dbxref_id where feature_id=f_row_e.feature_id;
               ELSE
                 update feature set dbxref_id=f_dbxref_id where feature_id=f_row_e.feature_id;
               END IF;
          ELSE
               update dbxref set accession=f_uniquename_exon where dbxref_id=f_row_e.dbxref_id;
               f_dbxref_id:=f_row_e.dbxref_id;
               IF f_row_e.name like ''%temp%'' or f_row_e.name IS NULL THEN
                 update feature set name=f_uniquename_exon  where feature_id=f_row_e.feature_id;                  
               END IF;
          END IF;
          RAISE NOTICE ''new uniquename of this feature is:%'', f_uniquename_exon;
          INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(f_row_e.feature_id, f_dbxref_id, ''false'');
          SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
          SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id;
          IF s_id IS NULL THEN
               INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_exon, f_uniquename_exon, s_type_id);
               SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id;
          END IF;
          SELECT INTO p_id pub_id from pub p cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id ;
            IF p_id IS NULL THEN
                 SELECT INTO p_type_id cvterm_id from cvterm where name=p_cvterm_name;
                 IF p_type_id IS NULL THEN
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    IF c_cv_id IS NULL THEN
                        INSERT INTO cv(name) values(p_cv_name);
                        SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                    END IF;
                    INSERT INTO cvterm(name, cv_id) values(p_cvterm_name, c_cv_id);
                    SELECT INTO c_cv_id cv_id from cv where name=p_cv_name;
                 END IF;
                 INSERT INTO pub(uniquename, miniref, type_id) values(p_miniref, p_miniref, p_type_id);
                 SELECT INTO p_id pub_id from pub p, cvterm c where uniquename=p_miniref and c.name=p_cvterm_name and c.cvterm_id=p.type_id;
            END IF;

          SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_e.feature_id and synonym_id=s_id and pub_id=p_id;
          IF f_s_id IS NULL THEN
              INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_e.feature_id, s_id, p_id, ''true'');
          END IF;

-- warning: should NOT add any FBpp to exist exons, only add FBpp to NEW exons, which happen in tr_f_u.sql. otherwise, it will dumplicate
/*
           SELECT INTO maxid_fb to_number(substring(max(accession) from 5 for 11),''9999999'') from dbxref dx, db d where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBex%'';  
           IF maxid_fb IS NULL OR maxid_fb< 70000  THEN
               maxid_fb:=70000;
           ELSE 
               maxid_fb:=maxid_fb+1;
           END IF;
           id_fb:=lpad(maxid_fb, 7, ''0000000'');
           fb_accession:=CAST(''FBex''||id_fb AS TEXT);
           RAISE NOTICE ''fb_accession is:%'', fb_accession;
           SELECT INTO d_id db_id from db where name=f_dbname_FB;
           INSERT INTO dbxref(db_id, accession) values(d_id, fb_accession);
           SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
           INSERT INTO feature_dbxref(feature_id, dbxref_id) values(f_row_e.feature_id, f_dbxref_id);   
           RAISE NOTICE ''FBpp for feature:% is:%'', NEW.uniquename, fb_accession;
*/
      END IF;
  END IF; 
  SELECT INTO f_type_id cvterm_id from cvterm where name=f_type_remark;
  IF NEW.type_id=f_type_id THEN
       SELECT INTO maxid to_number(substring(max(uniquename) from 8 for 6),''999999'') from feature where uniquename like ''remark:%''; 
       IF maxid IS NULL THEN
         maxid:=1;
       ELSE
         maxid:=maxid+1;
       END IF;
       id:=lpad(maxid, 6, ''000000'');
       f_uniquename:=CAST(''remark:''||id as TEXT);
       RAISE NOTICE ''new unquename:%, old remark uniquename is:%'', f_uniquename, NEW.uniquename;
       UPDATE feature set uniquename=f_uniquename, name=f_uniquename where feature_id=NEW.feature_id;
  END IF;
  RAISE NOTICE ''leave f_i .......'';
  return NEW;    
END;
'LANGUAGE 'plpgsql';

CREATE TRIGGER feature_assignname_tr_i AFTER INSERT ON feature for EACH ROW EXECUTE PROCEDURE feature_assignname_fn_i();

/*
*/