CREATE FUNCTION `c2025_conditionSort4ConferenceV2`(
pnUpdatedDate     DOUBLE(13,3)
,pnCreatedDate    DOUBLE(13,3)
,pnLastUsed       DOUBLE(13,3)
,pnLastMsgCreated DOUBLE(13,3)
,pnLastMissedCall DOUBLE(13,3)
,pnFilterType     TINYINT(2)
) RETURNS DOUBLE(13,3)
BEGIN
  --
  RETURN GREATEST(
                  ifnull(pnUpdatedDate, 0)
                        ,pnCreatedDate
                        ,LEAST(
                               ifnull(pnLastUsed, 0)
                              ,ifnull(pnLastMsgCreated, 0)
                              )
                            + IF( -- missed CALL last 24h
                                 pnFilterType IN (1, 4, 8, 11, 12)
                                 AND UNIX_TIMESTAMP(NOW(3) - INTERVAL 1 DAY) < pnLastMissedCall
                                ,pnLastMissedCall
                                ,0
                                )
                         );
  --
END