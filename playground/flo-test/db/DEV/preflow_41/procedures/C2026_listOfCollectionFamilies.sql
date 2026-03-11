CREATE PROCEDURE `C2026_listOfCollectionFamilies`(
    IN pnUserId BIGINT (20),
    IN pnLimit INT (11),
    IN pnOffset INT (11)
)
BEGIN
    WITH RECURSIVE collection_tree AS (
        -- Base CASE: GET ALL root collections (parent_id = 0)
        SELECT 
            c.id,
            c.parent_id,
            c.user_id,
            c.type,
            c.id AS root_id
        FROM collection c
        WHERE c.user_id = PnUserId 
          AND c.parent_id = 0 
          AND c.is_trashed = 0
        
        UNION ALL
        
        -- Recursive CASE: GET ALL children of EACH root
        SELECT 
            c.id,
            c.parent_id,
            c.user_id,
            c.type,
            ct.root_id
        FROM collection c
        INNER JOIN collection_tree ct ON c.parent_id = ct.id
        WHERE c.user_id = PnUserId 
          AND c.is_trashed = 0
          AND ct.root_id IS NOT NULL
    )
    SELECT 
        root_id AS family_root,
        JSON_ARRAYAGG(id) AS collection_ids,
        JSON_ARRAYAGG(
            JSON_OBJECT('id', id, 'type', type)
        ) AS collection_details,
        COUNT(*) AS family_size
    FROM collection_tree
    GROUP BY root_id
    ORDER BY root_id
    LIMIT pnLimit OFFSET pnOffset;
END