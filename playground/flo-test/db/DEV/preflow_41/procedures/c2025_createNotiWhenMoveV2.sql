CREATE PROCEDURE `c2025_createNotiWhenMoveV2`(
 OUT outNotiX           BIGINT(20)
,OUT outNotiY           BIGINT(20)
,OUT outNotiYDate       DOUBLE(13,3)
,OUT vContent         VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,collectionIdX          BIGINT(20)
,collectionIdY          BIGINT(20)
,objectUidOld           VARBINARY(1000)
,objectUidNew           VARBINARY(1000)
,objectType             VARCHAR(20)
,pvContent              VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,actionTime             DOUBLE(13,3)
,updatedDate            DOUBLE(13,3))
BEGIN
    DECLARE colTypeX          TINYINT(1) DEFAULT 0;
    DECLARE colTypeY          TINYINT(1) DEFAULT 0;
    DECLARE vAction           INT(11) DEFAULT 0;
    DECLARE vNotiX            TEXT;
    DECLARE vNotiY            TEXT;
  DECLARE vUserEmail       VARCHAR(255);
  DECLARE nUserId          BIGINT(20);
    -- GET content according TO new object_uid
    SET vContent = pvContent;
    --
    IF ifnull(vContent, '') = '' THEN
      --
      SET vContent = c2024_getObjectSummary(objectUidNew, objectType);
      --
    END IF;

    -- CREATE notifications for source share collection WITH action = 16(remove)
    SELECT c.`type`, u.id, u.email
      INTO colTypeX, nUserId, vUserEmail
      FROM collection c
      JOIN `user` u ON c.user_id = u.id
     WHERE c.id = collectionIdX;
    -- 
    IF (colTypeX = 3) THEN
       SET vAction = 16; -- Remove
       SET vNotiX = c2025_createNotificationV2(nUserId, vUserEmail, collectionIdX, 0, objectUidOld, objectType, vAction, actionTime, NULL, vContent, 0, updatedDate);
       SET outNotiX = JSON_EXTRACT(vNotiX, '$.id');
    END IF;
   
    -- CREATE notifications for source share collection WITH action = 0(CREATE)
    SELECT c.`type`
      INTO colTypeY
      FROM collection c
      JOIN `user` u ON c.user_id = u.id
     WHERE c.id = collectionIdY;
    -- 
    IF (colTypeY = 3) THEN
       SET vAction = 0; -- CREATE
       SET outNotiYDate = updatedDate + 0.001;
       SET vNotiY = c2025_createNotificationV2(nUserId, vUserEmail, collectionIdY, 0, objectUidNew, objectType, vAction, actionTime, NULL, vContent, 0, outNotiYDate);
       SET outNotiY = JSON_EXTRACT(vNotiY, '$.id');
    END IF;
END