CREATE PROCEDURE `l2025_getLinkedObjectsForMembersV2`(pnOwnerUserId         BIGINT(20) -- REQUIRED
                                                     ,pvCollectionIds        TEXT
                                                     ,pvTypes               TEXT            -- 0: GET ALL, 1: LINK, 2: BLOCKER
                                                     ,pvChannelId            VARCHAR(200)
                                                     ,pvObjectType          VARBINARY(1000)
                                                     ,pvObjectUid           VARBINARY(1000)
                                                     ,pnModifiedGTE         DOUBLE(14,4)
                                                     ,pnModifiedLT          DOUBLE(14,4)
                                                     ,pnMinId               BIGINT(20)
                                                     ,pvIDs                  TEXT
                                                     ,pnPageSize            INTEGER(11)
                                                     ,pvSort                VARCHAR(128)
                                                     ,pnUserId              BIGINT(20)
                                                     ,pvUsername            VARCHAR(100)
                                                    )
BEGIN
    --
    DECLARE nOFFSET           INT(11) DEFAULT 0;
    DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');
    -- DEFAULT IS ASC
    DECLARE vSort              VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' 
                                          AND NOT instr(pvSort, '-') 
                                          AND NOT instr(pvSort, '+'), concat('+', pvSort), pvSort);
    -- IF `pvTypes` contains 0, SET TO NULL TO GET ALL
    DECLARE vTypes            VARCHAR(50) DEFAULT IF(FIND_IN_SET('0', pvTypes), NULL, pvTypes);
    --
    WITH user_collections AS (
      --
      SELECT cnm.collection_id, cnm.owner_user_id, cnm.owner_calendar_uri, cnm.member_calendar_uri, cnm.owner_email
        FROM collection_notification_member cnm
       WHERE cnm.member_user_id = pnOwnerUserId
         AND cnm.is_active = 1
         -- user IS member of collections
         AND cnm.owner_user_id <> cnm.member_user_id
         -- AND cnm.collection_id > 0
         AND cnm.partition_group = 1
         AND (pvCollectionIds IS NULL OR cnm.collection_id IN (pvCollectionIds))
      --
    )
    -- SELECT link object type link
    SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
          ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
          ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
          ,lo.source_owner_calendar_uri, lo.source_owner_user_id, lo.source_owner_email, lo.source_member_calendar_uri
          ,lo.destination_owner_calendar_uri, lo.destination_owner_user_id, lo.destination_owner_email, lo.destination_member_calendar_uri
      FROM (
        SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
              ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
              ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
              -- calendar uri of the source object owner
              ,NULL source_owner_calendar_uri
              ,NULL source_owner_user_id
              ,NULL source_owner_email
              ,NULL source_member_calendar_uri
              -- calendar uri of the destination object owner
              ,NULL destination_owner_calendar_uri
              ,NULL destination_owner_user_id
              ,NULL destination_owner_email
              ,NULL destination_member_calendar_uri
              ,NULL source_collection_id
              ,NULL destination_collection_id
          FROM linked_object lo
         WHERE lo.type = 1 -- link object type link
           AND lo.user_id = pnOwnerUserId
            --
           AND (pvObjectType IS NULL
              OR (
                   lo.source_object_type = pvObjectType
                OR lo.destination_object_type = pvObjectType
              )
           ) 
           AND (pvObjectType IS NULL OR pvObjectUid IS NULL
              OR (
                   lo.source_object_uid = pvObjectUid
                OR lo.destination_object_uid = pvObjectUid
              )
           )
           AND (vTypes IS NULL OR FIND_IN_SET(lo.type, vTypes))
           AND (pnModifiedLT   IS NULL OR lo.updated_date < pnModifiedLT)
           AND (pnModifiedGTE   IS NULL OR lo.updated_date >= pnModifiedGTE)
           AND (pnMinId     IS NULL OR lo.id > pnMinId)
           AND (pvIDs       IS NULL OR FIND_IN_SET(lo.id, pvIDs))
          --
    UNION ALL
       SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
             ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
             ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
             -- calendar uri of the source object owner
             ,MAX(lo.source_owner_calendar_uri) source_owner_calendar_uri
             ,MAX(lo.source_owner_user_id) source_owner_user_id
             ,MAX(lo.source_owner_email) source_owner_email
             ,MAX(lo.source_member_calendar_uri) source_member_calendar_uri
             -- calendar uri of the destination object owner
             ,MAX(lo.destination_owner_calendar_uri) destination_owner_calendar_uri
             ,MAX(lo.destination_owner_user_id) destination_owner_user_id
             ,MAX(lo.destination_owner_email) destination_owner_email
             ,MAX(lo.destination_member_calendar_uri) destination_member_calendar_uri
             -- GET collection id of the source AND destination object
             ,MAX(lo.source_collection_id) source_collection_id
             ,MAX(lo.destination_collection_id) destination_collection_id
         FROM (
              SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
                    ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
                    ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
                     -- calendar uri of the source object owner
                    ,uc.owner_calendar_uri source_owner_calendar_uri
                    ,uc.owner_user_id source_owner_user_id
                    ,uc.owner_email source_owner_email
                    ,uc.member_calendar_uri source_member_calendar_uri
                    -- calendar uri of the destination object owner
                    ,NULL destination_owner_calendar_uri
                    ,NULL destination_owner_user_id
                    ,NULL destination_owner_email
                    ,NULL destination_member_calendar_uri
                    ,lco.collection_id source_collection_id
                    ,NULL destination_collection_id
                FROM linked_object lo
                JOIN linked_collection_object lco ON (lo.source_object_type = lco.object_type AND lo.source_object_uid = lco.object_uid)
                JOIN user_collections uc ON (lco.collection_id = uc.collection_id AND lco.user_id = uc.owner_user_id)
           UNION ALL
              SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
                    ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
                    ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
                     -- calendar uri of the source object owner
                    ,NULL source_owner_calendar_uri
                    ,NULL source_owner_user_id
                    ,NULL source_owner_email
                    ,NULL source_member_calendar_uri
                    -- calendar uri of the destination object owner
                    ,uc.owner_calendar_uri destination_owner_calendar_uri
                    ,uc.owner_user_id destination_owner_user_id
                    ,uc.owner_email destination_owner_email
                    ,uc.member_calendar_uri destination_member_calendar_uri
                    ,NULL source_collection_id
                    ,lco.collection_id destination_collection_id
                FROM linked_object lo
                JOIN linked_collection_object lco ON (lo.destination_object_type = lco.object_type AND lo.destination_object_uid = lco.object_uid)
                JOIN user_collections uc ON (lco.collection_id = uc.collection_id AND lco.user_id = uc.owner_user_id)
         ) lo
        WHERE lo.type = 2 -- link object type blocker
          AND (pvObjectType IS NULL
              OR (
                   lo.source_object_type = pvObjectType
                OR lo.destination_object_type = pvObjectType
              )
           ) 
           AND (pvObjectType IS NULL OR pvObjectUid IS NULL
              OR (
                   lo.source_object_uid = pvObjectUid
                OR lo.destination_object_uid = pvObjectUid
              )
           )
           AND (vTypes IS NULL OR FIND_IN_SET(lo.type, vTypes))
           AND (pnModifiedLT   IS NULL OR lo.updated_date < pnModifiedLT)
           AND (pnModifiedGTE   IS NULL OR lo.updated_date >= pnModifiedGTE)
           AND (pnMinId     IS NULL OR lo.id > pnMinId)
           AND (pvIDs       IS NULL OR FIND_IN_SET(lo.id, pvIDs))
     GROUP BY lo.id
        LIMIT pnPageSize
          -- 
      ) lo
  ORDER BY
    (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "-") THEN
             --
             CASE vFieldSort
               --
               WHEN 'created_date' THEN lo.created_date               
               WHEN 'updated_date' THEN lo.updated_date
               --
             END
           WHEN NOT isnull(pnModifiedLT) THEN lo.updated_date
           --
         END) DESC,
        (CASE
           --
           WHEN NOT isnull(pnMinId) THEN lo.id
           WHEN NOT isnull(pnModifiedGTE) THEN lo.updated_date
           WHEN isnull(pnMinId) AND INSTR(vSort, "+") THEN
             --
             CASE vFieldSort 
               --
               WHEN 'created_date' THEN lo.created_date               
               WHEN 'updated_date' THEN lo.updated_date
               --
              END
           --
         END) ASC
    --
  LIMIT pnPageSize;
  --
--
END