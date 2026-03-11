CREATE FUNCTION `n2024_decreaseNotificationBadge`(
 pnNotiId           BIGINT(20)
,pnCreatedDate      DOUBLE(13,3)
,pnUpdatedDate      DOUBLE(13,3)
,pnUserId           BIGINT(20)
,pvEmail            VARCHAR(100)
) RETURNS INT
BEGIN
  --
  DECLARE nID            INT(11);
  DECLARE nID2           INT(11);
  DECLARE nCollectionId  BIGINT(20);
  DECLARE vObjectType    VARBINARY(50);
  DECLARE nAction        INT(11);
  DECLARE vAssigner      VARCHAR(100);
  DECLARE vAssignees     TEXT;
  DECLARE nAssignment    TINYINT(1);
  --
  RETURN 1;
  --
  IF pnNotiId IS NULL THEN
    --
    RETURN 0;
    --
  END IF;
  --
  SELECT cn.collection_id, cn.object_type, cn.`action`, cn.email, cn.assignees
    INTO nCollectionId, vObjectType, nAction, vAssigner, vAssignees
    FROM collection_notification cn
   WHERE cn.id = pnNotiId;
   -- 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
   SET nAssignment = IF(vObjectType <> 'VTODO', 0
                       ,CASE 
                          WHEN COALESCE(vAssignees, '') = '' OR nAction = 18
                            THEN 1 -- 1. NOT assign
                          WHEN find_in_set(pvEmail, vAssignees) AND nAction = 17
                            THEN 2 -- 2. assigned TO me
                          WHEN vAssigner = pvEmail  AND nAction = 17
                            THEN 3 -- 3. assigned BY me
                          ELSE 0
                        END);
  --
  SELECT ifnull(max(cnb.id), 0)
    INTO nID
    FROM collection_notification_badge cnb
   WHERE cnb.user_id       = pnUserID
     AND cnb.collection_id = nCollectionId
     AND cnb.object_type   = vObjectType
     AND cnb.`action`      = nAction
     AND cnb.assigner      = vAssigner
     AND cnb.`assignees`   = vAssignees;
  --
  IF nID > 0 THEN
    -- UPDATE existing UN
    UPDATE collection_notification_badge cnb
       SET cnb.unread       = CASE WHEN cnb.unread < 1 THEN 0 ELSE cnb.unread - 1 END
          ,cnb.updated_date = pnUpdatedDate
     WHERE cnb.id = nID;
    --
  END IF;
  --
  RETURN nID;
  --
END