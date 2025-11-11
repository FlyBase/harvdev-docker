drop trigger feature_relationship_propagatename_tr_i ON feature_relationship;
create or replace function feature_relationship_propagatename_fn_i() RETURNS TRIGGER AS '
DECLARE
  maxid int;
  exon_id int;
  id    varchar(255);
  maxid_fb int;
  id_fb    varchar(255);
  loginfo      varchar(255);
  len   int;
  f_row_g feature%ROWTYPE;
  f_row_e feature%ROWTYPE;
  f_row_t feature%ROWTYPE;
  f_row_p feature%ROWTYPE;
  f_type  cvterm.name%TYPE;
  f_type_temp  cvterm.name%TYPE;
  letter_e varchar(10);
  letter_t varchar(10);
  letter_p varchar(10);
  f_dbxref_id          feature.dbxref_id%TYPE;
  fb_accession         dbxref.accession%TYPE;
  d_accession          dbxref.accession%TYPE;
  f_uniquename_gene    feature.uniquename%TYPE;
  f_uniquename_transcript feature.uniquename%TYPE;
  f_uniquename_exon feature.uniquename%TYPE;
  f_uniquename_protein feature.uniquename%TYPE;
  f_d_id               feature_dbxref.feature_dbxref_id%TYPE;
  dx_id                dbxref.dbxref_id%TYPE;
  d_id                 db.db_id%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  p_id                 pub.pub_id%TYPE;
  p_type_id            cvterm.cvterm_id%TYPE;
  c_cv_id              cv.cv_id%TYPE;
  f_s_id               feature_synonym.feature_synonym_id%TYPE;
  fr_row              feature_relationship%ROWTYPE;
  f_accession_temp varchar(255);
  f_accession varchar(255);
  f_type_gene CONSTANT varchar :=''gene'';
  f_type_exon CONSTANT varchar :=''exon'';
  f_type_transcript CONSTANT varchar :=''mRNA'';
  f_type_snoRNA CONSTANT varchar :=''snoRNA'';
  f_type_ncRNA CONSTANT varchar :=''ncRNA'';
  f_type_snRNA CONSTANT varchar :=''snRNA'';
  f_type_tRNA CONSTANT varchar :=''tRNA'';
  f_type_miRNA CONSTANT varchar :=''miRNA'';
  f_type_rRNA CONSTANT varchar :=''rRNA'';
  f_type_pseudo CONSTANT varchar :=''pseudogene'';
  f_type_protein CONSTANT varchar :=''protein'';
  f_type_allele CONSTANT varchar :=''alleleof'';
 f_dbname_gadfly CONSTANT varchar :=''Gadfly'';
 f_dbname_FB CONSTANT varchar :=''FlyBase'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''synonym type'';
  p_miniref         CONSTANT varchar:=''gadfly3'';
  p_cvterm_name     CONSTANT varchar:=''computer file'';
  p_cv_name         CONSTANT varchar:=''pub type'';
