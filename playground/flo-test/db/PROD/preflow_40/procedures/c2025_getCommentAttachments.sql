CREATE PROCEDURE `c2025_getCommentAttachments`(pnCommentIds TEXT)
BEGIN
    -- CONVERT comma-separated string TO JSON array format
    SET @json_ids = CONCAT('[', pnCommentIds, ']');

  SELECT cm.id AS comment_id
         ,sf.uid AS file_uid  
         ,sf.name AS name
         ,sf.size AS size
       ,sf.mimetype AS mimetype
         ,sf.created_date
       FROM JSON_TABLE(@json_ids, '$[*]' 
             COLUMNS(comment_id INT PATH '$')) AS jt
       JOIN collection_comment cm ON cm.id = jt.comment_id
       JOIN storage_file_linked_object sflo ON (sflo.object_id = cm.id 
                                           AND sflo.linked_by = cm.email 
                                           AND sflo.object_type = 2)
       JOIN storage_file   sf ON sf.uid = sflo.file_uid
  LEFT JOIN storage_upload su ON su.file_uid = sf.uid
      WHERE su.id IS NULL OR su.status = 2  -- multipart upload completed
   ORDER BY cm.id ASC, sf.created_date ASC;
END