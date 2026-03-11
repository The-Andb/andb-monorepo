CREATE FUNCTION `f2023_collectSortObjectTodo`(pvLinkType   VARCHAR(45)
                                                                             ,pvObjectUid   VARBINARY(1000)
                                                                             ,pvObjectType  VARBINARY(50)
                                                                             ,pnUserID      BIGINT(20)
                                                                             ,pvEmail       VARCHAR(255)
                                                                             ,pnMaxTurn     INT(4)
                                                                             ) RETURNS INT(11)
BEGIN
  --
  DECLARE no_more_rows      boolean;
  DECLARE vObjectUid        VARBINARY(1000);
  DECLARE vObjectType       VARBINARY(50);
  DECLARE nUserId           BIGINT(20);
  DECLARE nLinkId           BIGINT(20);
  DECLARE nLinkType         VARCHAR(45);
  DECLARE dNow              DOUBLE(13,3) DEFAULT unix_timestamp(CURRENT_TIMESTAMP(3));
  DECLARE nCount            INT(11) DEFAULT 0;
  --
   INSERT INTO flo_invalid_link
        (link_id, link_type, object_type, object_uid, user_id, created_date, updated_date)
   SELECT so.id, pvLinkType, so.object_type, so.object_uid, so.user_id, dNow, dNow
     FROM sort_object so
     -- OUTER calendar object aka Invalid link
LEFT JOIN calendarobjects co ON (so.object_uid = co.uid)
    WHERE so.user_id     = ifnull(pnUserID, so.user_id)
      AND so.account_id  = 0
      AND so.object_uid  = ifnull(pvObjectUid, so.object_uid)
      AND so.object_type = 'VTODO'-- ifnull(pvObjectType, so.object_type)
      AND co.id IS NULL
     -- NOT EXISTS FIL aka inserted BEFORE
      AND NOT EXISTS 
            (SELECT 1
               FROM flo_invalid_link fil
              WHERE fil.user_id = so.user_id 
                AND fil.link_type = pvLinkType
                AND fil.object_uid = so.object_uid 
                AND fil.object_type = 'VTODO' -- so.object_type
                AND fil.deleted_date IS NULL
                AND fil.link_id = so.id
            )
    GROUP BY so.id, so.user_id
    ORDER BY so.created_date DESC
    LIMIT pnMaxTurn;
   
  SELECT ROW_COUNT() INTO nCount;
  --
  RETURN ifnull(nCount, 0);
  --
END