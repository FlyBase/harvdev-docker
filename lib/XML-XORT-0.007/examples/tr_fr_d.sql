drop TRIGGER feature_relationship_tr_d  ON feature_relationship;
create or replace function feature_relationship_fn_d() RETURNS TRIGGER AS '
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
  f_dbxref_id feature.dbxref_id%TYPE;
  fb_accession dbxref.accession%TYPE;
  d_accession dbxref.accession%TYPE;
  f_uniquename_gene feature.uniquename%TYPE;
  f_uniquename_transcript feature.uniquename%TYPE;
  f_uniquename_exon feature.uniquename%TYPE;
  f_uniquename_protein feature.uniquename%TYPE;
  f_d_id               feature_dbxref.feature_dbxref_id%TYPE;
  d_id                 dbxref.dbxref_id%TYPE;
  s_type_id            synonym.type_id%TYPE;
  s_id                 synonym.synonym_id%TYPE;
  p_id                 pub.pub_id%TYPE;
  fr_row feature_relationship%ROWTYPE;
  f_accession_temp varchar(255);
  f_accession varchar(255);
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
 f_dbname_gadfly CONSTANT varchar :=''Gadfly'';
 f_dbname_FB CONSTANT varchar :=''FlyBase'';
  c_name_synonym CONSTANT varchar:=''synonym'';
  cv_cvname_synonym CONSTANT varchar:=''synonym type'';
  p_miniref         CONSTANT varchar:=''GadFly'';
BEGIN
 RAISE NOTICE ''enter fr_d, fr.object_id:%, fr.subject_id:%'', OLD.object_id, OLD.subject_id;
 SELECT INTO f_type name from cvterm  where cvterm_id=OLD.type_id;
 IF f_type=f_type_allele THEN
    RAISE NOTICE ''delete relationship beteen gene:% and allele:%'', OLD.object_id, OLD.subject_id; 
 ELSE
   SELECT INTO f_type c.name from feature f, cvterm c  where f.type_id=c.cvterm_id and f.feature_id=OLD.object_id;
   IF f_type=f_type_gene THEN 
      SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=OLD.subject_id and f.type_id=c.cvterm_id;
      IF (f_type_temp=f_type_transcript or f_type_temp=f_type_ncRNA or f_type_temp=f_type_snoRNA  or f_type_temp=f_type_snRNA  or f_type_temp=f_type_tRNA  or f_type_temp=f_type_rRNA  or f_type_temp=f_type_miRNA  or f_type_temp=f_type_pseudo ) THEN
          SELECT INTO fr_row * from feature_relationship where object_id<>OLD.object_id and subject_id=OLD.subject_id;
             if fr_row.object_id IS NULL THEN
                RAISE NOTICE ''delete this lonely transcript:%'', OLD.subject_id;
                delete from feature where feature_id=OLD.subject_id;
             END IF;
      ELSE
           RAISE NOTICE ''wrong feature_relationship: gene->NO_transcript:object_id:%, subject_id:%'', OLD.object_id, OLD.subject_id;
      END IF;
   ELSIF (f_type=f_type_transcript or f_type=f_type_snoRNA or f_type=f_type_ncRNA or f_type=f_type_snRNA or f_type=f_type_tRNA or f_type=f_type_miRNA or f_type=f_type_rRNA or f_type=f_type_pseudo) THEN
      SELECT INTO f_type_temp c.name from feature f, cvterm c where f.feature_id=OLD.subject_id and f.type_id=c.cvterm_id;
      IF f_type_temp=f_type_protein or f_type_temp=f_type_exon THEN
          SELECT INTO fr_row * from feature_relationship where subject_id=OLD.subject_id and object_id<>OLD.object_id;  
          IF fr_row.object_id IS NULL     THEN     
            RAISE NOTICE ''delete this lonely exon/protein:%'', OLD.subject_id;
            delete from feature where feature_id=OLD.subject_id;          
          END IF;
      ELSE
          RAISE NOTICE ''wrong relationship: transcript->NO_protein/exon: objfeature:%, subjfeature:%'',OLD.object_id, OLD.subject_id;
      END IF;
   END IF;
 END IF;
 RAISE NOTICE ''leave fr_d ....'';
 RETURN OLD;
END;
'LANGUAGE 'plpgsql';

CREATE TRIGGER feature_relationship_tr_d BEFORE DELETE ON feature_relationship  for EACH ROW EXECUTE PROCEDURE feature_relationship_fn_d();