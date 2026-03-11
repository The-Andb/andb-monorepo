CREATE FUNCTION `n2024_getTotalUnreadNotification_v1`(
 pnCollectionId  BIGINT(20)
,pnUserId        BIGINT(20)
,pvUsername      VARCHAR(100)
,pbNew           TINYINT(1) -- 1: New - 0: ALL Unread
,pvObjectType    VARBINARY(250) -- OR VEVENT, VTODO, VJOURNAL, URL
,pvAction        VARCHAR(100)   -- OR
,pvAssignment    VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me - 4: ALL TODO
) RETURNS INT(11)
BEGIN
  --
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0');
  DECLARE nReturn           INT(11) DEFAULT 0;
  DECLARE bAllAssign        boolean DEFAULT FALSE;
  DECLARE bAllTodo          boolean DEFAULT FALSE;
  --
  IF ifnull(pbNew, 0) = 1 THEN
    SET nReturn = n2024_getTotalUnreadNotification_v0(pnCollectionId, pnUserId, pvUsername
                                                     ,pbNew, pvObjectType, pvAction, pvAssignment);
    RETURN nReturn;
  END IF;
  --
  SET bAllAssign = find_in_set(0, ifnull(pvAssignment, ''));
  SET bAllTodo   = find_in_set(4, ifnull(pvAssignment, ''));
  --
  SELECT sum(cnd.unread)
    INTO nReturn
    FROM collection_notification_badge cnd
   WHERE cnd.user_id        = pnUserId
     AND cnd.collection_id  = pnCollectionId
     AND IF(bAllTodo
           ,cnd.object_type = 'VTODO'
           ,(pvObjectType IS NULL OR find_in_set(cnd.object_type, pvObjectType))
           )
     AND (pvAction     IS NULL OR find_in_set(cnd.`action`, pvAction))
     -- 0: ALL (DEFAULT) 
     AND (find_in_set(0, vAssignment)
           OR (
           cnd.object_type='VTODO' AND (
           -- 4: ALL VTODO
              find_in_set(4, vAssignment)
           -- 1: NOT Assigned
           OR (find_in_set(1, vAssignment) AND (ifnull(cnd.assignees, '') = '' OR cnd.action = 18))
           -- 2: Assigned TO Me 
           OR (find_in_set(2, vAssignment) AND cnd.action = 17 AND find_in_set(pvUsername, ifnull(cnd.assignees, 'NA')))
           -- 3: Assigned BY Me
           OR (find_in_set(3, vAssignment) AND cnd.assigner = pvUsername AND cnd.action = 17)
           )
         )
       )
   GROUP BY cnd.collection_id;
  --
  RETURN nReturn;
  --
END