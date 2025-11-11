drop TRIGGER featureprop_tr_i  ON featureprop ;
create or replace function featureprop_tr_i() RETURNS TRIGGER AS '
DECLARE
f_id feature.feature_id%TYPE;
f_uniquename feature.uniquename%TYPE;
f_time            timestamp;
BEGIN

     SELECT INTO f_time current_timestamp;
     SELECT INTO f_uniquename uniquename from feature where feature_id=NEW.feature_id;
     RAISE NOTICE ''update feature.timelastmodified due to new featureprop,set timelastmodified to:% for feature:%'', f_time, f_uniquename;
     update feature set timelastmodified=current_timestamp where feature_id=NEW.feature_id;

  RETURN NEW;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureprop_tr_i AFTER INSERT ON featureprop for EACH ROW EXECUTE PROCEDURE featureprop_tr_i();


-- here will manage the featureprop.rank, even real UC of featureprop is (feature_id, rank, type_id),
-- but in XORT ddl confi, we set it as (feature_id, value, type_id), so foreach featureprop with new value, we need to promote 
-- the existing fp.rank to other in order to insert this new which has defaut rank=0
drop TRIGGER featureprop_rank_tr_i  ON featureprop ;
create or replace function featureprop_rank_fn_i() RETURNS TRIGGER AS '
DECLARE
  rank_new    featureprop.rank%TYPE;
  rank_OLD    int:=0;
  fp_pub_row featureprop_pub%ROWTYPE;
  featureprop_id_OLD featureprop.featureprop_id%TYPE;
BEGIN
  -- here we ensure that any two records with same feature_id/type_id/rank but different value will NOT be overwrite
  SELECT INTO featureprop_id_OLD featureprop_id from featureprop where feature_id=NEW.feature_id and type_id=NEW.type_id and rank=rank_OLD;
  IF featureprop_id_OLD IS NOT NULL THEN
     SELECT INTO rank_new max(rank) from featureprop where feature_id=NEW.feature_id and type_id=NEW.type_id;
     rank_new:=rank_new+1;
     RAISE NOTICE ''update featureprop which has same feature_id/type_id and rank=0 as the new featureprop'';
     UPDATE featureprop set rank=rank_new where feature_id=NEW.feature_id and type_id=NEW.type_id and rank=rank_OLD;
  END IF;
  -- Triggers fired BEFORE signal the trigger manager to skip the operation for this actual row when returning NULL. 
  -- Otherwise, the returned record/row replaces the inserted/updated row in the operation.
  -- It is possible to replace single values directly in NEW and return that or to build a complete new record/row to return.
  -- here it is important to return NEW instead of OLD
  RETURN NEW;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureprop_rank_tr_i BEFORE INSERT ON featureprop for EACH ROW EXECUTE PROCEDURE featureprop_rank_fn_i();


-- anything happen to featureloc, also update feature.timelastmodified
drop TRIGGER featureloc_tr_i  ON featureloc ;
create or replace function featureloc_tr_i() RETURNS TRIGGER AS '
DECLARE
f_id feature.feature_id%TYPE;
f_uniquename feature.uniquename%TYPE;
f_time            timestamp;
BEGIN
    
     SELECT INTO f_time current_timestamp;
     SELECT INTO f_uniquename uniquename from feature where feature_id=NEW.feature_id;
     RAISE NOTICE ''update feature.timelastmodified due to insert of featureloc,set timelastmodified to:% for feature:%'', f_time, f_uniquename;
     update feature set timelastmodified=current_timestamp where feature_id=NEW.feature_id;

  RETURN NEW;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureloc_tr_i AFTER INSERT ON featureloc for EACH ROW EXECUTE PROCEDURE featureloc_tr_i();