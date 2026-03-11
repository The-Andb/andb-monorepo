CREATE TRIGGER `AFTER_INSERT_CM` AFTER INSERT ON `conference_member` FOR EACH ROW BEGIN
 --
 DECLARE nCNMID             BIGINT(20);
 DECLARE vOwnerUsername     VARCHAR(255) DEFAULT 0;
 DECLARE vOwnerUserId       BIGINT(20) DEFAULT 0;
 DECLARE nCollectionId      BIGINT(20) DEFAULT 0;
 --
 SELECT ifnull(max(cnm.id), 0), COALESCE(cc.collection_id,cnm.collection_id,0), u.username, u.id
   INTO nCNMID, nCollectionId, vOwnerUsername, vOwnerUserId
   FROM collection_notification_member cnm
   JOIN conference_channel cc ON cc.id = cnm.channel_id
   JOIN user u ON cc.user_id = u.id
  WHERE cnm.channel_id = NEW.channel_id
    AND cnm.member_user_id = NEW.user_id;
  --
  IF nCNMID = 0 AND NEW.user_id > 0 THEN
    --
    INSERT INTO collection_notification_member 
           (collection_id, calendarid, channel_id
            ,member_calendar_uri, member_email, member_user_id
            ,owner_calendar_uri ,owner_email, owner_user_id
            ,fk_collection_id, fk_channel_id, fk_cm_id, fk_csm_id, is_active
            ,created_date, updated_date)
      VALUES
            (nCollectionId
            ,0 -- will supply after calendarinstances
            ,NEW.channel_id
            ,'', NEW.email, NEW.user_id
            ,'', vOwnerUsername, vOwnerUserId
            ,nCollectionId, NEW.channel_id, NULL, NEW.id, 1
            ,UNIX_TIMESTAMP(now(3)), UNIX_TIMESTAMP(now(3)));
 ELSE
   --
   UPDATE collection_notification_member cnm
      SET is_active = 1 -- member JOIN > ADD conference
    WHERE cnm.id = nCNMID;
   --
 END IF;
 --
END