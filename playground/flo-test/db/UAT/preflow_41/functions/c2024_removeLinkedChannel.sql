CREATE FUNCTION `c2024_removeLinkedChannel`(pvUid         VARBINARY(1000)
                                ,pnUserId      BIGINT(20)
                                ,pdDeleteTime  DOUBLE(13,3)) RETURNS INT
BEGIN
  --
  DECLARE nID              BIGINT(20);
  DECLARE nCount           INT DEFAULT 0;
  DECLARE nReturn          INT DEFAULT 0;
  DECLARE vType            VARCHAR(3);
  DECLARE vItemType        VARCHAR(100);
  DECLARE vEmail           VARCHAR(100);
  DECLARE no_more_rows     boolean;
  DECLARE link_cursor CURSOR FOR
  # Start of: main query
 -- 1. remove `linked_collection_object` 
 SELECT DISTINCT(lco.id), 'COL' ltype
   FROM linked_collection_object lco
  WHERE lco.user_id = pnUserId
    AND lco.object_uid = pvUid
    AND lco.object_type = 'CONFERENCING'
  UNION
  -- 2. remove `linked_object`
 SELECT DISTINCT(lo.id), 'OBJ' ltype
   FROM linked_object lo
  WHERE lo.user_id = pnUserId
    AND ((lo.source_object_uid = pvUid AND lo.source_object_type = 'CONFERENCING')
        OR (lo.destination_object_uid = pvUid AND lo.destination_object_type = 'CONFERENCING'))
  UNION
  -- 3. `kanban_card`
 SELECT DISTINCT(kc.id), 'KAN' ltype
   FROM kanban_card kc
  WHERE kc.user_id = pnUserId
    AND kc.object_uid = pvUid
    AND kc.object_type = 'CONFERENCING'
-- 4. `conference_history`
  UNION
 SELECT DISTINCT(ch.id), 'HIS' ltype
   FROM conference_history ch
   JOIN conference_member cm ON (ch.member_id = cm.id)
   JOIN conference_channel cc ON (cm.channel_id = cc.id)
  WHERE ch.user_id = pnUserId
    AND cc.uid = pvUid
    AND cm.user_id = pnUserId
-- 5. `collection_notification`
  UNION
 SELECT DISTINCT(cn.id), 'CON' ltype
   FROM collection_notification cn
   JOIN conference_channel cc ON (cc.id = cn.channel_id)
  WHERE cn.user_id = pnUserId
    AND cc.uid = pvUid
    -- FB-5042 Added some actions related TO channel
    -- CALL_DECLINED = 123
    -- CALL_NOT_ANSWER = 124
    -- CALL_CANCELLED = 125
  AND cn.action IN (23, 30, 31, 123, 124, 125); -- chat notification 23: reaction, 30: new chat, 31: mention
  # END of: main query
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  OPEN link_cursor;
  link_loop: LOOP
    --
    FETCH link_cursor INTO nID, vType;
    --
    IF no_more_rows THEN
      CLOSE link_cursor;
      LEAVE link_loop;
    END IF;
    # main DELETE
    CASE
      WHEN vType = 'COL' THEN 
        -- 1. remove `linked_collection_object`
        SET vItemType = 'COLLECTION_LINK';
        --
        SET nReturn = m2023_insertAPILastModify('linked_collection_object', pnUserId, pdDeleteTime);
        --
        DELETE FROM linked_collection_object
        WHERE user_id = pnUserId
        AND id  = nID;
        --
      WHEN vType = 'OBJ' THEN
        -- 2. remove `linked_object`
        SET vItemType = 'LINK';
        --
        SET nReturn = m2023_insertAPILastModify('linked_object', pnUserId, pdDeleteTime);
        --
        DELETE FROM linked_object
        WHERE user_id = pnUserId
        AND id  = nID;
        --
      WHEN vType = 'KAN' THEN
        -- 3. `kanban_card`
        SET vItemType = 'CANVAS';
        --
        SET nReturn = m2023_insertAPILastModify('kanban', pnUserId, pdDeleteTime);
        --
        DELETE FROM kanban_card
        WHERE user_id = pnUserId
        AND id  = nID;
        --
      WHEN vType = 'HIS' THEN

        -- 4. `conference_history`
        SET vItemType = 'CONFERENCE_HISTORY';
        --
        SET nReturn = m2023_insertAPILastModify('conference_history', pnUserId, pdDeleteTime);
        --
        DELETE FROM conference_history
        WHERE user_id = pnUserId
        AND id  = nID;
        --
    WHEN vType = 'CON' THEN
  
      -- 5. `collection_notification`
      -- Perform a soft DELETE ON ALL user notifications WHEN the user deletes their conference.
      SELECT u.email INTO vEmail
      FROM `user` u 
      WHERE u.id = pnUserId;
      SET nReturn = n2023_softDeleteCollectionNotificationV2(nID, pdDeleteTime, pnUserId, vEmail);
      
       --
    END CASE;
    --
    IF vType <> 'CON' THEN
      INSERT INTO deleted_item
            (item_id, item_type, user_id,  item_uid, is_recovery, created_date, updated_date)
        value (  nID, vItemType, pnUserId,       '',           0,  pdDeleteTime, pdDeleteTime);
    SET nCount = nCount + 1;
  END IF;
    --
    # main DELETE
  END LOOP link_loop;
  --
  RETURN nCount;
  --
END