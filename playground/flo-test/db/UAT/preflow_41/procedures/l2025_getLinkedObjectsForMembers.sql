CREATE PROCEDURE `l2025_getLinkedObjectsForMembers`(pvOwnerUserIds       TEXT
                           ,pvCollectionIds      VARBINARY(1000)
                           ,pvTypes                  TEXT            -- 0: GET ALL, 1: LINK, 2: BLOCKER
                           ,pvChannelId        VARCHAR(200)
                           ,pvObjectType      VARBINARY(1000)
                           ,pvObjectUid         VARBINARY(1000)
                           ,pnModifiedGTE       DOUBLE(14,4)
                           ,pnModifiedLT        DOUBLE(14,4)
                           ,pnMinId             BIGINT(20)
                           ,pvIDs            TEXT
                           ,pnPageSize              INTEGER(11)
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
    ,MAX(CASE WHEN lo.source_collection_id IS NOT NULL THEN lo.source_collection_id END) source_collection_id
        ,MAX(lo.destination_collection_id) destination_collection_id
        ,lo.owner_user_id
   FROM (
    --
  SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
      ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
      ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
      ,lco.collection_id source_collection_id
          ,0 destination_collection_id
          ,csm.member_user_id member_user_id, csm.shared_status shared_status
          ,co.user_id owner_user_id
      FROM linked_object lo
    JOIN linked_collection_object lco ON (lo.source_object_type = lco.object_type
                      AND lo.source_object_uid = lco.object_uid
                                            AND FIND_IN_SET(lco.collection_id, pvCollectionIds))
    JOIN collection co ON (co.id = lco.collection_id AND co.user_id = lo.user_id)
      JOIN collection_shared_member csm ON (csm.collection_id = co.id)
    --
 UNION ALL
  SELECT lo.id, lo.source_object_uid, lo.source_object_type, lo.source_object_href, lo.source_account_id
      ,lo.destination_object_type, lo.destination_object_uid, lo.destination_object_href, lo.destination_account_id
      ,lo.user_id, lo.is_trashed, lo.type, lo.status, lo.created_date, lo.updated_date
      ,0 source_collection_id
          ,lco.collection_id destination_collection_id
          ,csm.member_user_id member_user_id, csm.shared_status shared_status
          ,co.user_id owner_user_id
    FROM linked_object lo
    JOIN linked_collection_object lco ON (lo.destination_object_type = lco.object_type
                      AND lo.destination_object_uid = lco.object_uid
                                            AND FIND_IN_SET(lco.collection_id, pvCollectionIds))
    JOIN collection co ON (co.id = lco.collection_id)
 LEFT JOIN collection_shared_member csm ON (csm.collection_id = co.id)
   ) lo
  --
  WHERE (lo.member_user_id IS NULL OR lo.member_user_id = pnUserId) -- request user must be a member of the source share col
    AND lo.shared_status = 1 -- JOINED
  --
  AND (pvOwnerUserIds IS NULL OR lo.user_id IN (pvOwnerUserIds))
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
  GROUP BY id
  -- IF source col = destination col, CHECK IF the owner of col IS the owner of linked object
    HAVING (owner_user_id IS NULL OR source_collection_id <> destination_collection_id OR owner_user_id = user_id)
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