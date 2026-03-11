CREATE PROCEDURE `C2025_listOfCollectionByCalTodoTree`(
  pvIDs TEXT,
  pnMinId BIGINT (20),
  pnRemoveDeleted boolean,
  pvObjectTrash VARBINARY (250),
  pnIncludeSubCol TINYINT (1),
  pnModifiedGTE DOUBLE (14, 4),
  pnModifiedLT DOUBLE (14, 4),
  pnFilterCreatedDate DOUBLE (14, 4),
  pvObjectType VARBINARY (250),
  pnPageSize INTEGER (11),
  pnUserId BIGINT (20)
)
BEGIN
  WITH collection_empty_finder AS (
    (
      SELECT
        c.id
      FROM
        collection c
      WHERE
        `c`.`user_id` = pnUserId
        AND `c`.`is_trashed` = 0
        AND `c`.`realtime_channel` != ""
        AND `c`.`created_date` >= pnFilterCreatedDate
        AND (pnMinId IS NULL OR `c`.`id` > pnMinId)
        AND (pvIDs IS NULL OR FIND_IN_SET(`c`.`id`, pvIDs))
        AND (pnIncludeSubCol IS NULL OR `c`.`type` <> 4)
        AND (
          c.updated_date <
          IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
          OR c.updated_date <
          IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
        )
        AND (
          c.updated_date >=
          IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
          OR c.updated_date >=
          IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
        )
        AND (ISNULL(pnRemoveDeleted) OR pnRemoveDeleted = FALSE OR c.is_trashed = 0)
    ) UNION ALL
    (
      SELECT
        c.id
      FROM
        collection c
      WHERE
        `c`.`user_id` = pnUserId
        AND `c`.`is_trashed` = 0
        AND `c`.`realtime_channel` != ""
        AND `c`.`created_date` < pnFilterCreatedDate
        AND (pnMinId IS NULL OR `c`.`id` > pnMinId)
        AND (pvIDs IS NULL OR FIND_IN_SET(`c`.`id`, pvIDs))
        AND (pnIncludeSubCol IS NULL OR `c`.`type` <> 4)
        AND (
          c.updated_date <
          IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
          OR c.updated_date <
          IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
        )
        AND (
          c.updated_date >=
          IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
          OR c.updated_date >=
          IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
        )
        AND (ISNULL(pnRemoveDeleted) OR pnRemoveDeleted = FALSE OR c.is_trashed = 0)
        AND EXISTS (
          SELECT
            1
          FROM
            linked_collection_object lco
          WHERE
            lco.collection_id = c.id
            AND lco.is_trashed = 0
            AND lco.object_type = "VTODO"
            AND EXISTS (SELECT 1 FROM cal_todo ct WHERE ct.uid = lco.object_uid AND ct.trashed = 0)
        )
    )
  ),
  -- GET ALL collections WITH their hierarchy levels
  hierarchy_collections AS (
    -- Level 1: Direct children WITH parents
    SELECT
      c1.*,
      c1.id AS co_id,
      1 AS hierarchy_level
    FROM
      collection c1
    WHERE
      c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id) UNION ALL
      -- Level 2: Parents of direct children
    SELECT
      c2.*,
      c2.id AS co_id,
      2 AS hierarchy_level
    FROM
      collection c1
      JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
    WHERE
      c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id) UNION ALL
      -- Level 3: Grandparents
    SELECT
      c3.*,
      c3.id AS co_id,
      3 AS hierarchy_level
    FROM
      collection c1
      JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
      JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
    WHERE
      c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c3.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id) UNION ALL
      -- Level 4: Great-grandparents
    SELECT
      c4.*,
      c4.id AS co_id,
      4 AS hierarchy_level
    FROM
      collection c1
      JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
      JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
      JOIN collection c4 ON (c4.id = c3.parent_id AND c4.is_trashed = 0)
    WHERE
      c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c3.parent_id IS NOT NULL
      AND c4.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id) UNION ALL
      -- Level 5: Great-great-grandparents
    SELECT
      c5.*,
      c5.id AS co_id,
      5 AS hierarchy_level
    FROM
      collection c1
      JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
      JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
      JOIN collection c4 ON (c4.id = c3.parent_id AND c4.is_trashed = 0)
      JOIN collection c5 ON (c5.id = c4.parent_id AND c5.is_trashed = 0)
    WHERE
      c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c3.parent_id IS NOT NULL
      AND c4.parent_id IS NOT NULL
      AND c5.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id) UNION ALL
      -- Level 6: Great-great-great-grandparents
    SELECT
      c6.*,
      c6.id AS co_id,
      6 AS hierarchy_level
    FROM
      collection c1
      JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
      JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
      JOIN collection c4 ON (c4.id = c3.parent_id AND c4.is_trashed = 0)
      JOIN collection c5 ON (c5.id = c4.parent_id AND c5.is_trashed = 0)
      JOIN collection c6 ON (c6.id = c5.parent_id AND c6.is_trashed = 0)
    WHERE
      c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c3.parent_id IS NOT NULL
      AND c4.parent_id IS NOT NULL
      AND c5.parent_id IS NOT NULL
      AND c6.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id)
  )
  -- Final result WITH deduplication AND ordering
  SELECT
    co_id AS id,
    channel_id,
    realtime_channel,
    calendar_uri,
    parent_id,
    root_id,
    `name`,
    icon,
    created_date,
    updated_date,
    color,
    type,
    due_date,
    flag,
    is_hide,
    alerts,
    recent_time,
    kanban_mode,
    is_trashed,
    is_expand,
    view_mode
  FROM (
      SELECT
          *,
          ROW_NUMBER() OVER (PARTITION BY co_id ORDER BY hierarchy_level ASC) AS rn
      FROM hierarchy_collections
  ) t
  WHERE rn = 1
--   ORDER BY created_date DESC
  LIMIT pnPageSize;
  --
END