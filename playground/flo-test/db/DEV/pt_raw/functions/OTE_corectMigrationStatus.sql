CREATE FUNCTION `OTE_corectMigrationStatus`() RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nID                 INT DEFAULT 0;
    DECLARE nCollectionID       INT DEFAULT 0;
    DECLARE nTotal              INT DEFAULT 0;
    DECLARE nTotalMember        INT DEFAULT 0;
    DECLARE nTotalExport        INT DEFAULT 0;
    DECLARE nTotalMigrate       INT DEFAULT 0;
    DECLARE nCalendarID         INT DEFAULT 0;
    DECLARE vCalendarURI        VARCHAR(255);
    DECLARE ms_cursor CURSOR FOR
    # Start of: main script;
    SELECT ms.id, ms.total_story, ms.collection_id, ms.calendar_uri
      FROM pt_migration_status ms
     -- WHERE ms.export_process = 'failed'
     ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN ms_cursor;
   ms_loop: LOOP
     -- start LOOP ms_cursor
     FETCH ms_cursor 
      INTO nID, nTotal, nCollectionID, vCalendarURI;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE ms_cursor;
       LEAVE ms_loop;
     END IF;
     # main UPDATE
     -- count total story exported
     SELECT count(*)
       INTO nTotalExport
       FROM pt_story ps
      WHERE ps.project_id = nID;
     -- count total story migrated
     SELECT count(*)
       INTO nTotalMigrate
       FROM preflow_41.linked_collection_object lco
      WHERE lco.collection_id = nCollectionID;
     -- count total members
     SELECT count(*)
       INTO nTotalMember
       FROM pt_project_member pm
      WHERE pm.project_id = nID;
     -- find calendar id
     SELECT ci.calendarid
       INTO nCalendarID
       FROM preflow_41.calendarinstances ci
       WHERE ci.uri = vCalendarURI;
     --
     UPDATE pt_migration_status ms
        SET ms.exported_story = nTotalExport
           ,ms.total_member   = nTotalMember
           ,ms.calendarid     = nCalendarID
           ,ms.total_story    = IF(ms.total_story < nTotalExport, nTotalExport, ms.total_story)
           ,ms.export_process = IF(nTotalExport >= nTotal, 'success', 'failed')
           ,ms.migrated_story = IF(ms.migrated_story < nTotalMigrate, nTotalMigrate, ms.total_story)
           ,ms.migrate_process = IF(nTotalMigrate = nTotal, 'success', 'failed')
      WHERE ms.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
  END LOOP ms_loop;
  --
  RETURN nCount;
  --
END