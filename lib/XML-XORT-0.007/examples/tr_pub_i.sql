/*
1) For publications with FBrf's, uniquename is FBrf
2) for journals with ID "1234", uniquename is "multipub_1234"
3) for publications without FBrf's, uniquename is "temp_FBrf_1234"
4) for journals without FBrf's, uniquename is "temp_multipub_1234"
*/
drop trigger pub_assignname_tr_i on pub;
create or replace function pub_assignname_fn_i() RETURNS TRIGGER AS '
DECLARE
  id         int;
  maxid      int;
  p_row pub%ROWTYPE; 
  p_miniref         CONSTANT varchar:=''gadfly3'';
  p_uniquename pub.uniquename%TYPE;
  id_db db.db_id%TYPE;
  id_contact contact.contact_id%TYPE;
  id_dbxref dbxref.dbxref_id%TYPE;
  id_feature_dbxref feature_dbxref.feature_dbxref_id%TYPE;
  db_name         CONSTANT varchar:=''FlyBase'';
  contact_description         CONSTANT varchar:=''dummy'';
BEGIN
  RAISE NOTICE ''enter pub_i: pub.uniquename:%, pub.type_id:%'', NEW.uniquename, NEW.type_id;
  IF (NEW.uniquename like ''temp_FBrf%'' or NEW.uniquename like ''temp_multipub%'')  THEN
    IF (NEW.uniquename like ''temp_FBrf%'') THEN
        SELECT INTO maxid max(to_number(substring(uniquename from 5 for 11), ''9999999'')) from pub where uniquename like ''FBrf%'';

               RAISE NOTICE ''in pub_i, maxid before is:%'', maxid;
               IF maxid IS NULL THEN
                   maxid:=1;
               ELSE
                   maxid:=maxid+1;
               END IF;

               id:=lpad(maxid, 7, ''0000000'');
               p_uniquename:=CAST(''FBrf''||id as TEXT);
               RAISE NOTICE ''new uniquename is:%'', p_uniquename;
         UPDATE pub set uniquename=p_uniquename  where pub_id=NEW.pub_id;
    END IF;

    IF (NEW.uniquename like ''temp_multipub%'') THEN
        SELECT INTO maxid max(to_number(substring(uniquename from 8 for 14), ''9999999'')) from pub where uniquename like ''multipub%'';

               RAISE NOTICE ''in pub_i, maxid before is:%'', maxid;
               IF maxid IS NULL THEN
                   maxid:=1;
               ELSE
                   maxid:=maxid+1;
               END IF;
               p_uniquename:=CAST(''multipub_''||maxid as TEXT);
               RAISE NOTICE ''new uniquename is:%'', p_uniquename;
         UPDATE pub set uniquename=p_uniquename  where pub_id=NEW.pub_id;
     END IF;


  END IF;
  RAISE NOTICE ''leave pub_i .......'';
  return NEW;    
END;
'LANGUAGE 'plpgsql';
CREATE TRIGGER pub_assignname_tr_i AFTER INSERT ON pub for EACH ROW EXECUTE PROCEDURE pub_assignname_fn_i();
