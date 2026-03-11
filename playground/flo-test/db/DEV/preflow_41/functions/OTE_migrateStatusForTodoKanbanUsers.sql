CREATE FUNCTION `OTE_migrateStatusForTodoKanbanUsers`() RETURNS INT
BEGIN

    DECLARE done    INT DEFAULT 0;
    DECLARE nCount  INT(11) DEFAULT 0;
    DECLARE nUserId BIGINT(20);
    DECLARE nReturn INT DEFAULT 0;

    DECLARE users_cursor CURSOR FOR
    SELECT u.id FROM `user` u WHERE u.disabled = 0 AND u.migrated = 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- OPEN the CURSOR
    OPEN users_cursor;

    users_loop: LOOP
        FETCH users_cursor INTO nUserId;
        
        IF done = 1 THEN
          CLOSE users_cursor;
            LEAVE users_loop;
        END IF;

        SET nReturn = OTE_migrateStatusForTodoKanban("Status for ToDo's", nUserId);
        SET nCount = nCount + 1;
    END LOOP;
        
RETURN nCount;
END