CREATE FUNCTION `n2025_notificationVipFilter`(
pnVip                 TINYINT(1)
,pvActor              VARCHAR(50)
,pvObjectType         VARBINARY(50)
,pnAction             INT(11)
,pvUsername           VARCHAR(100)
,pvNotiEmail          VARCHAR(100)
) RETURNS TINYINT(1)
BEGIN
  DECLARE nVipContactCount        INT DEFAULT 0;

RETURN 1;
  IF pnVip = 0 THEN
  RETURN 1;
  END IF;

  IF pnAction <> 80 THEN
    RETURN 1;
  END IF;

  IF ifnull(pvObjectType, '') NOT IN ('EMAIL', 'EMAIL365', 'GMAIL') THEN
  RETURN 1;
  END IF;
  
  SELECT COUNT(*)
    INTO nVipContactCount
    FROM card_contact cc
    JOIN addressbooks ab ON cc.addressbookid = ab.id
   WHERE ab.uri = pvNotiEmail
     AND cc.vip = 1 AND find_in_set(pvActor, cc.email_text);
  
  IF nVipContactCount = 0 THEN
  RETURN 0;
  END IF;

  RETURN 1;
  --
END