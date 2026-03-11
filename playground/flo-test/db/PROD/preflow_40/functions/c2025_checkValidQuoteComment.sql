CREATE FUNCTION `c2025_checkValidQuoteComment`(pvObjectUid           VARBINARY(1000)
                                                           ,pnQuoteCommentId     BIGINT(20)
                                                          ) RETURNS TINYINT(1)
BEGIN
    DECLARE vQuoteObjectUid    VARBINARY(1000) DEFAULT '';

    -- 
  IF IFNULL(pnQuoteCommentId, 0) > 0 THEN
    SELECT IFNULL(ca.object_uid, '')
          INTO vQuoteObjectUid
          FROM collection_comment cc
          JOIN collection_activity ca ON (cc.collection_activity_id = ca.id)
         WHERE cc.id = pnQuoteCommentId;
  END IF;
  
  -- quote comment must be IN the same object
  IF (vQuoteObjectUid <> '' AND vQuoteObjectUid <> pvObjectUid) THEN
    RETURN -7;
  END IF;
  
  RETURN 0;

END