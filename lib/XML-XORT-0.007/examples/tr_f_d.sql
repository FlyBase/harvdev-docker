drop TRIGGER tr_feature_del  ON feature;
create or replace function fn_feature_del() RETURNS TRIGGER AS '
DECLARE 
  f_type cvterm.name%TYPE;
  f_id_gene feature.feature_id%TYPE;
  f_id_transcript feature.feature_id%TYPE;
  f_id_exon feature.feature_id%TYPE;
  f_id_exon_temp feature.feature_id%TYPE; 
  f_id_protein feature.feature_id%TYPE;
  f_id_allele feature.feature_id%TYPE;
  fr_object_id feature.feature_id%TYPE;
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
  f_return feature.feature_id%TYPE;
  f_row feature%ROWTYPE;
  fr_row_transcript feature_relationship%ROWTYPE;
  fr_row_exon feature_relationship%ROWTYPE;
  fr_row_protein feature_relationship%ROWTYPE;
  message   varchar(255);
BEGIN
   RAISE NOTICE ''enter f_d, feature uniquename:%, type_id:%'',OLD.uniquename, OLD.type_id;
   f_return:=OLD.feature_id;
   SELECT INTO f_type c.name from feature f, cvterm c where f.feature_id=OLD.feature_id and f.type_id=c.cvterm_id;
   IF f_type=f_type_gene THEN
     SELECT INTO f_id_allele fr.subject_id from  feature_relationship fr, cvterm c where  (fr.object_id=OLD.feature_id or fr.subject_id=OLD.feature_id)  and fr.type_id=c.cvterm_id and c.name=f_type_allele;
     IF NOT FOUND THEN 
       FOR fr_row_transcript IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
         SELECT INTO f_id_transcript  f.feature_id from feature f, cvterm c where f.feature_id=fr_row_transcript.subject_id and f.type_id=c.cvterm_id and (c.name=f_type_transcript or c.name=f_type_ncRNA or c.name=f_type_snoRNA or c.name=f_type_snRNA or c.name=f_type_tRNA  or c.name=f_type_rRNA  or c.name=f_type_pseudo  or c.name=f_type_miRNA); 
         SELECT INTO f_id_gene f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_transcript and f.type_id=c.cvterm_id and c.name=f_type_gene and f.feature_id !=OLD.feature_id;
         IF f_id_gene IS NULL and f_id_transcript IS NOT NULL THEN
            RAISE NOTICE ''delete lonely transcript:%'', f_id_transcript;
            message:=CAST(''delete lonely transcript''||f_id_transcript AS TEXT);
            delete from feature where feature_id=f_id_transcript;
         ELSIF f_id_gene IS NOT NULL AND F_id_transcript IS NOT NULL THEN
            RAISE NOTICE ''There is another gene:% associated with this transcript:%, so this transcript will be kept'',f_id_gene, f_id_transcript;
            message:=CAST(''There is another gene:''||f_id_gene||'' associated with this transcript:''||f_id_transcript AS TEXT); 
         END IF;
      END LOOP;
      message:=CAST(''delete gene:''||OLD.feature_id AS TEXT);
    ELSE
     RAISE NOTICE ''there is other allele associated with this gene:%'', f_id_allele;
            message:=CAST(''There is other allele associated with this gene:''||f_id_allele AS TEXT); 
     -- return NULL will skip the delete operation since this happen BEFORE delete on featre ????  -----------------
     return NULL;
    END IF;
  ELSIF (f_type=f_type_transcript or f_type=f_type_ncRNA or f_type=f_type_snoRNA or f_type=f_type_snRNA or f_type=f_type_tRNA  or f_type=f_type_rRNA or f_type=f_type_pseudo or  f_type=f_type_miRNA) THEN
     FOR fr_row_exon IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
        select INTO f_id_exon f.feature_id from feature f, cvterm c where f.feature_id=fr_row_exon.subject_id and f.type_id=c.cvterm_id and c.name=f_type_exon;
        SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_exon and f.type_id=c.cvterm_id and (c.name=f_type_transcript or c.name=f_type_ncRNA or c.name=f_type_snoRNA or c.name=f_type_snRNA or c.name=f_type_tRNA  or c.name=f_type_rRNA  or c.name=f_type_pseudo  or c.name=f_type_miRNA) and f.feature_id!=OLD.feature_id;
        IF f_id_transcript IS NULL and f_id_exon IS NOT NULL THEN
            RAISE NOTICE ''delete lonely exon:%'', f_id_exon;
           delete from feature where feature_id=f_id_exon; 
            message:=CAST(''delete lonely exon:''||f_id_exon AS TEXT); 
        ELSIF f_id_transcript IS NOT NULL and f_id_exon IS NOT NULL THEN
            RAISE NOTICE ''There is another transcript:% associated with this exon:%, so this exon will be kept'', f_id_transcript, f_id_exon;
            message:=CAST(''There is another transcript:''||f_id_transcript||'' associated with this exon:''||f_id_exon AS TEXT); 
        END IF;    
     END LOOP;

     FOR fr_row_protein IN SELECT * from feature_relationship fr where fr.object_id=OLD.feature_id LOOP
        SELECT INTO f_id_protein f.feature_id from feature f, cvterm c where f.feature_id=fr_row_protein.subject_id and f.type_id=c.cvterm_id and c.name=f_type_protein;
        SELECT INTO f_id_transcript f.feature_id from feature f, feature_relationship fr, cvterm c where f.feature_id=fr.object_id and fr.subject_id=f_id_protein and f.type_id=c.cvterm_id and (c.name=f_type_transcript or c.name=f_type_ncRNA or c.name=f_type_snoRNA or c.name=f_type_snRNA or c.name=f_type_tRNA  or c.name=f_type_rRNA   or c.name=f_type_pseudo or  c.name=f_type_miRNA) and f.feature_id !=OLD.feature_id;
        IF f_id_transcript IS NULL and f_id_protein IS NOT NULL THEN
                  RAISE NOTICE ''delete lonely protein:%'', f_id_protein;
                  delete from feature where feature_id=f_id_protein;
                  message:=CAST(''delete lonely protein:''||f_id_protein AS TEXT); 
        ELSIF f_id_transcript IS NOT NULL and f_id_protein IS NOT NULL THEN
                  RAISE NOTICE ''There is another transcript:% associated with this protein:%, so this exon will be kept'', f_id_transcript, f_id_protein;
        END IF;
     END LOOP;
  END IF;
  RAISE NOTICE ''leave f_d ....'';
  RETURN OLD; 
END;
'LANGUAGE 'plpgsql';

CREATE TRIGGER tr_feature_del BEFORE DELETE ON feature for EACH ROW EXECUTE PROCEDURE fn_feature_del();
