CREATE PROCEDURE `c2023_createConferenceHistorySendInviteV3`(pnChannelId    BIGINT(20)
                                                                            ,pnUserId          BIGINT(20)
                                                                            ,pnType            TINYINT(1)
                                                                            ,pnStatus          TINYINT(2)
                                                                            ,pvOrganizer       VARCHAR(100)
                                                                            ,pvMemberForce     TEXT
                                                                            ,pvMeetingId       VARCHAR(1000)
                                                                            ,pvExMeetingId     VARCHAR(1000)
                                                                            ,pnUpdatedDate     DOUBLE(13,3))
BEGIN
  --
  --
  DECLARE no_more_rows   boolean;
  DECLARE vMemberSend        TEXT DEFAULT '';
  DECLARE vMemberIgnore       TEXT DEFAULT '';
  DECLARE nUserID        BIGINT(20);
  DECLARE vEmail         VARCHAR(100);
  DECLARE nCMID          BIGINT (20);
  DECLARE nID            BIGINT (20);
  DECLARE nForceCall     TINYINT (1);
  DECLARE nMeetingId     BIGINT(20);

  DECLARE his_cursor CURSOR FOR
  # Start of: main script;
  -- GET FROM user TO prevent 3rd account AND phone number
  SELECT u.id, cm.id, u.email 
    FROM conference_channel cc
    JOIN conference_member cm ON (cc.id = cm. channel_id)
    JOIN user u ON (u. id = cm. user_id)
   WHERE cc.id = pnChannelId
     AND cm.revoke_time = 0
     AND cm.email <> '' -- prevent CALL TO members have only phone number
     AND cm.user_id <> pnUserId
   ;
  # END of: main script
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  OPEN his_cursor;
  his_loop: LOOP
    -- start LOOP his_cursor
    FETCH his_cursor INTO nUserID, nCMID, vEmail;
    -- stop LOOP WHEN no_more_rows
    IF (no_more_rows) THEN
      CLOSE his_cursor;
      LEAVE his_loop;
    END IF;

    IF ifnull(pvMeetingId, '') != '' THEN
      --
      SELECT ifnull(max(cm.id), 0)
        INTO nMeetingId 
        FROM conference_meeting cm
       WHERE cm.meeting_id = pvMeetingId
         AND cm.channel_id = pnChannelId;
      --
      IF nMeetingId = 0 THEN
        --
        INSERT INTO conference_meeting
          (channel_id, user_id, meeting_id, external_meeting_id, created_date, updated_date)
        VALUES
          (pnChannelId, pnUserId, ifnull(pvMeetingId, ''), ifnull(pvExMeetingId, ''), pnUpdatedDate, pnUpdatedDate);
        --
        SET nMeetingId = last_insert_id();
      END IF;
      --
    END IF;
    # main INSERT
    -- CHECK IF the user IS already invited TO the meeting
    -- ..OR FOR TO CALL
    SELECT ifnull(max(ch.id), 0)
      INTO nID
      FROM conference_history ch
     WHERE ch.user_id = nUserID
       AND ch.member_id = nCMID
       AND ch.conference_meeting_id = nMeetingId
       -- AND type = pnType
       AND status  IN (24, 13) -- 24: missing FOR participant, 13: OUT going FOR oganizer
       ;
    --
    SELECT ifnull(max(cm.id), 0)
      INTO nForceCall
      FROM conference_member cm
     WHERE cm.email = vEmail
       AND cm.channel_id = pnChannelId
       AND find_in_set(cm.email, pvMemberForce)
       ;
    --
    IF nID = 0 OR nForceCall THEN
      -- INSERT history
      INSERT INTO conference_history
          (user_id, member_id, invitee, start_time, type, status, organizer, 
          action_time, conference_meeting_id, meeting_id, external_meeting_id, created_date, updated_date) 
      VALUES
          (nUserID, nCMID, vEmail, unix_timestamp(now(3)), pnType, 24, pvOrganizer
          ,unix_timestamp(now(3)), nMeetingId, ifnull(pvMeetingId, ''), ifnull(pvExMeetingId, ''), pnUpdatedDate, pnUpdatedDate);
      -- INSERT invite
      INSERT INTO conference_invite
        (channel_id, user_id, email, `status`, conference_meeting_id, meeting_id, external_meeting_id, created_date,updated_date)
      VALUES
        (pnChannelId, nUserID, vEmail, pnStatus, nMeetingId,ifnull(pvMeetingId, ''), ifnull(pvExMeetingId, ''), pnUpdatedDate, pnUpdatedDate)
        ON DUPLICATE KEY UPDATE updated_date=VALUES(updated_date);

      --
      SET vMemberSend = concat(vMemberSend, vEmail, ',');
      --
      SET nID = last_insert_id();
      --
      UPDATE conference_member cm
         SET cm.last_history_id = nID
       WHERE cm.id = nCMID;
      --
    END IF;
    --
    SET vMemberIgnore = concat(vMemberIgnore, vEmail, ',');
    --
    # main INSERT
  END LOOP his_loop;
  --
  SELECT vMemberSend sendTo, vMemberSend ignoreTo;-- vMemberIgnore ignoreTo;
  --
END