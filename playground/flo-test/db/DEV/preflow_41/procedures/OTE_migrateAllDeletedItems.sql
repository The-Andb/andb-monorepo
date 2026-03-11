CREATE PROCEDURE `OTE_migrateAllDeletedItems`()
BEGIN
    DECLARE nUserId BIGINT;
    DECLARE done    INT DEFAULT 0;
    DECLARE nBatch  INT DEFAULT 0;

    DECLARE cur CURSOR FOR
     SELECT DISTINCT di.user_id
       FROM deleted_item di
      WHERE di.created_sec >= UNIX_TIMESTAMP('2025-08-01 00:00:00')
        AND di.created_sec <  UNIX_TIMESTAMP(NOW(3))
         ;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO nUserId;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- gọi migrate từng user
        CALL OTE_migrateDeletedItemChunk(nUserId);

        SET nBatch = nBatch + ROW_COUNT();
    END LOOP;

    CLOSE cur;

    SELECT CONCAT('Migrate finished. Total rows inserted/updated: ', nBatch) AS result;
END