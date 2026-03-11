CREATE PROCEDURE `u2024_getVJournalTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                                  ,pvCalendarUri     VARBINARY(200)
                                                                  ,pnCollectionId    BIGINT(20)
                                                                  ,pnUserId          BIGINT(20)
                                                                  ,pvEmail  VARCHAR(100))
u2024_getVJournalTitleByUser: BEGIN
  --
  IF ifnull(pnCollectionId, 0) > 0 THEN
    --
    SELECT cn.summary title, cn.uid, '' uri, lco.is_trashed
      FROM cal_note cn
      JOIN linked_collection_object lco ON (cn.uid = lco.object_uid)
      JOIN collection co  ON (lco.collection_id = co.id)
      JOIN user usr ON (co.user_id = usr.id)
      JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
     WHERE (pnCollectionId IS NULL OR csm.collection_id  = pnCollectionId)
       AND find_in_set(lco.object_uid, pvObjectUid)
       AND lco.object_type = 'VJOURNAL'
       AND (co.user_id = pnUserId OR (
             csm.member_user_id = pnUserId
             AND csm.shared_status = 1
        ))
       AND co.type = 3
     GROUP BY lco.id
     ORDER BY lco.id DESC;
    --
    LEAVE u2024_getVJournalTitleByUser;
    --
  END IF;
  --
  SELECT cn.summary title, cn.uid, cali.uri, ifnull(tc.id, 0) > 0 AS is_trashed
    FROM cal_note cn
    JOIN calendarobjects co ON (cn.uid = co.uid)
    JOIN calendarinstances cali ON (cali.calendarid = co.calendarid)
    JOIN principals pp ON (pp.uri = cali.principaluri)
LEFT JOIN trash_collection tc ON (cn.uid = tc.object_uid AND tc.object_type = 'VJOURNAL' AND tc.user_id = pnUserId)
   WHERE pp.uri = concat('principals/', pvEmail)
     AND find_in_set(cn.uid, pvObjectUid)
     AND (pvCalendarUri IS NULL OR cali.uri = pvCalendarUri)
   ORDER BY cn.id DESC;
  --
END