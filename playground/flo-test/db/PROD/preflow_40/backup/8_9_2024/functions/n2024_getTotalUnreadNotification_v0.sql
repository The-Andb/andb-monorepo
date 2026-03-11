CREATE FUNCTION `n2024_getTotalUnreadNotification_v0`(
 pnCollectionId  BIGINT(20)
,pnUserId        BIGINT(20)
,pvUsername      VARCHAR(100)
,pvObjectType    VARBINARY(250) -- OR VEVENT, VTODO, VJOURNAL, URL
,pvAction        VARCHAR(100)   -- OR
,pvAssignment    VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
) RETURNS INT(11)
BEGIN
  --
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0');
  DECLARE nReturn INT(11) DEFAULT 0;
  --
   SELECT count(*)
     INTO nReturn
     FROM collection_notification cn
LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
     JOIN (
          -- owner existed collection_id
          SELECT co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' member_calendar_uri, '' member_email
                ,0 member_user_id
                ,usr.username owner_username
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
           WHERE co.id = IF(ifnull(pnCollectionId, 0) > 0, pnCollectionId, co.id)
             AND co.`type` = IF(ifnull(pnCollectionId, 0) > 0, co.`type`, 3) -- owner GET BY uid? dont need TO share
             AND co.user_id = pnUserId
          -- member existed collection_id
          UNION
          SELECT co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email
                ,csm.member_user_id
                ,usr.username owner_username
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
           WHERE co.id = IF(ifnull(pnCollectionId, 0) > 0, pnCollectionId, co.id)
             AND ifnull(co.is_trashed, 0) = 0
             AND csm.member_user_id = pnUserId
             AND co.type = 3 -- share only
       ) permission ON (permission.collection_id = cn.collection_id)
    WHERE cn.collection_id = IF(ifnull(pnCollectionId, 0) > 0, pnCollectionId, cn.collection_id)
      AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
      AND IF(isnull(pvAction), 1,
          CASE WHEN find_in_set(6, pvAction)
            THEN (cn.action = 61 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
            ELSE find_in_set(cn.`action`, pvAction)
            END
        )
        -- only GET noti UPDATE comment FOR CASE mention
      AND IF(cn.action = 61, un.has_mention = 1, 1)
      AND IF(isnull(pvObjectType), 1, find_in_set(cn.object_type, pvObjectType))
      -- 0: ALL (DEFAULT) 
      AND (ifnull(un.status, 0) = 0)
      -- 0: ALL (DEFAULT) 
      AND (find_in_set(0, vAssignment)
           OR (
           cn.object_type='VTODO' AND (
           -- 4: ALL VTODO
              find_in_set(4, vAssignment)
           -- 1: NOT Assigned
           OR (find_in_set(1, vAssignment) AND (ifnull(cn.assignees, '') = '' OR cn.action = 18)) -- 18 >> Un-Assigned 
           -- 2: Assigned TO Me 
           OR (find_in_set(2, vAssignment) AND cn.action = 17 AND find_in_set(pvUsername, ifnull(cn.assignees, 'NA')))
           -- 3: Assigned BY Me
           OR (find_in_set(3, vAssignment) AND cn.email = pvUsername AND cn.action = 17)
           )
         )
       )
   GROUP BY c
  ;
  RETURN nReturn;
  --
END