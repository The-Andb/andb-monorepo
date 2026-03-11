CREATE FUNCTION `o2025_getObjectTitle_V2`(
pvObjectType          VARBINARY(50)
,pvObjectUid           VARBINARY(1000)
,pnCollectionId        BIGINT
) RETURNS VARCHAR(1000) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
BEGIN
  --
  DECLARE vContent      VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  DECLARE nCalendarId   INT DEFAULT 0;
  DECLARE vCalendarUri  VARCHAR(255);
  --
  -- GET calendarid BY collection_id
  IF pnCollectionId IS NOT NULL AND pnCollectionId > 0 THEN
    SELECT ci.calendarid INTO nCalendarId
      FROM collection co
      JOIN calendarinstances ci ON ci.uri = co.calendar_uri
     WHERE co.id = pnCollectionId
     LIMIT 1;
  END IF;
  --
  CASE ifnull(pvObjectType, '')
    --
    WHEN 'URL' THEN
      --
      SELECT ifnull(u.title, '') 
        INTO vContent 
        FROM url u
       WHERE u.uid = pvObjectUid
       LIMIT 1;
      --
    WHEN 'VTODO' THEN
      --
      SELECT ifnull(ct.summary, '')
        INTO vContent 
        FROM cal_todo ct 
       WHERE ct.uid = pvObjectUid
         AND ct.calendarid = nCalendarId
       LIMIT 1;
      --
    WHEN 'VEVENT' THEN
      --
      SELECT ifnull(ce.summary, '')
        INTO vContent 
        FROM cal_event ce 
       WHERE ce.uid = pvObjectUid
         AND ce.calendarid = nCalendarId
       LIMIT 1;
      --
    WHEN 'VJOURNAL' THEN
      --
      SELECT ifnull(cn.summary, '')
        INTO vContent
        FROM cal_note cn
       WHERE cn.uid = pvObjectUid
         AND cn.calendarid = nCalendarId
       LIMIT 1;
    ELSE
      --
      SET vContent = ''; 
      --
  END CASE;
  --
  RETURN vContent;
  --
END