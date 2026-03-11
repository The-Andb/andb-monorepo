CREATE PROCEDURE `C2025_listOfCollectionTree`(
  pnModifiedLT    DOUBLE(14,4),
  pvObjectType    VARBINARY(250),
  pnPageSize      INTEGER(11), 
  pnUserId         BIGINT (20)
)
BEGIN
  --
  WITH collection_empty_finder AS (
    SELECT
      c.id
    FROM
      collection c
    WHERE
      `c`.`user_id` = pnUserId
      AND `c`.`is_trashed` = 0
      AND `c`.`realtime_channel` != ""
      AND `c`.`channel_id` IS NULL
      AND `c`.`created_date` < pnModifiedLT
      AND EXISTS (
        SELECT 1 
        FROM linked_collection_object lco 
        WHERE 
          lco.collection_id = c.id
          AND `lco`.`is_trashed` = 0
          AND (
              ISNULL(pvObjectType) OR pvObjectType = '' OR FIND_IN_SET(lco.object_type, pvObjectType)
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
    FROM collection c1
    WHERE c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id)

    UNION ALL

    -- Level 2: Parents of direct children
    SELECT 
      c2.*,
      c2.id AS co_id,
      2 AS hierarchy_level
    FROM collection c1
    JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
    WHERE c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id)

    UNION ALL

    -- Level 3: Grandparents
    SELECT 
      c3.*,
      c3.id AS co_id,
      3 AS hierarchy_level
    FROM collection c1
    JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
    JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
    WHERE c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c3.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id)

    UNION ALL

    -- Level 4: Great-grandparents
    SELECT 
      c4.*,
      c4.id AS co_id,
      4 AS hierarchy_level
    FROM collection c1
    JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
    JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
    JOIN collection c4 ON (c4.id = c3.parent_id AND c4.is_trashed = 0)
    WHERE c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c3.parent_id IS NOT NULL
      AND c4.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id)

    UNION ALL

    -- Level 5: Great-great-grandparents
    SELECT 
      c5.*,
      c5.id AS co_id,
      5 AS hierarchy_level
    FROM collection c1
    JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
    JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
    JOIN collection c4 ON (c4.id = c3.parent_id AND c4.is_trashed = 0)
    JOIN collection c5 ON (c5.id = c4.parent_id AND c5.is_trashed = 0)
    WHERE c1.user_id = pnUserId
      AND c1.parent_id IS NOT NULL
      AND c2.parent_id IS NOT NULL
      AND c3.parent_id IS NOT NULL
      AND c4.parent_id IS NOT NULL
      AND c5.parent_id IS NOT NULL
      AND c1.is_trashed = 0
      AND EXISTS (SELECT 1 FROM collection_empty_finder cef WHERE cef.id = c1.id)

    UNION ALL

    -- Level 6: Great-great-great-grandparents
    SELECT 
      c6.id AS co_id,
      c6.*,
      6 AS hierarchy_level
    FROM collection c1
    JOIN collection c2 ON (c2.id = c1.parent_id AND c2.is_trashed = 0)
    JOIN collection c3 ON (c3.id = c2.parent_id AND c3.is_trashed = 0)
    JOIN collection c4 ON (c4.id = c3.parent_id AND c4.is_trashed = 0)
    JOIN collection c5 ON (c5.id = c4.parent_id AND c5.is_trashed = 0)
    JOIN collection c6 ON (c6.id = c5.parent_id AND c6.is_trashed = 0)
    WHERE c1.user_id = pnUserId
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
      id AS co_id,
      channel_id AS co_channel_id,
      realtime_channel AS co_realtime_channel,
      calendar_uri AS co_calendar_uri,
      parent_id AS co_parent_id,
      root_id AS co_root_id,
      `name` AS co_name,
      icon AS co_icon,
      created_date AS co_created_date,
      updated_date AS co_updated_date,
      color AS co_color,
      type AS co_type,
      due_date AS co_due_date,
      flag AS co_flag,
      is_hide AS co_is_hide,
      alerts AS co_alerts,
      recent_time AS co_recent_time,
      kanban_mode AS co_kanban_mode,
      is_trashed AS co_is_trashed,
      is_expand AS co_is_expand,
      view_mode AS co_view_mode
  FROM (
      SELECT
          *,
          ROW_NUMBER() OVER (PARTITION BY co_id ORDER BY hierarchy_level ASC) AS rn
      FROM hierarchy_collections
  ) t
  WHERE rn = 1
  -- ORDER BY created_date DESC
  LIMIT pnPageSize;
  --
END