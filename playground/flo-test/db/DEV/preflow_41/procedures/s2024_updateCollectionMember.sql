CREATE PROCEDURE `s2024_updateCollectionMember`(
pnCSMID         BIGINT(20)
,pnAccess       TINYINT(1)
,pnSharedStatus TINYINT(1)
,pnUpdatedDate  DOUBLE(13,3)
,pnUserID       BIGINT(20)
)
updateCollectionMember:BEGIN
  --
  -- -1: MSG_ERR_NOT_EXIST
  --
  DECLARE nID               BIGINT(20);
  DECLARE nUserID           BIGINT(20);
  DECLARE nColID            BIGINT(20);
  DECLARE vName             VARCHAR(255);
  DECLARE nType             TINYINT(1);
  DECLARE nShareStatus      TINYINT(1);
  DECLARE nAccess           TINYINT(1);
  -- 1. Find member BY email
   SELECT ifnull(max(csm.id), 0), csm.shared_status, csm.access
    INTO nID, nShareStatus, nAccess
    FROM collection_shared_member csm
    JOIN collection co ON (csm.collection_id = co.id)
   WHERE csm.id         = pnCSMID
     AND csm.user_id    = pnUserID
     AND co.is_trashed  = 0;
  --
  IF nID = 0 
    OR nShareStatus = 2 -- DECLINED
    OR nShareStatus = 3 -- REMOVED
    OR nShareStatus = 4 THEN -- LEAVED
    --
    SELECT -1 id; -- MSG_ERR_NOT_EXIST
    LEAVE updateCollectionMember;
    --
  END IF;
  --
  UPDATE collection_shared_member csm
     SET csm.shared_status = ifnull(pnSharedStatus, csm.shared_status)
        ,csm.access        = ifnull(pnAccess, csm.access)
        ,csm.updated_date  = pnUpdatedDate
        ,csm.joined_date   = CASE
                                WHEN pnSharedStatus <> nShareStatus
                                THEN pnUpdatedDate
                                ELSE csm.joined_date
                             END
  WHERE csm.id = nID;
  --
 SELECT csm.id, csm.member_user_id, csm.shared_email, csm.collection_id
        ,co.type collection_type, co.name collection_name, co.channel_id
        ,csm.account_id, csm.calendar_uri, csm.contact_uid, csm.contact_href
        ,nAccess old_access, csm.access, nShareStatus old_shared_status, csm.shared_status
        ,csm.created_date, csm.updated_date
    FROM collection_shared_member csm
    JOIN collection co ON (co.id = csm.collection_id)
   WHERE csm.id = nID;
  --
END