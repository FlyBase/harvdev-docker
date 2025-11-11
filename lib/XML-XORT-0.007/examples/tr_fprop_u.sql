drop TRIGGER featureprop_tr_u  ON featureprop ;
create or replace function featureprop_tr_u() RETURNS TRIGGER AS '
DECLARE
f_id feature.feature_id%TYPE;
f_uniquename feature.uniquename%TYPE;
f_time            timestamp;
BEGIN
    IF NEW.type_id<>OLD.type_id OR NEW.value<>OLD.value OR NEW.rank<>OLD.rank THEN
     SELECT INTO f_time current_timestamp;
     SELECT INTO f_uniquename uniquename from feature where feature_id=OLD.feature_id;
     RAISE NOTICE ''update feature.timelastmodified due to changes of featureprop,set timelastmodified to:% for feature:%'', f_time, f_uniquename;
     update feature set timelastmodified=current_timestamp where feature_id=OLD.feature_id;
  END IF;
  RETURN OLD;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureprop_tr_u AFTER UPDATE ON featureprop for EACH ROW EXECUTE PROCEDURE featureprop_tr_u();



drop TRIGGER featureprop_rank_tr_u  ON featureprop ;
create or replace function featureprop_rank_fn_u() RETURNS TRIGGER AS '
DECLARE
  rank_new    featureprop.rank%TYPE;
  fp_pub_row featureprop_pub%ROWTYPE;
  featureprop_id_NEW featureprop.featureprop_id%TYPE;
BEGIN
  -- here we ensure that any two records with same feature_id/type_id/rank but different value will NOT be overwrite
  IF NEW.feature_id=OLD.feature_id and NEW.type_id=OLD.type_id and NEW.rank=OLD.rank and NEW.value<>OLD.value THEN
     SELECT INTO rank_new max(rank) from featureprop where feature_id=NEW.feature_id and type_id=NEW.type_id;
     rank_new:=rank_new+1;
     RAISE NOTICE ''create a new featureprop with OLD value, set OLD.value to new_value to avoid overwrite same feature_id/type_id/rank with diff value, and to return OLD.featureprop_id with NEW_value to XORT. The Old one,old value:%, new value:%'',OLD.value, NEW.value;
      insert into featureprop(feature_id, type_id, rank, value) values (OLD.feature_id, OLD.type_id, rank_new, OLD.value);
      delete from featureprop where value=NEW.value and feature_id=OLD.feature_id and rank<>OLD.rank;
       select featureprop_id into featureprop_id_NEW from featureprop where feature_id=OLD.feature_id and type_id=OLD.type_id and rank=rank_new;   
       FOR fp_pub_row IN SELECT * from featureprop_pub where featureprop_id=OLD.featureprop_id LOOP
           update featureprop_pub set featureprop_id=featureprop_id_NEW where featureprop_pub_id=fp_pub_row.featureprop_pub_id;      
       END LOOP;

  END IF;
  -- Triggers fired BEFORE signal the trigger manager to skip the operation for this actual row when returning NULL. 
  -- Otherwise, the returned record/row replaces the inserted/updated row in the operation.
  -- It is possible to replace single values directly in NEW and return that or to build a complete new record/row to return.
  -- here it is important to return NEW instead of OLD
  RETURN NEW;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureprop_rank_tr_u BEFORE UPDATE ON featureprop for EACH ROW EXECUTE PROCEDURE featureprop_rank_fn_u();


-- anything happen to featureloc, also update feature.timelastmodified
drop TRIGGER featureloc_tr_u  ON featureloc ;
create or replace function featureloc_tr_u() RETURNS TRIGGER AS '
DECLARE
f_id feature.feature_id%TYPE;
f_uniquename feature.uniquename%TYPE;
f_time            timestamp;
BEGIN
    IF NEW.srcfeature_id<>OLD.srcfeature_id OR NEW.fmin<>OLD.fmin OR NEW.fmax<>OLD.fmax  OR NEW.strand<>OLD.strand  OR NEW.phase<>OLD.phase  OR NEW.residue_info<>OLD.residue_info  OR NEW.locgroup<>OLD.locgroup  OR NEW.rank<>OLD.rank THEN
     SELECT INTO f_time current_timestamp;
     SELECT INTO f_uniquename uniquename from feature where feature_id=OLD.feature_id;
     RAISE NOTICE ''update feature.timelastmodified due to changes of featureloc,set timelastmodified to:% for feature:%'', f_time, f_uniquename;
     update feature set timelastmodified=current_timestamp where feature_id=OLD.feature_id;
  END IF;
  RETURN OLD;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureloc_tr_u AFTER UPDATE ON featureloc for EACH ROW EXECUTE PROCEDURE featureloc_tr_u();