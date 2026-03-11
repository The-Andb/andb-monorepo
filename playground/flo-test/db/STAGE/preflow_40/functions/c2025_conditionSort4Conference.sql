CREATE FUNCTION `c2025_conditionSort4Conference`(
pnLastHistory       DOUBLE(13,3)
,pnCreatedDate      DOUBLE(13,3)
,pnLastUsed         DOUBLE(13,3)
,pnLastMsgCreated   DOUBLE(13,3)
,pnLastMissedCall   DOUBLE(13,3)
,pnFilterType       TINYINT(2)
,pnApplySetting     TINYINT(1)
,pnNotificationCall TINYINT(1)
) RETURNS DOUBLE(13,3)
BEGIN
  --
  RETURN GREATEST(
                  -- last history
                  ifnull(pnLastHistory, 0)
                  -- channel created
                  ,pnCreatedDate
                  -- greatest of last used AND last channel's mesage created
                  ,GREATEST(
                         ifnull(pnLastUsed, 0)
                        ,ifnull(pnLastMsgCreated, 0)
                        )
                      + IF( -- missed CALL last 24h
                           pnFilterType IN (1, 4, 8, 11, 12) 
                           -- CHECK apply setting?
                           AND (pnApplySetting = 0 OR pnNotificationCall = 1)
                           -- SET last missed CALL IN 24h TO top
                           AND UNIX_TIMESTAMP(NOW(3) - INTERVAL 1 DAY) < pnLastMissedCall
                          ,pnLastMissedCall
                          ,0
                          )
                   );
  --
END