CREATE FUNCTION `OTE_patchCalendarInstances4Migrate`() RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nReturn             BIGINT DEFAULT 0;
    DECLARE nID                 INT DEFAULT 0;
    DECLARE nCollectionID       INT DEFAULT 0; 
    DECLARE nCalendarID         INT DEFAULT 0;
    DECLARE nCSMID              INT DEFAULT 0;
    DECLARE nCalInsID           INT DEFAULT 0;
    DECLARE nUserId             BIGINT(20) DEFAULT 0;
    DECLARE nOwnerUserId        BIGINT(20) DEFAULT 0;
    DECLARE vOwnerEmail         VARCHAR(255);
    DECLARE vEmail              VARCHAR(255);
    DECLARE vName               VARCHAR(255);
    DECLARE vURI                VARCHAR(255);
    DECLARE vColor              VARCHAR(20);
    DECLARE bIsOwner            BOOL;
    DECLARE nRole               TINYINT(1);
    DECLARE nAccess             TINYINT(1);
    DECLARE nUpdatedDate        DOUBLE(13,3) DEFAULT unix_timestamp(NOW(3));
   
    DECLARE ms_cursor CURSOR FOR
    # Start of: main script;
    SELECT pms.id, pms.name, pms.collection_id, pms.calendarid
          ,pum.flo_email, pum.flo_user_id, (uu.email = pum.flo_email) isOwner, uu.id
          ,ifnull(csm.id, 0)
          ,(CASE 
             WHEN ppm.role IN ('owner','member') THEN 2
             WHEN ppm.role = 'viewer' THEN 1
            END
          ) vrole
          ,(CASE
             -- ACCESS_OWNER = 1;
             WHEN (uu.email = pum.flo_email) THEN 1
             -- ACCESS_READWRITE = 3;
             WHEN ppm.role IN ('owner','member') THEN 3
             -- ACCESS_READ = 2;
             WHEN ppm.role = 'viewer' THEN 2
            END
          ) vaccess
          ,co.color
      FROM pt_raw.pt_migration_status pms
      JOIN preflow_40.collection co ON pms.collection_id = co.id
      JOIN preflow_40.user uu ON uu.id = co.user_id
      JOIN pt_raw.pt_project_member ppm ON ppm.project_id = pms.id
      JOIN pt_raw.pt_user_mapping pum ON ppm.person_email = pum.pt_email
      LEFT JOIN preflow_40.collection_shared_member csm ON (csm.collection_id = pms.collection_id 
                                                            AND csm.shared_email = pum.flo_email
                                                            )
      LEFT JOIN preflow_40.calendarinstances ci ON (pms.calendarid = ci.calendarid
                                                AND (co.calendar_uri = ci.uri OR csm.calendar_uri = ci.uri)
                                                AND ci.principaluri = concat('principals/', pum.flo_email)
                                              )
     WHERE pms.id IN (1033574,1171660,1177210,1215470,1481472,1654355,2119982,2322037,2350530,2438691)
     AND pum.flo_email IS NOT NULL
     AND (
         -- owner OR member lose calendar instance (CI)
         ci.id IS NULL 
         -- member lost csm
          OR (csm.id IS NULL AND pum.flo_email <> uu.email)
          )
     GROUP BY pms.id, ppm.id
     ORDER BY pms.id, csm.shared_email;
     
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN ms_cursor;
   ms_loop: LOOP
     -- start LOOP ms_cursor
     FETCH ms_cursor 
      INTO nID, vName, nCollectionID, nCalendarID
          ,vEmail, nUserId, bIsOwner, nOwnerUserId
          ,nCSMID, nRole, nAccess, vColor;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE ms_cursor;
       LEAVE ms_loop;
     END IF;
     # main UPDATE
     SET nUpdatedDate = nUpdatedDate + nCount;
     -- CHECK missing CALENDAR INSTANCES THEN created
     SELECT ifnull((
         SELECT ci.uri
           FROM preflow_40.calendarinstances ci
          WHERE ci.calendarid = nCalendarID
            AND ci.principaluri = concat('principals/', vEmail)
       ), 'NA')
      INTO vURI
      FROM DUAL;
         
     --
     IF vURI = 'NA' THEN
       --
       SET vURI = UUID();
       --
        INSERT INTO `preflow_40`.`calendarinstances`
        (`calendarid`,`principaluri`,`access`,`displayname`,`uri`,`description`,`calendarorder`,`calendarcolor`
         ,`transparent`,`share_href`,`share_displayname`,`share_invitestatus`,`timezone`)
        VALUES
        (nCalendarID,concat('principals/', vEmail), nAccess, vName, vURI, vName, 0, vColor
        ,1,concat('mailto:', vEmail), vName, 2
        ,"BEGIN:VCALENDAR
                    PRODID:-//Floware/Flo//END 
                    VERSION:0.2.0 
                    BEGIN:VTIMEZONE 
                    TZID:Asia/Ho_Chi_Minh
                    END:VTIMEZONE
                    END:VCALENDAR
                    ");
       --
     END IF;
     --
     IF bIsOwner THEN
       -- UPDATE calendar instance for owner
       UPDATE preflow_40.collection co
          SET co.calendar_uri = vURI
             ,csm.updated_date = nUpdatedDate
        WHERE co.id = nCollectionID;
       --
       SET nReturn = preflow_40.m2023_insertAPILastModify('collection', nOwnerUserId, nUpdatedDate);
       -- 
     ELSEIF nCSMID > 0 THEN
       -- UPDATE calendar instance for member
       UPDATE preflow_40.collection_shared_member csm
          SET csm.calendar_uri = vURI
             ,csm.updated_date = nUpdatedDate
        WHERE csm.id = nCSMID;
       --
       SET nReturn = preflow_40.m2023_insertAPILastModify('collection_member', nUserId, nUpdatedDate);
       -- CHECK missing CSM
     ELSEIF nCSMID = 0 AND !bIsOwner THEN
       -- INSERT CSM
         INSERT INTO `preflow_40`.`collection_shared_member`
            (`user_id`, `collection_id`, `calendar_uri`, `access`, `shared_status`, `shared_email`, `member_user_id`
            ,`contact_uid`, `contact_href`, `account_id`, `created_date`, `updated_date`, `joined_date`)
          VALUES
            (nOwnerUserId, nCollectionID, vURI, nRole, 2, vEmail, nUserId
            ,NULL, NULL, 0, nUpdatedDate, nUpdatedDate, nUpdatedDate);
       --
       SET nReturn = preflow_40.m2023_insertAPILastModify('collection_member', nUserId, nUpdatedDate);
       --
     END IF;
     
     SET nCount = nCount + 1;
      # main UPDATE
     --
  END LOOP ms_loop;
  --
  RETURN nCount;
  --
END