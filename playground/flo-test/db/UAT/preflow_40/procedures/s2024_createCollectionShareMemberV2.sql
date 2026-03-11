CREATE PROCEDURE `s2024_createCollectionShareMemberV2`(
 pnCollectionID BIGINT(20)
,pvEmail        VARCHAR(100)
,pnAccountID    BIGINT(20)
,pnAccess       TINYINT(1)
,pvCalendarURI  VARCHAR(255)
,pvContactUid   VARCHAR(255)
,pvContactHref  VARCHAR(255)
,pnUpdatedDate  DOUBLE(13,3)
,pnUserID       BIGINT(20)
)
createCollectionShareMember:BEGIN
  --
  -- -1: MSG_NOT_FOUND_MEMBER
  -- -2: COLLECTION_NOT_EXIST
  -- -3: MSG_ERR_EXISTED
  -- -4: MSG_COLLECTION_ID_INVALID
  --
  DECLARE nID               BIGINT(20);
  DECLARE nUserID           BIGINT(20);
  DECLARE nOwnerId          BIGINT(20);
  DECLARE nColID            BIGINT(20);
  DECLARE vName             VARCHAR(255);
  DECLARE nType             TINYINT(1);
  DECLARE nShareStatus      TINYINT(1);
  -- 1. CHECK member user exist BY email
  SELECT ifnull(max(u.id), 0)
    INTO nUserID
    FROM `user` u
   WHERE u.username = pvEmail
     AND u.disabled = 0;
  --
  IF nUserID = 0 THEN
    --
    SELECT -1 id;
    LEAVE createCollectionShareMember;
    --
  END IF;
  -- 2. CHECK collection exist
   SELECT ifnull(max(co.id), 0), co.name, co.type
     INTO nColID, vName, nType
     FROM collection co
    WHERE co.id         = pnCollectionID
      AND co.user_id    = pnUserID
      AND co.is_trashed = 0;
  --
  IF nColID = 0 THEN
    --
    SELECT -2 id;
    LEAVE createCollectionShareMember;
    --
  END IF;
  --
  IF nType <> 3 THEN -- SHARED only
    --
    SELECT -4 id; -- MSG_COLLECTION_ID_INVALID
    LEAVE createCollectionShareMember;
    --
  END IF;
  -- 3. CREATE OR UPDATE
  SELECT ifnull(max(csm.id), 0), csm.shared_status, co.user_id
    INTO nID, nShareStatus, nOwnerId
    FROM collection co  
    LEFT JOIN collection_shared_member csm ON (co.id = csm.collection_id AND co.id = pnCollectionID)
   WHERE csm.user_id        = pnUserID
     AND csm.collection_id  = pnCollectionID
     AND csm.shared_email   = pvEmail;
  --
  IF nOwnerId = nUserID THEN
    --
    SELECT -5 id; -- MSG_OWNER_DENIED
    LEAVE createCollectionShareMember;
    --
  ELSEIF nID = 0 THEN
    --
    INSERT INTO collection_shared_member
    (user_id, collection_id, calendar_uri, access, shared_status
    ,contact_uid, contact_href
    ,shared_email, member_user_id, account_id, created_date, updated_date)
    VALUES
    (pnUserID, pnCollectionID, pvCalendarURI, pnAccess, 0 -- shared_status: 0, // always IS 0 WHEN CREATE
     ,pvContactUid, pvContactHref
     ,pvEmail, nUserID, ifnull(pnAccountID, 0), pnUpdatedDate, pnUpdatedDate);
    --
    SELECT last_insert_id() INTO nID;
    --
  ELSE
    --
    IF nShareStatus < 2 THEN -- SHARE_STATUS.DECLINED
      --
      SELECT -3 id; -- MSG_ERR_EXISTED
      LEAVE createCollectionShareMember;
      --
    END IF;
    --
    UPDATE collection_shared_member csm
       SET csm.shared_status    = 0
          ,csm.calendar_uri     = ifnull(pvCalendarURI, csm.calendar_uri)
          ,csm.access           = pnAccess
          ,csm.updated_date     = pnUpdatedDate
    WHERE csm.id = nID;
    --
  END IF;
  -- 4. response
  SELECT csm.id, csm.collection_id, csm.account_id
        ,csm.shared_email, csm.access, csm.shared_status
        ,csm.calendar_uri, csm.updated_date, csm.created_date
        ,csm.contact_uid
        ,csm.contact_href
        ,nType collection_type
        ,vName collection_name
    FROM collection_shared_member csm
    WHERE csm.id = nID;
  --
END