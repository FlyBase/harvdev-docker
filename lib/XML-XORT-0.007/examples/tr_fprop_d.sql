drop TRIGGER featureprop_tr_d  ON featureprop ;
create or replace function featureprop_tr_d() RETURNS TRIGGER AS '
DECLARE
f_id feature.feature_id%TYPE;
f_uniquename feature.uniquename%TYPE;
f_time            timestamp;
BEGIN

     SELECT INTO f_time current_timestamp;
     SELECT INTO f_uniquename uniquename from feature where feature_id=OLD.feature_id;
     RAISE NOTICE ''update feature.timelastmodified due to delete featureprop,set timelastmodified to:% for feature:%'', f_time, f_uniquename;
     update feature set timelastmodified=current_timestamp where feature_id=OLD.feature_id;

  RETURN OLD;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureprop_tr_d BEFORE DELETE  ON featureprop for EACH ROW EXECUTE PROCEDURE featureprop_tr_d();


-- anything happen to featureloc, also update feature.timelastmodified
drop TRIGGER featureloc_tr_d  ON featureloc ;
create or replace function featureloc_tr_d() RETURNS TRIGGER AS '
DECLARE
f_id feature.feature_id%TYPE;
f_uniquename feature.uniquename%TYPE;
f_time            timestamp;
BEGIN
    
     SELECT INTO f_time current_timestamp;
     SELECT INTO f_uniquename uniquename from feature where feature_id=OLD.feature_id;
     RAISE NOTICE ''update feature.timelastmodified due to delete of featureloc,set timelastmodified to:% for feature:%'', f_time, f_uniquename;
     update feature set timelastmodified=current_timestamp where feature_id=OLD.feature_id;

  RETURN OLD;
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER featureloc_tr_d BEFORE DELETE  ON featureloc for EACH ROW EXECUTE PROCEDURE featureloc_tr_d();