CREATE PROCEDURE `l2025_getLinkedObjectsForMembersV2`(pvCollectionIds      VARBINARY(1000) -- REQUIRED
                                      ,pvTypes              TEXT            -- 0: GET ALL, 1: LINK, 2: BLOCKER
                                      ,pvChannelId        VARCHAR(200)
                                      ,pvObjectType      VARBINARY(1000)
                                      ,pvObjectUid         VARBINARY(1000)
                                      ,pnModifiedGTE       DOUBLE(14,4)
                                      ,pnModifiedLT        DOUBLE(14,4)
                                      ,pnMinId             BIGINT(20)
                                      ,pvIDs        TEXT
                                      ,pnPageSize           INTEGER(11)
                                      ,pvSort              VARCHAR(128)
                                        ,pnUserId            BIGINT(20)
                                      ,pvUsername          VARCHAR(100)
                                      )
BEGIN
  --
  DECLARE nOFFSET           INT(11) DEFAULT 0;
  DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');
  -- DEFAULT IS ASC
  DECLARE vSort            VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' 
                AND NOT instr(pvSort, '-') 
                AND NOT instr(pvSort, '+'), concat('+', pvSort), pvSort);
  -- IF `pvTypes` contains 0, SET TO NULL TO GET ALL
  DECLARE vTypes            VARCHAR(50) DEFAULT IF(FIND_IN_SET('0', pvTypes), NULL, pvTypes);
  --
  --
    SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
      ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
      ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
            ,lcos.collection_id source_collection_id
            ,lcos.owner_user_id source_owner_user_id, lcos.owner_username source_owner_username
            ,lcos.owner_calendar_uri source_owner_calendar_uri, lcos.calendar_uri source_calendar_uri
            ,lcod.collection_id destination_collection_id
      ,lcod.owner_user_id destination_owner_user_id, lcod.owner_username destination_owner_username
      ,lcod.owner_calendar_uri destination_owner_calendar_uri, lcod.calendar_uri destination_calendar_uri
     FROM linked_object lo
  LEFT JOIN (
    SELECT lco.object_type, lco.object_uid, lco.collection_id
        ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
        ,csm.calendar_uri calendar_uri
        ,usr.username owner_username
      FROM linked_collection_object lco
      JOIN collection co ON (lco.collection_id = co.id)
      JOIN user usr ON (co.user_id = usr.id)
      JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
  ) lcos ON (lo.source_object_type = lcos.object_type AND lo.source_object_uid = lcos.object_uid)
  LEFT JOIN (
    SELECT lco.object_type, lco.object_uid, lco.collection_id
        ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
        ,csm.calendar_uri calendar_uri
        ,usr.username owner_username
      FROM linked_collection_object lco
      JOIN collection co ON (lco.collection_id = co.id)
      JOIN user usr ON (co.user_id = usr.id)
      JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
  ) lcod ON (lo.destination_object_type = lcod.object_type AND lo.destination_object_uid = lcod.object_uid)
    --
     WHERE (lcos.collection_id IN (pvCollectionIds) OR lcod.collection_id IN (pvCollectionIds))
       AND ((
        (pvObjectType IS NULL OR lo.source_object_type = pvObjectType)
        AND (pvObjectUid  IS NULL OR lo.source_object_uid = pvObjectUid)
       )
        OR (
        (pvObjectType IS NULL OR lo.destination_object_type = pvObjectType)
        AND (pvObjectUid  IS NULL OR lo.destination_object_uid = pvObjectUid)
       ))
        --
       AND (vTypes     IS NULL OR FIND_IN_SET(lo.type, vTypes))
      --
       AND (pnModifiedLT   IS NULL OR lo.updated_date < pnModifiedLT)
       AND (pnModifiedGTE   IS NULL OR lo.updated_date >= pnModifiedGTE)
       AND (pnMinId     IS NULL OR lo.id > pnMinId)
       AND (pvIDs       IS NULL OR FIND_IN_SET(lo.id, pvIDs))
      --
    AND IF(
      --
      IFNULL(pvChannelId, '') = '',
        1,
        EXISTS (
        --
          SELECT 1
            FROM conference_channel cc
        INNER JOIN conference_member cm ON cc.id = cm.channel_id
           WHERE cc.id = pvChannelId
             AND cm.user_id = pnUserId
        --
        )
      --
      )
     ORDER BY
    -- 
    (CASE WHEN ifnull(vSort,'') <> '' THEN
      --
      CASE WHEN INSTR(vSort, "-") THEN
      --
      CASE vFieldSort 
        WHEN 'updated_date' THEN lo.updated_date
        WHEN 'created_date' THEN lo.created_date
      END
      --
      END
      --
      WHEN IFNULL(pnModifiedLT, 0) > 0 THEN lo.updated_date
    END) DESC,
    --
    (CASE WHEN ifnull(vSort,'') <> '' THEN
      --
      CASE WHEN INSTR(vSort, "+") THEN
      CASE vFieldSort
        WHEN 'updated_date' THEN lo.updated_date
        WHEN 'created_date' THEN lo.created_date
      END
      END
      --
      WHEN IFNULL(pnModifiedGTE, 0) > 0 THEN lo.updated_date
      WHEN ifnull(pnMinId, 0) > 0 THEN lo.id
    END) ASC
    --
    LIMIT pnPageSize;
  --
--
END