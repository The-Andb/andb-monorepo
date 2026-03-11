CREATE FUNCTION `c2022_sendLastModifyShare`(pvApiName             VARCHAR(255)
                                                              ,pnCollectionId        BIGINT(20)
                                                              ,pnLastModifyDate      DOUBLE(13,3)) RETURNS INT
BEGIN
  --
  DECLARE nUserId      BIGINT(20);
  DECLARE no_more_rows boolean;
  DECLARE nReturn      BIGINT(20)  DEFAULT 0;
  DECLARE vApiName     VARCHAR(255);
  DECLARE api_cursor CURSOR FOR 
  -- 1. GET ALL user id IN 1 collection BOTH owner AND member
  SELECT co.user_id, pvApiName api_name
    FROM collection co
   WHERE co.id = pnCollectionId
  UNION
  SELECT csm.member_user_id user_id
        ,(CASE pvApiName 
        WHEN 'file' THEN 'file_member'
        WHEN 'linked_object' THEN 'linked_object_member'
        WHEN 'linked_collection_object' THEN 'linked_collection_object_member'
        ELSE pvApiName END
         ) api_name
    FROM collection_shared_member csm
   WHERE csm.collection_id = pnCollectionId;
  --
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  OPEN api_cursor;
  api_loop: LOOP
    --
    FETCH api_cursor INTO nUserId, vApiName;
    --
    IF (no_more_rows) THEN
      CLOSE api_cursor;
      LEAVE api_loop;
    END IF;
    
    # 2. main UPDATE
    SET nReturn = m2023_insertAPILastModify(vApiName, nUserId, pnLastModifyDate);
    --
    -- IF we send api name collection_history ELSE ...
    -- ... we also need TO send FOR the collection activity too
    IF vApiName = 'collection_history' THEN 
      # main UPDATE
      SET nReturn = m2023_insertAPILastModify('collection_activity', nUserId, pnLastModifyDate);
      --
    END IF;
    --
  END LOOP api_loop;
  --
  RETURN nReturn;
  --
END