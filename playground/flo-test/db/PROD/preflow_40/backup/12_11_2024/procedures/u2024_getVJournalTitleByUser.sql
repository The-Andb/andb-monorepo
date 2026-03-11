CREATE PROCEDURE `u2024_getVJournalTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                                  ,pvCalendarUri     VARBINARY(200)
                                                                  ,pnCollectionId    BIGINT(20)
                                                                  ,pnUserId          BIGINT(20)
                                                                  ,pvEmail  VARCHAR(100))
u2024_getVJournalTitleByUser: BEGIN
  --
  IF ifnull(pnCollectionId, 0) > 0 THEN
    --
    SELECT cn.summary title, cn.uid, '' uri
      FROM cal_note cn
      JOIN linked_collection_object lco ON (cn.uid = lco.object_uid)
      JOIN collection co  ON (lco.collection_id = co.id)
      JOIN user usr ON (co.user_id = usr.id)
      JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
     WHERE co.is_trashed = 0
       AND (pnCollectionId IS NULL OR csm.collection_id  = pnCollectionId)
       AND find_in_set(lco.object_uid, pvObjectUid)
       AND lco.is_trashed = 0
       AND csm.member_user_id = pnUserId
       AND lco.object_type = 'VJOURNAL'
       AND csm.shared_status = 1
       AND co.type = 3;
       --
    LEAVE u2024_getVJournalTitleByUser;
    --
  END IF;
  --
  SELECT cn.summary title, cn.uid, cali.uri
    FROM cal_note cn
    JOIN calendarobjects co ON (cn.uid = co.uid)
    JOIN calendarinstances cali ON (cali.calendarid = co.calendarid)
    JOIN principals pp ON (pp.uri = cali.principaluri)
   WHERE pp.uri = concat('principals/', pvEmail)
     AND find_in_set(cn.uid, pvObjectUid)
     AND (pvCalendarUri IS NULL OR cali.uri = pvCalendarUri);
  --
END