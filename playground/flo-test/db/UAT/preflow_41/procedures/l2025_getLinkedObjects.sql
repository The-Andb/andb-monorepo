CREATE PROCEDURE `l2025_getLinkedObjects`(pnOwnerUserId            BIGINT(20) -- REQUIRED
                      ,pvCollectionIds      VARBINARY(1000)
                        ,pvTypes                   TEXT            -- 0: GET ALL, 1: LINK, 2: BLOCKER
                                          ,pvChannelId        VARCHAR(200)
                      ,pvObjectType        VARBINARY(1000)
                        ,pvObjectUid           VARBINARY(1000)
                        ,pnModifiedGTE         DOUBLE(14,4)
                        ,pnModifiedLT          DOUBLE(14,4)
                        ,pnMinId               BIGINT(20)
                        ,pvIDs            TEXT
                        ,pnPageSize                INTEGER(11)
                        ,pvSort                VARCHAR(128)
                        ,pnUserId              BIGINT(20)
                        ,pvUsername            VARCHAR(100)
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
    ,MAX(lo.source_collection_id) source_collection_id
        ,MAX(lo.destination_collection_id) destination_collection_id
      ,MAX(CASE WHEN lo.owner_calendar_uri IS NOT NULL THEN lo.owner_calendar_uri END) owner_calendar_uri
        ,MAX(CASE WHEN lo.owner_user_id IS NOT NULL THEN lo.owner_user_id END) owner_user_id
        ,MAX(CASE WHEN lo.owner_username IS NOT NULL THEN lo.owner_username END) owner_username
        ,MAX(CASE WHEN lo.member_calendar_uri IS NOT NULL THEN lo.member_calendar_uri END) member_calendar_uri
   FROM (
     --
  SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
      ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
      ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
      ,lco.collection_id source_collection_id
          ,0 destination_collection_id
      ,NULL owner_calendar_uri, NULL owner_user_id, NULL owner_username, NULL member_calendar_uri
      FROM linked_object lo
 LEFT JOIN linked_collection_object lco ON (lo.source_object_type = lco.object_type
                      AND lo.source_object_uid = lco.object_uid)
     UNION
  SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
      ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
      ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
      ,0 source_collection_id
          ,lco.collection_id destination_collection_id
      ,lco.owner_calendar_uri
          ,CASE WHEN lco.owner_user_id = pnUserId THEN NULL -- IF user IS already owner THEN RETURN NULL TO avoid REPLACE href
          ELSE lco.owner_user_id
       END owner_user_id
          ,lco.owner_username, lco.member_calendar_uri
    FROM linked_object lo
 LEFT JOIN (
     -- GET the owner info of destination object
       -- RISK: IF member belongs TO too many collections, this may decrease query performance
     SELECT lco.collection_id, lco.object_type, lco.object_uid
       ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
       ,csm.calendar_uri member_calendar_uri
       ,usr.username owner_username
     FROM linked_collection_object lco
     JOIN collection co ON (lco.collection_id = co.id)
     JOIN user usr ON (co.user_id = usr.id)
     JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
     --
     ) lco ON (lo.destination_object_type = lco.object_type
        AND lo.destination_object_uid  = lco.object_uid)
  ) lo
  --
  WHERE (lo.user_id = pnOwnerUserId OR
     --
       (
        pvObjectType IS NOT NULL
      AND pvObjectUid  IS NOT NULL
          AND lo.type = 2
     )
    )
    --
  AND ((
    (pvObjectType IS NULL OR pvObjectUid IS NULL)
    OR (lo.source_object_type = pvObjectType AND lo.source_object_uid = pvObjectUid)
  )
    OR (
    (pvObjectType IS NULL OR pvObjectUid IS NULL)
    OR (lo.destination_object_type = pvObjectType AND lo.destination_object_uid = pvObjectUid)
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
           AND (cc.uid = lo.source_object_uid OR cc.uid = lo.destination_object_uid)
                   AND (lo.source_object_type = 'CONFERENCING' OR lo.destination_object_type = 'CONFERENCING')
           AND cm.user_id = pnUserId
      --
      )
    --
  )
  GROUP BY id
  HAVING pvCollectionIds IS NULL
       OR (FIND_IN_SET(source_collection_id, pvCollectionIds) OR FIND_IN_SET(destination_collection_id, pvCollectionIds))
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