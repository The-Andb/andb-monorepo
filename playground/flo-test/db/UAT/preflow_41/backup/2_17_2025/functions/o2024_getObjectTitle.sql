CREATE FUNCTION `o2024_getObjectTitle`(
pvObjectType          VARBINARY(50)
,pvObjectUid           VARBINARY(1000)
) RETURNS VARCHAR(1000) CHARSET utf8mb3 COLLATE utf8mb3_unicode_ci
BEGIN
  --
  DECLARE vContent      VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
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
       LIMIT 1;
      --
    WHEN 'VEVENT' THEN
      --
      SELECT ifnull(ce.summary, '')
        INTO vContent 
        FROM cal_event ce 
       WHERE ce.uid = pvObjectUid 
       LIMIT 1;
      --
    WHEN 'VJOURNAL' THEN
      --
      SELECT ifnull(cn.summary, '')
        INTO vContent
        FROM cal_note cn
       WHERE cn.uid = pvObjectUid
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