BEGIN
 RAISE NOTICE ''enter fr_i, fr.object_id:%, fr.subject_id:%'', NEW.object_id, NEW.subject_id;
 SELECT INTO f_type name from cvterm  where cvterm_id=NEW.type_id;
 IF f_type=f_type_allele THEN
    SELECT INTO f_accession d.accession from feature_dbxref fd, dbxref d where fd.feature_id=NEW.subject_id and fd.dbxref_id=d.dbxref_id and d.accession like ''FBal%'';
    IF f_accession IS NULL THEN
        SELECT INTO maxid_fb to_number(substring(max(accession) from 5 for 11),''9999999'') from dbxref dx, db d  where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBal%'';  
           IF maxid_fb IS NULL OR maxid_fb< 70000  THEN
               maxid_fb:=70000;
           ELSE 
               maxid_fb:=maxid_fb+1;
           END IF;
           id_fb:=lpad(maxid_fb, 7, ''0000000'');
           fb_accession:=CAST(''FBal''||id_fb AS TEXT);
           RAISE NOTICE ''fb_accession is:%'', fb_accession;
           SELECT INTO d_id db_id from db where name=f_dbname_FB;
           RAISE NOTICE ''db_id is:%'', d_id;
           SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
           IF ( dx_id IS NOT NULL ) THEN
                RAISE NOTICE ''warning: you insert dumplicate accession:% into db....'', fb_accession;
           ELSE 
              INSERT INTO dbxref(db_id, accession) values(d_id, fb_accession);
              SELECT INTO f_dbxref_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
           END IF;
           INSERT INTO feature_dbxref(feature_id, dbxref_id) values(NEW.subject_id, f_dbxref_id);       
    END IF;
    SELECT INTO f_d_id feature_dbxref_id from feature_dbxref fd, dbxref d where fd.feature_id=NEW.subject_id and fd.dbxref_id=d.dbxref_id and d.accession like ''FBgn%'';
    IF f_d_id IS NOT NULL THEN
        delete from feature_dbxref where feature_dbxref_id=f_d_id;
        RAISE NOTICE ''delete this feature_dbxref which originally set as FBgn, and should be FBal:%'',f_d_id;      
    END IF;
 ELSE
   SELECT INTO f_type c.name from feature f, cvterm c  where f.type_id=c.cvterm_id and f.feature_id=NEW.object_id;
   IF f_type=f_type_gene THEN 
      SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=NEW.subject_id and f.type_id=c.cvterm_id;
      IF (f_type_temp=f_type_transcript or f_type_temp=f_type_snoRNA or f_type_temp=f_type_ncRNA or f_type_temp=f_type_snRNA or f_type_temp=f_type_tRNA or f_type_temp=f_type_rRNA or f_type_temp=f_type_miRNA or f_type_temp=f_type_pseudo) THEN
          SELECT INTO f_row_t * from feature where feature_id=NEW.subject_id;
          IF f_row_t.uniquename like ''CG:temp%'' or f_row_t.uniquename like ''CR:temp%'' THEN
             SELECT INTO f_uniquename_gene uniquename from feature where feature_id=NEW.object_id;
             f_accession_temp:=f_row_t.uniquename;
             IF f_accession_temp like ''CG:temp%'' or f_accession_temp like ''CR:temp%'' THEN
                len:=length(f_accession_temp);
                letter_t:=substring(f_accession_temp from len for 1);             
                 f_uniquename_transcript:=CAST(f_uniquename_gene||''-R''||letter_t  AS TEXT);
             ELSE 
                f_uniquename_transcript:=f_accession_temp;
             END IF;
             RAISE NOTICE ''insert new accession for transcript, dbname:%, accession:%'', f_dbname_gadfly, f_uniquename_transcript;
             SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
             SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_transcript;
             IF (dx_id IS NOT NULL ) THEN 
                RAISE NOTICE ''warning: you insert dumplicate transcript:% into db....'', f_uniquename_transcript;
             ELSE 
               insert into dbxref (db_id, accession) values(d_id, f_uniquename_transcript);
               SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_transcript;
             END IF;
             SELECT INTO f_d_id feature_dbxref_id from feature_dbxref where feature_id=NEW.subject_id and dbxref_id=dx_id;
             IF f_d_id IS NULL THEN
                INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(NEW.subject_id, dx_id, ''false'');
             END IF;
             RAISE NOTICE ''start to update feature, old:%, new:%'', f_row_t.uniquename, f_uniquename_transcript;
             IF f_row_t.name like ''%temp%'' THEN
                RAISE NOTICE ''also update feature.name'';
                UPDATE feature set name=f_uniquename_transcript, uniquename=f_uniquename_transcript, dbxref_id=dx_id where feature_id=NEW.subject_id;
             ELSE                
                UPDATE feature set  uniquename=f_uniquename_transcript, dbxref_id=dx_id where feature_id=NEW.subject_id;
             END IF;   
             RAISE NOTICE ''assign new number for transcript:%'', NEW.subject_id;
             SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
             RAISE NOTICE ''s_type_id:%'', s_type_id;
             SELECT INTO s_id synonym_id from synonym where name=f_uniquename_transcript and type_id=s_type_id;
             IF s_id IS NULL THEN 
                 INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_transcript, f_uniquename_transcript, s_type_id);
                 SELECT INTO s_id synonym_id from synonym where name=f_uniquename_transcript and type_id=s_type_id;
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
             RAISE NOTICe ''start to insert feature_synonym:synonym_id:%,feature_id:%, pub_id:%'', s_id, f_row_t.feature_id, p_id;
             SELECT INTO f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_t.feature_id and synonym_id=s_id and pub_id=p_id;
             IF f_s_id IS NULL THEN 
                  INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_t.feature_id, s_id, p_id, ''true'');           
             END IF;     
             SELECT INTO maxid_fb to_number(substring(max(accession) from 5 for 11),''9999999'') from dbxref dx, db d where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBtr_______'';  
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
             SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
             INSERT INTO feature_dbxref(feature_id, dbxref_id) values(NEW.subject_id, dx_id);
             RAISE NOTICE ''insert FBtr:% into feature_dbxref, and set is_current as true'', fb_accession;
          ELSIF (f_row_t.uniquename like ''CG%-R_'' or f_row_t.uniquename like ''CR%-R_'') and  f_row_t.uniquename not like ''%:%'' THEN
             RAISE NOTICE ''add new transcript:% to exist gene'', f_row_t.uniquename;  
          ELSE
             RAISE NOTICe ''Warning:unexpected format for uniquename(transcript):%'', f_row_t.uniquename;
          END IF;
      ELSE
              RAISE NOTICE ''wrong feature_relationship: gene->NO_transcript:object_id:%, subject_id:%'', NEW.object_id, NEW.subject_id;
      END IF;

   ELSIF (f_type=f_type_transcript or f_type=f_type_ncRNA  or f_type=f_type_snoRNA or f_type=f_type_snRNA or f_type=f_type_tRNA or f_type=f_type_rRNA or f_type=f_type_miRNA or f_type=f_type_pseudo)   THEN
      SELECT INTO f_uniquename_gene f.uniquename from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=NEW.object_id and f.type_id=c.cvterm_id and c.name=f_type_gene;
      SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=NEW.subject_id and f.type_id=c.cvterm_id;
      IF f_type_temp=f_type_protein and f_uniquename_gene IS NOT NULL THEN
          SELECT INTO f_row_p * from feature where feature_id=NEW.subject_id;  
          IF f_row_p.uniquename like ''CG:temp%'' or f_row_p.uniquename like ''CR:temp%''    THEN     
             f_accession_temp:=f_row_p.uniquename;
             if f_accession_temp like ''CG:temp%'' or f_accession_temp like ''CR:temp%'' THEN
                len:=length(f_accession_temp);
                letter_p:=substring(f_accession_temp from len for 1);             
                f_uniquename_protein:=CAST(f_uniquename_gene||''-P''||letter_p  AS TEXT);
             ELSE 
                f_uniquename_protein:=f_accession_temp;
             END IF;
             RAISE NOTICE ''update uniquename of protein:% to new uniquename:%'',f_row_p.uniquename, f_uniquename_protein;
             SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
             SELECT INTO dx_id dbxref_id from dbxref dx, db d  where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_protein;
             IF  dx_id IS NULL THEN
                 insert into dbxref (db_id, accession) values(d_id, f_uniquename_protein);
                 SELECT INTO dx_id dbxref_id from dbxref dx, db d  where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_protein;
             END IF;
             SELECT INTO f_d_id feature_dbxref_id from feature_dbxref where feature_id=NEW.subject_id and dbxref_id=dx_id;
             IF f_d_id IS NULL THEN 
                 INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(NEW.subject_id, dx_id, ''false'');
             END IF;
             if f_row_p.name like ''%temp%'' THEN
                UPDATE feature set name=f_uniquename_protein, uniquename=f_uniquename_protein, dbxref_id=dx_id where feature_id=NEW.subject_id;
             ELSE
                UPDATE feature set  uniquename=f_uniquename_protein, dbxref_id=dx_id where feature_id=NEW.subject_id;
             END IF;   
             RAISE NOTICE ''assign new number:% for protein:%'', f_uniquename_protein,  NEW.subject_id;
             SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
             SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
             IF s_id IS NULL THEN
                  INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_protein, f_uniquename_protein, s_type_id);
                  SELECT INTO s_id synonym_id from synonym where name=f_uniquename_protein and type_id=s_type_id;
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
             SELECT INTo f_s_id feature_synonym_id from feature_synonym where feature_id=f_row_p.feature_id and synonym_id=p_id;
             INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_p.feature_id, s_id, p_id, ''true'');
                
             SELECT INTO maxid_fb to_number(substring(max(accession) from 5 for 11),''9999999'') from dbxref dx, db d  where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBpp_______'';  
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
             SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
             INSERT INTO feature_dbxref(feature_id, dbxref_id) values(NEW.subject_id, dx_id);
             RAISE NOTICE ''insert FBpp:% into feature_dbxref, and set is_current as true'', fb_accession;
          ELSIF (f_row_p.uniquename like ''CG%-P_'' or f_row_p.uniquename like ''CR%-P_'') and  f_row_p.uniquename not like ''%:%'' THEN
              RAISE NOTICE ''add protein to exist transcript'';
          ELSE
              RAISE NOTICE ''warning:unexpected format of protein uniquename:%'', f_row_p.uniquename;
          END IF;
      ELSIF f_type_temp=f_type_exon and f_uniquename_gene IS NOT NULL THEN
          SELECT INTO f_row_e * from feature where feature_id=NEW.subject_id;
          IF f_row_e.uniquename like ''CG:temp%'' or f_row_e.uniquename like ''CR:temp%''  THEN            
             f_accession_temp:=f_row_e.uniquename;
             IF f_accession_temp like ''CG:temp_:%'' or f_accession_temp like ''CR:temp_:%'' THEN
                len:=length(f_accession_temp);
                letter_e:=substring(f_accession_temp from 10);             
                f_uniquename_exon:=CAST(f_uniquename_gene||'':''||letter_e  AS TEXT);
             ELSIF f_accession_temp like ''CG:temp__:%'' or  f_accession_temp like ''CR:temp__:%'' THEN
                len:=length(f_accession_temp);
                letter_e:=substring(f_accession_temp from 11);             
                f_uniquename_exon:=CAST(f_uniquename_gene||'':''||letter_e  AS TEXT);
             ELSE 
                f_uniquename_exon:=f_accession_temp;
             END IF;
             RAISE NOTICE ''letter_e:%, uniquename:%'', letter_e, f_uniquename_exon;
             SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
             insert into dbxref (db_id, accession) values(d_id, f_uniquename_exon);
             SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_gadfly and accession=f_uniquename_exon;
             INSERT INTO feature_dbxref(feature_id, dbxref_id, is_current) values(NEW.subject_id, dx_id, ''false'');
             if f_row_e.name like ''%temp%'' THEN
                UPDATE feature set name=f_uniquename_exon, uniquename=f_uniquename_exon, dbxref_id=d_id where feature_id=NEW.subject_id;
             ELSE
                UPDATE feature set  uniquename=f_uniquename_exon, dbxref_id=d_id where feature_id=NEW.subject_id;
             END IF;   
             RAISE NOTICE ''assign new number:% for exon:%'', f_uniquename_exon,  NEW.subject_id;
             SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
             SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id; 
             IF s_id IS NULL THEN
                 INSERT INTO synonym(name, synonym_sgml, type_id) values(f_uniquename_exon, f_uniquename_exon, s_type_id);
                 SELECT INTO s_id synonym_id from synonym where name=f_uniquename_exon and type_id=s_type_id;
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
             INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (f_row_e.feature_id, s_id, p_id, ''true'');                
             SELECT INTO maxid_fb to_number(substring(max(accession) from 5 for 11),''9999999'') from dbxref dx, db d  where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBex%'';  
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
             SELECT INTO dx_id dbxref_id from dbxref dx, db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
             INSERT INTO feature_dbxref(feature_id, dbxref_id) values(NEW.subject_id, dx_id);
             RAISE NOTICE ''insert FBpp:% into feature_dbxref, and set is_current as true'', fb_accession;
          ELSIF f_row_e.uniquename like ''CG%:%'' or f_row_e.uniquename like ''CR%:%'' THEN 
               RAISE NOTICE ''add exon to exist transcript'';  
          ELSE
               RAISE NOTICE ''unexpected format of exon uniquename:%'', f_row_e.uniquename;            
          END IF;
      ELSE
         RAISE NOTICE ''no link to gene for this transcript or wrong feature_relationship: transcript->protein/exon:object_id:%, subject_id:%'', NEW.object_id, NEW.subject_id;
      END IF;
   END IF;
 END IF;
 RAISE NOTICE ''leave fr_i ....'';
 RETURN NEW;
END;
'LANGUAGE 'plpgsql';

CREATE trigger feature_relationship_propagatename_tr_i after INSERT ON feature_relationship for EACH ROW EXECUTE PROCEDURE feature_relationship_propagatename_fn_i();

-- this is the place to check FBtr/FBpp, not in tr_f_i, before 