CREATE PROCEDURE `OTE_migrateCollectionIdForComment`()
BEGIN

    DECLARE done          INT DEFAULT 0;
    DECLARE nCount        INT(11) DEFAULT 0;
    DECLARE nCollectionId BIGINT(20);
    DECLARE nCommentId    BIGINT(20);

    DECLARE ca_cursor CURSOR FOR
    -- 
    SELECT c2.collection_id, c.id
    FROM collection_comment c 
    JOIN collection_activity c2 ON (c2.id = c.collection_activity_id)
   WHERE c.collection_id = -1;
    -- 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- OPEN the CURSOR
    OPEN ca_cursor;

    col_loop: LOOP
        FETCH ca_cursor INTO nCollectionId, nCommentId;
        
        IF done = 1 THEN
          CLOSE ca_cursor;
            LEAVE col_loop;
        END IF;

        UPDATE collection_comment c 
           SET collection_id = nCollectionId 
         WHERE id = nCommentId;
        -- 
        SET nCount = nCount + 1;
    END LOOP;
        
SELECT nCount `total`;
END