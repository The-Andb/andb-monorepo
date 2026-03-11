CREATE PROCEDURE `OTE_migrateAgileKanbanForAll`()
BEGIN

    DECLARE done    INT DEFAULT 0;
    DECLARE nCount  INT(11) DEFAULT 0;
    DECLARE nUserId BIGINT(20);
    DECLARE nReturn INT DEFAULT 0;
    DECLARE nMigrated  INT(11) DEFAULT 0;

    DECLARE user_cursor CURSOR FOR
    -- 
    SELECT u.id
      FROM `user` u
     WHERE u.disabled = 0
       AND u.migrated = 0;
    -- 
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- OPEN the CURSOR
    OPEN user_cursor;

    col_loop: LOOP
        FETCH user_cursor INTO nUserId;
        
        IF done = 1 THEN
          CLOSE user_cursor;
            LEAVE col_loop;
        END IF;

        SET nReturn = OTE_migrateAgileKanban(nUserId);
        IF nReturn <> 0 THEN
          SET nMigrated = nMigrated + 1;
          UPDATE `user` SET migrated = 1 WHERE id = nUserId;
        END IF;
        SET nCount = nCount + 1;
    END LOOP;
        
SELECT nCount `total`, nMigrated migrated;
END