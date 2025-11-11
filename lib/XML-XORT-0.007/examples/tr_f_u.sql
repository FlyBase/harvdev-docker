drop TRIGGER feature_propagatename_tr_u  ON feature ;
create or replace function feature_propagatename_fn_u() RETURNS TRIGGER AS '
DECLARE
maxid int;
id    varchar(255);
maxid_fb int;
len     int;
pos     int;
no      int;
id_fb    varchar(255);
message   varchar(255);
exon_id int;
f_row   feature%ROWTYPE;
f_row_g feature%ROWTYPE;
f_row_e feature%ROWTYPE;
f_row_t feature%ROWTYPE;
f_row_p feature%ROWTYPE;
fr_row  feature_relationship%ROWTYPE;
f_type  cvterm.name%TYPE;
f_type_temp  cvterm.name%TYPE;
letter_t varchar;
letter_p varchar;
letter_e varchar;
uniquename_exon_like varchar;
f_dbxref_id feature.dbxref_id%TYPE;
fb_accession dbxref.accession%TYPE;
d_accession dbxref.accession%TYPE;
f_uniquename_temp feature.uniquename%TYPE;
f_uniquename feature.uniquename%TYPE;
f_uniquename_tr feature.uniquename%TYPE;
f_uniquename_exon feature.uniquename%TYPE;
f_uniquename_protein feature.uniquename%TYPE;
f_feature_id_exon feature.feature_id%TYPE;
f_feature_id_protein feature.feature_id%TYPE;
d_id                 db.db_id%TYPE;
dx_id                dbxref.dbxref_id%TYPE;
dx_id_temp           dbxref.dbxref_id%TYPE;
d_id_temp            dbxref.dbxref_id%TYPE; 
s_type_id            synonym.type_id%TYPE;
s_id                 synonym.synonym_id%TYPE;
p_id                 pub.pub_id%TYPE;
  p_type_id            cvterm.cvterm_id%TYPE;
  c_cv_id              cv.cv_id%TYPE;
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
  f_type_allele CONSTANT varchar :=''allele'';
  f_dbname_gadfly CONSTANT varchar :=''Gadfly'';
  f_dbname_FB CONSTANT varchar :=''FlyBase'';
  o_genus  CONSTANT varchar :=''Drosophila'';
  o_species  CONSTANT varchar:=''melanogaster'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''synonym type'';
  p_miniref         CONSTANT varchar:=''gadfly3'';
  p_cvterm_name     CONSTANT varchar:=''computer file'';
  p_cv_name         CONSTANT varchar:=''pub type'';
  f_time            timestamp;
