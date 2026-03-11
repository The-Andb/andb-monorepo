CREATE FUNCTION `n2025_notificationCallChatReadTransform`(
pvObjectType     VARBINARY(50)
,pnStatus        TINYINT(1)
,pnLastSeenChat  DOUBLE(13,3)
,pnLastSeenCall  DOUBLE(13,3)
,pnCreatedDate   DOUBLE(13,3)
,pnUpdatedDateN  DOUBLE(13,3)
,pnUpdatedDateU  DOUBLE(13,3)
) RETURNS TINYINT(1)
BEGIN
  --
  DECLARE nStatus TINYINT(1) DEFAULT ifnull(pnStatus, 0);
  --
  RETURN IF(nStatus > 0, nStatus
           ,CASE
              WHEN pvObjectType = 'CHAT'
              THEN nStatus = 0 
                  AND IFNULL(pnLastSeenChat, 0) > 0
                  AND pnLastSeenChat >= GREATEST(pnCreatedDate, ifnull(pnUpdatedDateU, pnUpdatedDateN))
              WHEN pvObjectType = 'CALL'
              THEN nStatus = 0 
                  AND IFNULL(pnLastSeenCall, 0) > 0
                  AND pnLastSeenCall >= GREATEST(pnCreatedDate, ifnull(pnUpdatedDateU, pnUpdatedDateN))
              ELSE nStatus
            END);
  --
END