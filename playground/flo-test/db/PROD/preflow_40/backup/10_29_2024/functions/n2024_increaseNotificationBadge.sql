CREATE FUNCTION `n2024_increaseNotificationBadge`(
pnNotiId            BIGINT(20)
,pnCollectionId     BIGINT(20)
,pvObjectType       VARBINARY(50)
,pnAction           INT(11)
,pvAssigner         VARCHAR(100)
,pvAssignees        TEXT
,pnCreatedDate      DOUBLE(13,3)
,pnUpdatedDate      DOUBLE(13,3)
,pnUserId           BIGINT(20)
,pvEmail            VARCHAR(100)
) RETURNS INT(11)
BEGIN
  --
  DECLARE nID            INT(11);
  DECLARE nID2           INT(11);
  DECLARE notiID         INT(11);
  DECLARE nAssignment    INT(11);
  -- 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
  SET nAssignment = IF(pvObjectType <> 'VTODO', 0
                      ,CASE
                         WHEN COALESCE(pvAssignees, '') = '' OR pnAction = 18
                           THEN 1 -- 1. NOT assign
                         WHEN find_in_set(pvEmail, pvAssignees) AND pnAction = 17
                           THEN 2 -- 2. assigned TO me
                         WHEN pvAssigner = pvEmail AND pnAction = 17
                           THEN 3 -- 3. assigned BY me
                         ELSE 0
                        END);
    --
  -- make sure increase only 1 WITH notiID provided
  
   SELECT ifnull(max(un.id), 0)
     INTO notiID
    FROM user_notification un
    WHERE un.collection_notification_id = pnNotiId
      AND un.user_id = pnUserId
      AND un.counted = 0;
  --
  IF notiID = 0 THEN
    --
    RETURN 0;
    --
  END IF;
  --
  UPDATE user_notification un
     SET un.counted = 1 -- count only 1 time
   WHERE un.collection_notification_id = pnNotiId
     AND un.user_id = pnUserId;
  --
  SELECT ifnull(max(cnb.id), 0)
    INTO nID
    FROM collection_notification_badge cnb
   WHERE cnb.user_id       = pnUserID
     AND cnb.collection_id = pnCollectionId
     AND cnb.object_type   = pvObjectType
     AND cnb.`action`      = pnAction
     AND cnb.`assigner`    = pvAssigner
     AND cnb.`assignees`   = pvAssignees;
  --
  IF nID > 0 THEN
    -- UPDATE existing UN
    UPDATE collection_notification_badge cnb
       SET cnb.unread       = cnb.unread + 1
          ,cnb.updated_date = pnUpdatedDate
     WHERE cnb.id = nID;
    --
  ELSE
    -- CREATE new badge
    INSERT INTO collection_notification_badge
      (user_id, email, collection_id, unread, object_type, `action`, assigner
      ,`assignment`, assignees, created_date, updated_date)
    VALUES
      (pnUserId, pvEmail, pnCollectionId, 1, pvObjectType, pnAction, pvAssigner
      ,nAssignment, COALESCE(pvAssignees, ''), pnCreatedDate, pnUpdatedDate);
    --
    SELECT last_insert_id() INTO nID;
    --
  END IF;
  --
  RETURN nID;
  --
END