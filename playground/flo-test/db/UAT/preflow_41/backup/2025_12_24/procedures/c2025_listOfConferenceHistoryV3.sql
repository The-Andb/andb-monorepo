CREATE PROCEDURE `c2025_listOfConferenceHistoryV3`(pvKeyword         TEXT
                                                                   ,pvChannelIDs      TEXT
                                                                   ,pvIDs             TEXT
                                                                   ,pnMinId           BIGINT(20)
                                                                   ,pnPageSize        INTEGER(11)
                                                                   ,pnPageNo          INTEGER(11)
                                                                   ,pvSort            VARCHAR(128)
                                                                   ,pnGroupMeetingID  TINYINT(1)
                                                                   ,pnModifiedGTE     DOUBLE(14,4)
                                                                   ,pnModifiedLT      DOUBLE(14,4)
                                                                   ,pnCreatedBefore   DOUBLE(14,4)
                                                                   ,pnCreatedAfter    DOUBLE(14,4)
                                                                   ,pnUserId          BIGINT(20)
                                                                   ,pvEmail           VARCHAR(100))
BEGIN
  -- CALL c2023_listOfConferenceHistory(?,?,?,?,?,?,?,?,?,?) -- PARAMETERS: [NULL,NULL,46429,"579987",NULL,NULL,NULL,2,NULL,NULL]
  -- GET conference history WITH duration
  DECLARE nOFFSET       INT(11) DEFAULT 0;
  DECLARE bGroupMI      TINYINT(1) DEFAULT ifnull(pnGroupMeetingID, 0);
  DECLARE vFieldSort    VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');
  DECLARE vSort         VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> ''
                         AND NOT instr(pvSort, '-') 
                         AND NOT instr(pvSort, '+'), concat('+', pvSort), pvSort);
  DECLARE vKeyword TEXT DEFAULT concat('%', ifnull(pvKeyword, ''), '%');
  --
  SET nOFFSET = IF(ifnull(pnPageNo, 0) > 0, (pnPageNo - 1) * pnPageSize, 0);
  --
  SET SESSION group_concat_max_len = 500000;
  --
  SELECT ch.id, ch.invitee, ch.phone_number, ifnull(ch.attendees, '[]') lsAttendees
        ,ch.start_time, ch.end_time
        ,ch1.durations
        ,ch.action_time, ch.type, ch.status, ch.organizer, ch.meeting_id
        ,cc.id channel_id
        ,ch.external_meeting_id, ch.is_reply
        ,ch.created_date, ch.updated_date
    FROM conference_history ch
    JOIN (
      SELECT max(ch.created_date) created_date
            ,ch.meeting_id
            ,CONCAT('[',GROUP_CONCAT(
           JSON_OBJECT('start_time', ch.start_time, 'end_time', ch.end_time, 'status', ch.status)
         ),']') durations
        FROM conference_history ch
        JOIN conference_member cm ON (ch.member_id = cm.id)
        JOIN conference_channel cc ON (cm.channel_id = cc.id)
       WHERE ch.user_id = pnUserId
        -- AND ch.updated_date  <  IF(ifnull(pnModifiedLT,    0) > 0, pnModifiedLT, unix_timestamp() + 1)
        -- AND ch.updated_date  >= IF(ifnull(pnModifiedGTE,   0) > 0, pnModifiedGTE, 0)
        -- AND ch.created_date  <  IF(ifnull(pnCreatedBefore, 0) > 0, pnCreatedBefore, unix_timestamp() + 1)
        -- AND ch.created_date  >= IF(ifnull(pnCreatedAfter,  0) > 0, pnCreatedAfter, 0)
        AND (pnMinId IS NULL OR ch.id > pnMinId)
        AND (pvIDs IS NULL OR FIND_IN_SET(ch.id, pvIDs))
        AND (pvChannelIDs IS NULL OR FIND_IN_SET(cc.id, pvChannelIDs))
      GROUP BY CASE 
                 WHEN bGroupMI = 1 THEN ch.meeting_id 
                 ELSE ch.id
               END
       ) ch1 ON (ch1.meeting_id = ch.meeting_id AND ch1.created_date = ch.created_date)
    JOIN conference_member cm ON (ch.member_id = cm.id)
    JOIN conference_channel cc ON (cm.channel_id = cc.id)
   WHERE ch.user_id = pnUserId
     AND ch.updated_date  <  IF(ifnull(pnModifiedLT,    0) > 0, pnModifiedLT, unix_timestamp() + 1)
     AND ch.updated_date  >= IF(ifnull(pnModifiedGTE,   0) > 0, pnModifiedGTE, 0)
     AND ch.created_date  <  IF(ifnull(pnCreatedBefore, 0) > 0, pnCreatedBefore, unix_timestamp() + 1)
     AND ch.created_date  > IF(ifnull(pnCreatedAfter,  0) > 0, pnCreatedAfter, 0)
     AND (pnMinId IS NULL OR ch.id > pnMinId)
     AND (pvIDs IS NULL OR FIND_IN_SET(ch.id, pvIDs))
     AND (pvChannelIDs IS NULL OR FIND_IN_SET(cc.id, pvChannelIDs))
   ORDER BY 
    --
    (CASE WHEN ifnull(vSort,'') <> '' THEN
       --
       CASE WHEN INSTR(vSort, "-") THEN
         --
         CASE vFieldSort
           --
           WHEN 'action_time' THEN ch.action_time
           WHEN 'created_date' THEN ch.created_date
           WHEN 'updated_date' THEN ch.updated_date
           ELSE ch.updated_date
           --
          END
     --
         END
         WHEN ifnull(pnModifiedLT, 0) > 0 THEN ch.updated_date
     --
      END) DESC,
    (CASE WHEN ifnull(vSort,'') <> '' THEN
       --
       CASE WHEN INSTR(vSort, "+") THEN
         --
         CASE vFieldSort 
           --
           WHEN 'action_time' THEN ch.action_time
           WHEN 'created_date' THEN ch.created_date
           WHEN 'updated_date' THEN ch.updated_date
           --
          END
         --
        END
        WHEN ifnull(pnModifiedGTE, 0) > 0 THEN ch.updated_date 
        WHEN ifnull(pnMinId, 0) > 0 THEN ch.id
       -- ELSE ch.id
      END) ASC
    --
   LIMIT pnPageSize
  OFFSET nOFFSET;
  --
  SET SESSION group_concat_max_len = 1024;
  --
END