CREATE PROCEDURE `adm2026_listOfTerminateUser`(
     pvGroupIds               TEXT
    ,pnGroupFilterType        TINYINT(1)
    ,pvKeyword                VARCHAR(256) -- search ON field: email & account_3rd_emails
    ,pvPlatformIds            VARCHAR(256)
    ,pvPlatformFilterType     TINYINT(1)    -- 0:any, 1:ALL
    ,pbIsInternal             TINYINT(1)
    ,pvStatuses               VARCHAR(256)
    ,pvSort                   VARCHAR(128)  -- [-DESC +ASC] fieldname
    ,pnOFFSET                 INT(5)
    ,pnLIMIT                  INT(5))
BEGIN
  --
  DECLARE vKeyword      VARCHAR(256)    DEFAULT concat('%', ifnull(pvKeyword, ''), '%');
  DECLARE nRows         INT(11)         DEFAULT 0;
  DECLARE bIsInternal   TINYINT(1)      DEFAULT ifnull(pbIsInternal, 0);
  DECLARE bIsNoGroup    TINYINT(1)      DEFAULT 0;
  DECLARE nOFFSET       INT(5);
  DECLARE nLIMIT        INT(5);
  DECLARE vGroupIds     TEXT;
  DECLARE vFieldSort    VARCHAR(50)     DEFAULT REPLACE(REPLACE(IFNULL(pvSort, 'id'), '-', ''), '+', '');
  DECLARE vSort         VARCHAR(50)     DEFAULT IF(NOT isnull(pvSort)
                         AND NOT instr(pvSort, '-') 
                                               AND NOT instr(pvSort, '+'), concat('+', pvSort), ifnull(pvSort, '-id'));
  --
  SET bIsNoGroup = ifnull(find_in_set(-1, pvGroupIds), 0) = 1;
  SET vGroupIds = CASE
        WHEN pvGroupIds IS NULL THEN ''
        ELSE REPLACE(REPLACE(pvGroupIds, '-1,', ''), '-1', '')
    END;
  --
  -- Count total rows matching criteria
  SELECT COUNT(DISTINCT uu.id) INTO nRows
    FROM user uu
    INNER JOIN user_deleted ud ON (uu.id = ud.user_id)
    LEFT JOIN report_cached_user rcu ON (rcu.user_id = uu.id)
    LEFT JOIN (
          SELECT group_concat(gg.`name` ORDER BY gg.`name`) `groups`, guu.user_id
                ,group_concat(gg.group_type) group_type
                ,group_concat(guu.group_id) group_id
            FROM `group` gg
            JOIN group_user guu ON (guu.group_id = gg.id)
           GROUP BY guu.user_id
     ) gu ON (uu.id = gu.user_id)
   WHERE (rcu.email LIKE vKeyword OR rcu.account_3rd_emails LIKE vKeyword)
     AND (isnull(pbIsInternal)
       OR (bIsInternal = 0 AND (NOT find_in_set(2, gu.group_type) OR gu.groups IS NULL))
       OR (bIsInternal = 1 AND find_in_set(2, gu.group_type) AND NOT isnull(gu.groups)))
     AND IF(vGroupIds = '', 1
           ,IF(NOT bIsNoGroup, futil_findNeedleInHaystack(vGroupIds, gu.group_id, pnGroupFilterType)
           ,ISNULL(gu.groups) OR futil_findNeedleInHaystack(vGroupIds, gu.group_id, pnGroupFilterType)))
     AND IF(bIsNoGroup AND vGroupIds = '', gu.groups IS NULL, 1)
     AND IF(ifnull(pvPlatformIds, '') = '', 1, futil_findNeedleInHaystack(pvPlatformIds, rcu.platform, pvPlatformFilterType))
     -- Status filter: 1=Waiting for approval, 2=Pending Deletion, 3=Cleaning STARTING, 4=Cleaning IN progress
     AND IF(ifnull(pvStatuses, '') = '', 1, 
         FIND_IN_SET(
             CASE 
                 WHEN ifnull(ud.progress, 0) = 0 AND ifnull(ud.cleaning_date, 0) = 0 THEN 1
                 WHEN ifnull(ud.progress, 0) = 0 AND ifnull(ud.cleaning_date, 0) > 0 THEN 2
                 WHEN ifnull(ud.progress, 0) = 1 AND ifnull(ud.cleaning_date, 0) > 0 THEN 3
                 WHEN ifnull(ud.progress, 0) > 1 AND ifnull(ud.cleaning_date, 0) > 0 THEN 4
                 ELSE 0
             END, 
             pvStatuses
         )
     );
  --
  SET nOFFSET = ifnull(pnOFFSET, 0);
  SET nLIMIT = ifnull(pnLIMIT, nRows);
  SET SESSION group_concat_max_len = 500000;
  --
  SELECT
        -- user_deleted fields
        ud.id, ud.created_date, ud.updated_date
        ,ud.is_disabled AS is_disabled
        ,ifnull(ud.progress, 0) AS delete_progress
        ,ifnull(ud.cleaning_date, 0) AS cleaning_date
        
        -- user fields
        ,uu.email, uu.fullname
        
        -- group_user fields
        ,gu.`groups`, gu.group_type, gu.group_id
        
        -- report cached user fields
        ,rcu.last_used_date, rcu.user_id, rcu.account_3rd, rcu.account_3rd_emails, rcu.account_type
        ,rcu.`storage`, p.product_id sub_id, rcu.subs_type, rcu.order_number, rcu.subs_current_date, rcu.platform
        ,rcu.join_date, ifnull(unix_timestamp(p.next_renewal_date), 0) next_renewal, rcu.disabled, rcu.deleted, rcu.addition_info
        
        -- purchase fields
        ,p.id AS `subscriptionPurchase.id`
        ,p.product_id `subscriptionPurchase.sub_id`
        ,p.is_current `subscriptionPurchase.is_current`
        ,ifnull(unix_timestamp(p.created_date), 0) start_date
        ,ifnull(unix_timestamp(p.expires_at), 0) end_date
        ,ifnull(unix_timestamp(p.created_date), 0) `subscriptionPurchase.created_date`
        ,plan.name plan_name
        ,plan.circle_life
        
        ,CASE 
            WHEN ifnull(ud.progress, 0) = 0 AND ifnull(ud.cleaning_date, 0) = 0 THEN 1  -- Waiting for approval
            WHEN ifnull(ud.progress, 0) = 0 AND ifnull(ud.cleaning_date, 0) > 0 THEN 2  -- Pending Deletion
            WHEN ifnull(ud.progress, 0) = 1 AND ifnull(ud.cleaning_date, 0) > 0 THEN 3  -- Cleaning STARTING
            WHEN ifnull(ud.progress, 0) > 1 AND ifnull(ud.cleaning_date, 0) > 0 THEN 4  -- Cleaning IN progress
            ELSE 0
         END AS delete_status
        ,nRows totalRows
    FROM user uu
    INNER JOIN user_deleted ud ON (uu.id = ud.user_id)
    LEFT JOIN report_cached_user rcu ON (rcu.user_id = uu.id)
    LEFT JOIN (
          SELECT group_concat(gg.`name` ORDER BY gg.`name`) `groups`, guu.user_id
                ,group_concat(gg.group_type) group_type
                ,group_concat(guu.group_id) group_id
            FROM `group` gg
            JOIN group_user guu ON (guu.group_id = gg.id)
           GROUP BY guu.user_id
     ) gu ON (uu.id = gu.user_id)
     LEFT JOIN flo_subscription.purchases p ON (uu.id = p.user_id AND p.is_current = 1)
     LEFT JOIN flo_subscription.plans plan ON (p.product_id = plan.product_id)
     WHERE (rcu.email LIKE vKeyword OR rcu.account_3rd_emails LIKE vKeyword)
       AND (isnull(pbIsInternal)
         OR (bIsInternal = 0 AND (NOT find_in_set(2, gu.group_type) OR gu.groups IS NULL))
         OR (bIsInternal = 1 AND find_in_set(2, gu.group_type) AND NOT isnull(gu.groups)))
       AND IF(vGroupIds = '', 1
             ,IF(NOT bIsNoGroup, futil_findNeedleInHaystack(vGroupIds, gu.group_id, pnGroupFilterType)
             ,ISNULL(gu.groups) OR futil_findNeedleInHaystack(vGroupIds, gu.group_id, pnGroupFilterType)))
       AND IF(bIsNoGroup AND vGroupIds = '', gu.groups IS NULL, 1)
       AND IF(ifnull(pvPlatformIds, '') = '', 1, futil_findNeedleInHaystack(pvPlatformIds, rcu.platform, pvPlatformFilterType))
       -- Status filter: 1=Waiting for approval, 2=Pending Deletion, 3=Cleaning STARTING, 4=Cleaning IN progress
       AND IF(ifnull(pvStatuses, '') = '', 1, 
           FIND_IN_SET(
               CASE 
                   WHEN ifnull(ud.progress, 0) = 0 AND ifnull(ud.cleaning_date, 0) = 0 THEN 1
                   WHEN ifnull(ud.progress, 0) = 0 AND ifnull(ud.cleaning_date, 0) > 0 THEN 2
                   WHEN ifnull(ud.progress, 0) = 1 AND ifnull(ud.cleaning_date, 0) > 0 THEN 3
                   WHEN ifnull(ud.progress, 0) > 1 AND ifnull(ud.cleaning_date, 0) > 0 THEN 4
                   ELSE 0
               END, 
               pvStatuses
           )
       )
    GROUP BY rcu.id, gu.user_id
    ORDER BY
          -- DESC sorting (NUMERIC fields)
          CASE 
            WHEN INSTR(vSort, '-') AND vFieldSort IN ('id', 'progress', 'cleaning_date', 'created_date') THEN 
              CASE vFieldSort 
                WHEN 'id' THEN ud.id
                WHEN 'progress' THEN ifnull(ud.progress, 0)
                WHEN 'cleaning_date' THEN ifnull(ud.cleaning_date, 0)
                WHEN 'created_date' THEN ifnull(ud.created_date, 0)
              END
          END DESC,
          -- DESC sorting (string fields)
          CASE 
            WHEN INSTR(vSort, '-') AND vFieldSort = 'email' THEN ud.username
          END DESC,
          -- ASC sorting (NUMERIC fields)
          CASE 
            WHEN INSTR(vSort, '+') AND vFieldSort IN ('id', 'progress', 'cleaning_date', 'created_date') THEN 
              CASE vFieldSort 
                WHEN 'id' THEN ud.id
                WHEN 'progress' THEN ifnull(ud.progress, 0)
                WHEN 'cleaning_date' THEN ifnull(ud.cleaning_date, 0)
                WHEN 'created_date' THEN ifnull(ud.created_date, 0)
              END
          END ASC,
          -- ASC sorting (string fields)
          CASE 
            WHEN INSTR(vSort, '+') AND vFieldSort = 'username' THEN ud.username
          END ASC
     LIMIT nOFFSET, nLIMIT;
END