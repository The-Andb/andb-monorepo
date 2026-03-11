CREATE PROCEDURE `c2024_createNotiWhenMove`(
 OUT outNotiX           BIGINT(20)
,OUT outNotiY           BIGINT(20)
,OUT outNotiYDate       DOUBLE(13,3)
,userId                 BIGINT(20)
,userEmail              VARCHAR(255)
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
    DECLARE vContent          VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT pvContent;
    DECLARE vAction           INT(11) DEFAULT 0;
    -- GET content according TO new object_uid
    IF ifnull(vContent, '') = '' THEN
      --
      SET vContent = c2024_getObjectSummary(objectUidNew, objectType);
      --
    END IF;
    --
    SELECT c.`type` INTO colTypeX FROM collection c WHERE c.id = collectionIdX;
    IF (colTypeX = 3) THEN
       SET vAction = 16; -- Remove
       SET outNotiX = c2023_createNotificationV2(userId, userEmail, collectionIdX, 0, objectUidOld, objectType, vAction, actionTime, NULL, vContent, updatedDate);
    END IF;
   
    SELECT c.`type` INTO colTypeY FROM collection c WHERE c.id = collectionIdY;
    IF (colTypeY = 3) THEN
       SET vAction = 0; -- CREATE
       SET outNotiYDate = updatedDate + 0.001;
       SET outNotiY = c2023_createNotificationV2(userId, userEmail, collectionIdY, 0, objectUidNew, objectType, vAction, actionTime, NULL, vContent, outNotiYDate);
    END IF;
END