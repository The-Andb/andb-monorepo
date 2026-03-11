CREATE FUNCTION `OTE_createAuditLog`(
 pvTable      VARCHAR(100)
,pvOperation  VARCHAR(10)
,pnRecordId   BIGINT
,pjOld        JSON
,pjNew        JSON
) RETURNS TINYINT(1)
    DETERMINISTIC
BEGIN
  INSERT INTO audit_log (`table_name`, operation, record_id, old_data, new_data, created_at)
  VALUES (pvTable, pvOperation, pnRecordId, pjOld, pjNew, NOW());
  RETURN TRUE;
END