BEGIN
  -- here change the timelastmodified whenever something change to feature table, how about featureprop, featureloc ...
  -- also postgre has very weird behavior whenever set spmething to null or change null to something, so ignore here...
  IF NEW.uniquename<>OLD.uniquename OR NEW.dbxref_id<>OLD.dbxref_id OR NEW.organism_id<>OLD.organism_id OR NEW.name<>OLD.name  OR NEW.uniquename<>OLD.uniquename OR NEW.residues<>OLD.residues OR NEW.seqlen<>OLD.seqlen OR NEW.md5checksum<>OLD.md5checksum  OR NEW.type_id<>OLD.type_id OR NEW.is_analysis<>OLD.is_analysis THEN
    SELECT INTO f_time current_timestamp;
    RAISE NOTICE ''set timelastmodified to:% for feature:%'', f_time, OLD.uniquename;
    update feature set timelastmodified=current_timestamp where feature_id=OLD.feature_id;
  END IF;
  IF NEW.uniquename <>OLD.uniquename and (NEW.uniquename like ''CG%'' or NEW.uniquename like ''CR%'') THEN
      SELECT INTO f_type c.name from feature f, cvterm c, organism o where f.type_id=c.cvterm_id and f.uniquename=NEW.uniquename and f.organism_id =NEW.organism_id;
      IF f_type is NOT NULL THEN
        RAISE NOTICE ''in f_u, type of this feature is:%'', f_type;
      END IF;
      IF f_type=f_type_gene THEN
        RAISE NOTICE ''in f_u, synchronize the transcript uniquename with genes'';
        FOR fr_row IN SELECT * from feature_relationship where object_id=OLD.feature_id LOOP
           SELECT INTO f_type c.name from feature f, cvterm c where f.type_id=c.cvterm_id and f.feature_id=fr_row.subject_id;
           IF (f_type =f_type_transcript or f_type =f_type_ncRNA or f_type =f_type_snoRNA or f_type =f_type_snRNA or f_type =f_type_tRNA  or f_type =f_type_rRNA or f_type =f_type_pseudo or f_type =f_type_miRNA) THEN
              SELECT INTO f_uniquename_temp uniquename from feature where feature_id=fr_row.subject_id; 
              len:=length (f_uniquename_temp);                        
              letter_t:=substring(f_uniquename_temp from len );             
              f_uniquename_tr:=CAST(NEW.uniquename||''-R''||letter_t  AS TEXT);
              RAISE NOTICE ''f_uniquename_tr:%'', f_uniquename_tr;
              UPDATE feature set uniquename=f_uniquename_tr where feature_id=fr_row.subject_id;
           ELSE
              RAISE NOTICE ''wrong relationship:gene->no_RNA: obj:%, subj:%'', fr_row.object_id, fr_row.subject_id;
              message:=CAST(''wrong relationship:gene->no_RNA''||''object:''||fr_row.object_id||''subject:''||fr_row.subject_id AS TEXT);
 
           END IF;
        END LOOP;
      ELSIF (f_type =f_type_transcript or f_type =f_type_ncRNA or f_type =f_type_snoRNA or f_type =f_type_snRNA or f_type =f_type_tRNA or f_type =f_type_rRNA  or f_type =f_type_pseudo or f_type =f_type_miRNA) THEN
        select INTO f_uniquename f.uniquename from feature f, feature_relationship fr where f.feature_id=fr.object_id and fr.subject_id=OLD.feature_id;
        IF f_uniquename IS NOT NULL THEN
          FOR fr_row IN SELECT * from feature_relationship where object_id=OLD.feature_id LOOP
             select INTO f_type_temp c.name from cvterm c, feature f where c.cvterm_id=f.type_id and f.feature_id=fr_row.subject_id;
             IF f_type_temp =f_type_protein THEN
                SELECT INTO f_row * from feature where feature_id=fr_row.subject_id;
                RAISE NOTICE ''f_row.uniquename:%'', f_row.uniquename;
                IF f_row.uniquename like ''CG:temp%'' or f_row.uniquename like ''CR:temp%'' THEN
                   len:=length(f_row.uniquename);
                   RAISE NOTICE ''len:% for uniquename:%'', len, f_row.uniquename;
                   letter_p:=substring(f_row.uniquename from len for 1); 

                   f_uniquename_protein:=CAST(f_uniquename||''-P''||letter_p  AS TEXT);
                   RAISE NOTICE ''letter_p:%, uniquename:%'', letter_p, f_uniquename_protein;
                   SELECT INTO d_id db_id from db where name=f_dbname_gadfly;                   
                   SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_protein;
                   IF dx_id IS NULL THEN                    
                      INSERT INTO dbxref(db_id, accession) values(d_id, f_uniquename_protein);
                      SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_protein;
                   END IF;
                   SELECT INTO d_id_temp dbxref_id from feature_dbxref where feature_id=fr_row.subject_id and dbxref_id=dx_id;
                   IF d_id_temp IS NULL THEN 
                      INSERT INTO feature_dbxref (feature_id, dbxref_id, is_current)  values(fr_row.subject_id, dx_id, ''false'');
                   END IF;
                   SELECT INTO maxid_fb max(to_number(substring(accession from 5 for 11),''9999999'')) from dbxref dx, db d where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBpp%'';  
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
                   SELECT INTO dx_id dbxref_id from dbxref dx , db d where dx.db_id=d.db_id and d.name=f_dbname_FB and accession=fb_accession;
                   INSERT INTO feature_dbxref(feature_id, dbxref_id) values(fr_row.subject_id, dx_id);
                   RAISE NOTICE ''insert FBpp:% into feature_dbxref, and set is_current as true'', fb_accession;
                   SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
                   RAISE NOTICE ''s_type_id:%'', s_type_id;
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
                   RAISE NOTICe ''start to insert feature_synonym:synonym_id:%,feature_id:%'', s_id, fr_row.subject_id;
                   INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (fr_row.subject_id, s_id, p_id, ''true'');
                ELSIF  (f_row.uniquename like ''CG%-P_'' or f_row.uniquename like ''CR%-P_'') and  f_row.uniquename not like ''%temp%''  THEN
                   len:=length(f_row.uniquename);
                   letter_p:=substring(f_row.uniquename from len);
                   f_uniquename_protein:=CAST(f_uniquename||''-P''||letter_p  AS TEXT);
                   RAISE NOTICE ''letter_p:%, len:%, f_uniquename_protein:%'', letter_p, len, f_uniquename_protein;
                END IF;
                IF (f_row.name like ''%temp%'' or f_row.name like ''CG%'' or f_row.name like ''CR%'') and f_row.uniquename like ''%temp%'' THEN         
                    UPDATE feature set uniquename=f_uniquename_protein, name=f_uniquename_protein,  dbxref_id=d_id_temp where feature_id=fr_row.subject_id;
                ELSIF  f_row.uniquename like ''%temp%'' THEN
                   UPDATE feature set uniquename=f_uniquename_protein, dbxref_id=d_id_temp where feature_id=fr_row.subject_id;
                END IF;
             ELSIF f_type_temp =f_type_exon THEN
                RAISE NOTICE ''in f_u, update exon:%'', fr_row.subject_id;
                SELECT INTO f_row_e * from feature where feature_id=fr_row.subject_id;
                IF f_row_e.uniquename like ''CG:temp%'' or f_row_e.uniquename like ''CR:temp%'' THEN
                   len:=length(f_row_e.uniquename)-1;
                   RAISE NOTICE ''in f_u, uniquename for exon is:%'', f_row_e.uniquename;
                   RAISE NOTICE ''in f_u, no is:%'', len;
                   letter_e:=substring(f_row_e.uniquename from len for 2); 
                  RAISE NOTICE ''in f_u, letter_e:% for for exon:%'',letter_e, f_row_e.uniquename; 
                  pos:=position('':'' in letter_e);
                  IF pos =1 THEN
                     len:=len+1; 
                     letter_e:=substring(f_row_e.uniquename from len for 1); 
                  END IF;
                   f_uniquename_exon:=CAST(f_uniquename||'':''||letter_e AS TEXT); 
                   RAISE NOTICE ''letter_e:%, uniquename:%'', letter_e, f_uniquename_exon;
                   SELECT INTO d_id db_id from db where name=f_dbname_gadfly;
                   SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_exon;  
                   IF dx_id is NULL THEN
                       INSERT INTO dbxref(db_id, accession) values(d_id, f_uniquename_exon);
                       SELECT INTO dx_id dbxref_id from dbxref where db_id=d_id and accession=f_uniquename_exon;
                   END IF;
                   INSERT INTO feature_dbxref (feature_id, dbxref_id, is_current)  values(fr_row.subject_id, dx_id, ''false'');
                   SELECT INTO maxid_fb max(to_number(substring(accession from 5 for 11),''9999999'')) from dbxref dx, db d where dx.db_id=d.db_id and d.name = f_dbname_FB and accession like ''FBex%'';  
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
                   INSERT INTO feature_dbxref(feature_id, dbxref_id) values(fr_row.subject_id, dx_id);
                   RAISE NOTICE ''insert FBex:% into feature_dbxref, and set is_current as true'', fb_accession;
                   SELECT INTO s_type_id cvterm_id from cvterm c1, cv c2 where c1.name=c_name_synonym and c2.name=cv_cvname_synonym and c1.cv_id=c2.cv_id;
                   RAISE NOTICE ''s_type_id:%'', s_type_id;
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
                   RAISE NOTICe ''start to insert feature_synonym:synonym_id:%,feature_id:%'', s_id, fr_row.subject_id;
                   INSERT INTO feature_synonym(feature_id, synonym_id, pub_id, is_current) values (fr_row.subject_id, s_id, p_id, ''true'');

                   RAISE NOTICE ''in f_u, new uniquename for exon:%, old unqiuename:%'', f_uniquename_exon, f_row_e.uniquename;
                   SELECT INTO f_feature_id_exon feature_id from feature where uniquename=f_uniquename_exon;
                   IF f_feature_id_exon IS NOT NULL THEN 
                      RAISE NOTICE ''this exon:% share with other transcript, re_direct to exist exon and delete this one'', f_row_e.uniquename;
                      RAISE NOTICE ''UPDATE feature_relationship set subject_id=% where feature_relationship_id=%'',f_feature_id_exon,fr_row.feature_relationship_id;
                      UPDATE feature_relationship set subject_id=f_feature_id_exon where feature_relationship_id=fr_row.feature_relationship_id;
                      delete from feature_dbxref where feature_id=f_row_e.feature_id;
                      delete from feature_synonym where  feature_id=f_row_e.feature_id;
                      delete from featureprop where feature_id=f_row_e.feature_id;
                      DELETE from featureloc where feature_id=f_row_e.feature_id;
                      DELETE from feature where feature_id=f_row_e.feature_id;
                      RAISE NOTICE ''finish re_direct feature_relationship:%'',fr_row.feature_relationship_id;
                   ELSE 
                     IF (f_row_e.name like ''%temp%'' or f_row_e.name like ''CG%'' or  f_row_e.name like ''CR%'') and f_row_e.uniquename like ''%temp%'' THEN         
                        RAISE NOTICE ''in f_u, update both uniquename and name for exon:%'', f_row_e.uniquename;  
                        UPDATE feature set uniquename=f_uniquename_exon, name=f_uniquename_exon,  dbxref_id=dx_id where feature_id=fr_row.subject_id;
                     ELSIF f_row_e.uniquename like ''%temp%'' THEN
                        RAISE NOTICE ''in f_u, update exon uniuqnename:% to %'', f_row_e.uniquename, f_uniquename_exon;   
                        UPDATE feature set uniquename=f_uniquename_exon, dbxref_id=dx_id where feature_id=fr_row.subject_id;
                     END IF;
                   END IF;
                ELSIF  (f_row_e.uniquename like ''CG%:_%'' or f_row_e.uniquename like ''CR%:_%'') and f_row_e.uniquename not like ''%temp%'' THEN
                   len:=position('':'' in f_row_e.uniquename);
                   pos:=length (f_uniquename);
                   RAISE NOTICE ''len:%'', len;
                   letter_e:=substring(f_row_e.uniquename from len+1);
                   f_uniquename_exon:=CAST(f_uniquename||'':''||letter_e AS TEXT);
                   RAISE NOTICE ''f_uniquename_exon:%, f_row.uniquename:%, len:%'', f_uniquename_exon, f_row_e.uniquename, len;
                END IF;

             ELSE
                RAISE NOTICE ''wrong relationship: transcript->no_exon/protein, obj:%, subj:%'', fr_row.object_id, fr_row.subject_id;
             END IF;
          END LOOP;
        END IF;
      END IF;
  END IF; 
  RETURN OLD;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER feature_propagatename_tr_u AFTER UPDATE ON feature for EACH ROW EXECUTE PROCEDURE feature_propagatename_fn_u();



