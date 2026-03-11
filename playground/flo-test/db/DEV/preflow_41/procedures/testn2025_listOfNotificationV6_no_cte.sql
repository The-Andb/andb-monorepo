CREATE PROCEDURE `testn2025_listOfNotificationV6_no_cte`(
   pnCollectionId     BIGINT(20)
  ,pnChannelId        BIGINT(20)
  ,pvIds              TEXT
  ,pnModifiedGTE      DOUBLE(14,4)
  ,pnModifiedLT       DOUBLE(14,4)
  ,pnMinId            BIGINT(20)
  ,pnPageSize         INTEGER(11)
  ,pnPageNo           INTEGER(11)
  ,pvSort             VARCHAR(128)
  ,pvStatus           VARCHAR(20)
  ,pvObjectType       VARBINARY(250)
  ,pvCategory         VARCHAR(100)
  ,pvAction           VARCHAR(100)
  ,pvAssignment       VARCHAR(20)
  ,pnIncludeShared    TINYINT(1)
  ,pnIncludeReaction  TINYINT(1)
  ,pnIncludePersonal  TINYINT(1)
  ,pnActionByMe       TINYINT(1)
  ,pnUserId           BIGINT(20)
  ,pvUsername         VARCHAR(100)
  ,pnVip              TINYINT(1)
)
BEGIN
  DECLARE nTimeToDel        DOUBLE;
  DECLARE vStatus           VARCHAR(20) DEFAULT IFNULL(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT IFNULL(pvAssignment, '0');
  DECLARE nOFFSET           INT DEFAULT 0;
  DECLARE nActionByMe       INT DEFAULT IFNULL(pnActionByMe, 1);
  DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');
  DECLARE vSort             VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' 
                                                  AND NOT INSTR(pvSort, '-') 
                                                  AND NOT INSTR(pvSort, '+'),
                                                  CONCAT('+', pvSort), pvSort);
  DECLARE nModifiedLT       DOUBLE(14,4) DEFAULT IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, UNIX_TIMESTAMP() + 1);
  DECLARE nModifiedGTE      DOUBLE(14,4) DEFAULT IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0);

  IF IFNULL(pvSort, 'NA') <> 'NA' THEN
    SET nOFFSET = IF(IFNULL(pnPageNo, 0) = 0, 0, (pnPageNo - 1) * pnPageSize);
  END IF;

  SET nTimeToDel = n2025_getMinCreatedDateToShowNotification(pnUserId);

  SELECT 
     cn.id, cn.collection_id, IFNULL(cn.channel_id, 0) channel_id
    ,cn.user_id, cn.content, cn.object_type, cn.object_uid, cn.assignees
    ,IFNULL(cn.actor, '') actor, cn.comment_id, cn.created_date, cn.updated_date
    ,cn.kanban_id, IFNULL(cn.emoji_unicode,'') emoji_unicode, cn.category, cn.is_reply
    ,un.has_mention
    ,IF(cnm.channel_id > 0 ,ifnull(un.`status`, 0), n2025_notificationCallChatReadTransform(cn.object_type
                                        ,un.`status`
                                        ,rculs.last_message_created_date
                                        ,cm.last_seen_call
                                        ,cn.created_date
                                        ,un.updated_date
                                        ,cn.updated_date)) AS `status`
    ,cnm.owner_calendar_uri, cnm.owner_user_id, cnm.owner_email
    ,cnm.member_calendar_uri, cnm.member_email, cnm.member_user_id
    ,cnm.last_seen_chat, cnm.last_seen_call, cn.account_id
    ,CASE
       WHEN cn.object_type IN ('EMAIL', 'GMAIL', 'EMAIL365') THEN cn.actor
       ELSE IFNULL(cn.actor, '')
     END email
    ,CASE
       WHEN cn.action IN (6, 61) AND un.has_mention = 1 THEN 63
       WHEN cn.action IN (30, 31) AND un.has_mention = 1 THEN 33
       ELSE cn.action
     END action
    ,IF(cn.object_type NOT IN ('VEVENT', 'VJOURNAL', 'VTODO'), '',
        CONCAT('/calendarserver.php/calendars/', cn.owner_email, '/', cn.owner_calendar_uri, '/',
               CAST(CONVERT(cn.object_uid USING cp1251) AS CHAR CHARACTER SET latin1), '.ics')) AS object_href
    ,COALESCE(
       (SELECT ce.summary FROM cal_event ce WHERE ce.uid = cn.object_uid AND cn.object_type = 'VEVENT' ORDER BY id DESC LIMIT 1),
       (SELECT cn1.summary FROM cal_note cn1 WHERE cn1.uid = cn.object_uid AND cn.object_type = 'VJOURNAL' ORDER BY id DESC LIMIT 1),
       (SELECT ct.summary FROM cal_todo ct WHERE ct.uid = cn.object_uid AND cn.object_type = 'VTODO' ORDER BY id DESC LIMIT 1),
       (SELECT url.title FROM url WHERE url.uid = cn.object_uid AND cn.object_type = 'URL' ORDER BY id DESC LIMIT 1),
       ''
     ) last_object_title
    ,COALESCE(un.action_time, cn.action_time, 0) AS action_time
  FROM collection_notification_member cnm
  JOIN collection_notification cn 
    ON (
         cn.collection_id = cnm.collection_id 
      OR cn.channel_id = cnm.channel_id 
      OR (cnm.member_user_id = cn.user_id AND cn.collection_id = 0 AND cn.channel_id = 0)
    )
  LEFT JOIN user_notification un 
    ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
  WHERE cnm.member_user_id = pnUserId
    AND cn.created_date >= nTimeToDel
    AND (pnMinId IS NULL OR cn.id > pnMinId)
    AND (pvObjectType IS NULL OR FIND_IN_SET(cn.object_type, pvObjectType))
    AND (pvIds IS NULL OR FIND_IN_SET(cn.id, pvIds))
    AND (cn.action NOT IN (31, 61) OR un.has_mention = 1)
    AND un.deleted_date IS NULL
    AND (cn.action NOT IN (23, 24) OR cn.user_id = pnUserId)
    AND n2025_notificationModifedFilter(un.id, cn.updated_date, un.updated_date, nModifiedLT, nModifiedGTE)
    AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
    AND (
        cnm.channel_id > 0 OR (
            FIND_IN_SET(0, vStatus)
            OR (
              IF(FIND_IN_SET(1, vStatus), UNIX_TIMESTAMP(NOW(3) - INTERVAL 1 DAY) <= cn.created_date, 1)
              AND (
                vStatus = '1'
                OR (FIND_IN_SET(2, vStatus) AND n2025_notificationCallChatReadTransform(cn.object_type, un.status, cnm.last_seen_chat, cnm.last_seen_call, cn.created_date, un.updated_date, cn.updated_date) = 1)
                OR (FIND_IN_SET(3, vStatus) AND n2025_notificationCallChatReadTransform(cn.object_type, un.status, cnm.last_seen_chat, cnm.last_seen_call, cn.created_date, un.updated_date, cn.updated_date) = 0)
                OR (FIND_IN_SET(4, vStatus) AND IFNULL(un.status, 0) = 2)
              )
            )
        )
    )
    AND (cnm.channel_id > 0 OR n2025_notificationStatusFilter(vStatus, un.status, cn.created_date))
    AND n2025_notificationAssignmentFilter(vAssignment, cn.object_uid, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email)
    AND (IFNULL(pnIncludeShared, 0) = 1 OR cn.action NOT IN (20, 21, 22))
    AND IF(IFNULL(pnIncludeReaction, 0) IN (1,3), 1, cn.action <> 23)
    AND IF(IFNULL(pnIncludeReaction, 0) IN (2,3), 1, cn.action <> 24)
    AND IF(IFNULL(pnIncludePersonal, 0) = 1, 1, cn.action NOT IN (19, 30, 31, 70, 80, 81))
    AND (nActionByMe = 1 OR (nActionByMe = 0 AND IFNULL(cn.actor, cn.email) <> pvUsername))
    AND (pvCategory IS NULL OR (IF(cn.object_type <> 'VTODO', 1, FIND_IN_SET(cn.category, pvCategory))))
    AND (cnm.channel_id > 0 OR (cn.created_date >= cnm.last_seen_call AND (cn.action NOT IN (123, 124, 125) OR cn.user_id = pnUserId)))
    AND (cnm.channel_id > 0 OR cnm.collection_id > 0 OR n2025_notificationVipFilter(pnVip, cn.actor, cn.object_type, cn.action, pvUsername, cn.email))
  GROUP BY cn.id
  ORDER BY
    CASE 
      WHEN pnMinId IS NULL AND INSTR(vSort, '-') THEN
        CASE vFieldSort
          WHEN 'action_time' THEN cn.action_time
          WHEN 'updated_date' THEN cn.updated_date
          WHEN 'created_date' THEN cn.created_date
        END
      WHEN pnModifiedLT IS NOT NULL THEN cn.updated_date
    END DESC,
    CASE 
      WHEN pnMinId IS NOT NULL THEN cn.id
      WHEN pnModifiedGTE IS NOT NULL THEN cn.updated_date
      WHEN pnMinId IS NULL AND INSTR(vSort, '+') THEN
        CASE vFieldSort
          WHEN 'action_time' THEN cn.action_time
          WHEN 'updated_date' THEN cn.updated_date
          WHEN 'created_date' THEN cn.created_date
        END
    END ASC
  LIMIT pnPageSize OFFSET nOFFSET;

END