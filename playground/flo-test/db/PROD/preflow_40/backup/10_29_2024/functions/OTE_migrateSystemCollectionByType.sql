CREATE FUNCTION `OTE_migrateSystemCollectionByType`(
 pvName VARCHAR(255)
,pnType TINYINT(3)) RETURNS INT(11)
BEGIN
   DECLARE no_more_rows     boolean;
   DECLARE nUserId          BIGINT(20);
   DECLARE nUpdatedDate     DOUBLE(13,3);
   DECLARE nID              BIGINT(20);
   DECLARE nReturn          BIGINT(20) DEFAULT 0;
   DECLARE nCount           INT DEFAULT 0;
   DECLARE system_collection_cursor CURSOR FOR
   # Start of: main script
   SELECT u.id user_id, ifnull(MAX(cs.updated_date) + 0.001, unix_timestamp(now(3))) updated_date
         -- ,ifnull(group_concat(cs.`type`), ',') AS collection_type
     FROM user u
LEFT JOIN collection_system cs ON (u.id = cs.user_id AND cs.is_default = 1)
 WHERE u.id IN (133716,
133718,
134595,
134596,
136756,
157847,
182285,
184978,
184983,
184984,
184985,
184989,
185001,
185019,
185100,
185150,
202603,
204300,
206580,
207129,
207694,
208271,
208854,
208897,
208898,
208901,
208903,
208905,
208907,
208910,
208911,
208912,
208926,
209124,
209183,
209184,
209185,
209186,
209187)
 GROUP BY u.id
   HAVING ifnull(group_concat(cs.`type`), '')  NOT LIKE concat('%', pnType, '%');
   # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN system_collection_cursor;
   system_collection_loop: LOOP
     --
     FETCH system_collection_cursor INTO nUserId, nUpdatedDate;
     --
     IF (no_more_rows) THEN
       CLOSE system_collection_cursor;
       LEAVE system_collection_loop;
     END IF;
     -- CHECK IF exist
     SELECT ifnull(max(cs.id), 0)
       INTO nID
       FROM collection_system cs
      WHERE cs.user_id = nUserId
        AND cs.name    = pvName
        AND cs.is_default = 0;
    --
    IF nID > 0 THEN
      --
      UPDATE collection_system cs
         SET cs.is_default = 1
            ,cs.updated_date = nUpdatedDate
       WHERE cs.id = nID
         AND cs.user_id = nUserId;
      --
    ELSE
      --
      INSERT INTO collection_system (user_id, `name`, `type`, is_default, created_date, updated_date)
      VALUES(nUserId, pvName, pnType, 1, nUpdatedDate, nUpdatedDate);     
      --
    END IF;
    --
    SET nReturn = m2023_insertAPILastModify('system_collection', nUserId, nUpdatedDate);
    --
    SET nCount = nCount + 1;
    --
   END LOOP system_collection_loop; 
   --
RETURN nCount;
-- RETURN respond;
END