CREATE FUNCTION `n2025_notificationModifedFilter`(
 pnUsrNotiID        BIGINT
,pnUpdatedDateN     DOUBLE(14,4)
,pnUpdatedDateU     DOUBLE(14,4)
,pnModifiedLT       DOUBLE(14,4)
,pnModifiedGTE      DOUBLE(14,4)
) RETURNS TINYINT(1)
BEGIN
  --
  RETURN IF (pnUsrNotiID IS NULL, pnUpdatedDateN <  pnModifiedLT,  pnUpdatedDateU <  pnModifiedLT)
     AND IF (pnUsrNotiID IS NULL, pnUpdatedDateN >= pnModifiedGTE, pnUpdatedDateU >= pnModifiedGTE);
  --
END