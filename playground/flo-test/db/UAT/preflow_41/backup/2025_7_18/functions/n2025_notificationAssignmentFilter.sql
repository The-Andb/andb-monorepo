CREATE FUNCTION `n2025_notificationAssignmentFilter`(
pvAssignmentFilter   VARCHAR(100)
,pvObjectUid          VARBINARY(1000)
,pvObjectType         VARBINARY(50)
,pnAction             INT
,pvAssignees          TEXT
,pvUsername           VARCHAR(100)
,pvNotiEmail          VARCHAR(100)
) RETURNS TINYINT(1)
BEGIN
  --
  DECLARE vAssignees        TEXT DEFAULT ifnull(pvAssignees, '');
  -- 18 >> Un-Assigned
  DECLARE bUnassigned       TINYINT(1) DEFAULT (vAssignees = '' OR pnAction = 18);
  -- 17 >> Assigned
  DECLARE bAssignedToMe     TINYINT(1) DEFAULT (pnAction = 17
                                              AND find_in_set(pvUsername, vAssignees));
  DECLARE bAssignedByMe     TINYINT(1) DEFAULT (pnAction = 17
                                              AND pvNotiEmail = pvUsername);
  DECLARE bAssignedByOther  TINYINT(1) DEFAULT (vAssignees <> '' 
                                                AND pvNotiEmail <> pvUsername 
                                                AND NOT find_in_set(pvUsername, vAssignees));
  DECLARE vRealAssignees    TEXT;
  DECLARE vOrganizer        TEXT;
  --
  IF pvObjectType = 'VTODO' THEN
    --
    SELECT ifnull(ct.assignee, 'NA'), ifnull(ct.organizer, '')
      INTO vRealAssignees, vOrganizer
      FROM cal_todo ct
     WHERE ct.uid = pvObjectUid
     ORDER BY id DESC
     LIMIT 1; 
    --
    SET bUnassigned = vRealAssignees = 'NA' OR pnAction = 18;
    --
    SET bAssignedByMe = vRealAssignees <> 'NA' AND LOCATE(pvUsername, vOrganizer) > 0;
    --
    SET bAssignedToMe = vRealAssignees <> 'NA' AND LOCATE(pvUsername, vRealAssignees) > 0;
    --
    SET bAssignedByOther = IF(vRealAssignees = '', 1, 
                        pvNotiEmail <> pvUsername
                        AND LOCATE(pvUsername, vRealAssignees) = 0);
    --
  END IF;
  --
  RETURN find_in_set(0, pvAssignmentFilter)
              OR (pvObjectType <> 'VTODO' 
                OR (pvObjectType = 'VTODO' AND (
                 -- 4: ALL VTODO
                 find_in_set(4, pvAssignmentFilter)
                 -- 1: NOT Assigned
                 OR (find_in_set(1, pvAssignmentFilter) AND bUnassigned)
                 -- 2: Assigned TO Me 
                 OR (find_in_set(2, pvAssignmentFilter) AND bAssignedToMe)
                 -- 3: Assigned BY Me
                 OR (find_in_set(3, pvAssignmentFilter) AND bAssignedByMe)
                 -- -1: Other
                 OR (FIND_IN_SET(-1, pvAssignmentFilter) AND bAssignedByOther)
               )
            )
         );
  --
END