COPY
  (SELECT m.id,
          m.product || ' ' || coalesce(m.version, '') AS model_name,
          count(*) AS items_count,
          max(i.last_check) AS last_check,
          min(i.created_at) AS first_procurement,
          count(DISTINCT r.contract_id) AS number_of_contracts,
          eg.name AS entitlement_groups_name
   FROM items i
   JOIN models m ON m.id = i.model_id
   LEFT JOIN reservations r ON r.item_id = i.id
   LEFT JOIN users ON r.user_id = users.id 
   LEFT JOIN entitlement_groups_users egu ON egu.user_id = users.id
   LEFT JOIN entitlement_groups eg ON eg.inventory_pool_id = i.inventory_pool_id AND eg.id = egu.entitlement_group_id
   LEFT JOIN contracts c ON r.contract_id = c.id
   WHERE i.inventory_pool_id = (SELECT id FROM inventory_pools WHERE name = 'Ausleihe Toni-Areal')
     AND eg.name = 'DDK - FFI'
   GROUP BY m.id, eg.name
   ORDER BY m.product || ' ' || coalesce(m.version, ''))
TO '/Users/nitaai/tmp/ausleihe-toni_all-items.csv' (format csv)

COPY
  (SELECT m.id,
          m.product || ' ' || coalesce(m.version, '') AS model_name,
          count(*) AS items_count,
          max(i.last_check) AS last_check,
          min(i.created_at) AS first_procurement,
          count(DISTINCT r.contract_id) AS number_of_contracts,
          eg.name AS entitlement_groups_name
   FROM items i
   JOIN models m ON m.id = i.model_id
   LEFT JOIN reservations r ON r.item_id = i.id
   LEFT JOIN users ON r.user_id = users.id 
   LEFT JOIN entitlement_groups_users egu ON egu.user_id = users.id
   LEFT JOIN entitlement_groups eg ON eg.inventory_pool_id = i.inventory_pool_id AND eg.id = egu.entitlement_group_id
   LEFT JOIN contracts c ON r.contract_id = c.id
   WHERE i.retired IS NULL
     AND eg.name like 'DDK - FFI'
     AND i.inventory_pool_id = (SELECT id FROM inventory_pools WHERE name like 'Ausleihe Toni-Areal')
   GROUP BY m.id, eg.name
   ORDER BY m.product || ' ' || coalesce(m.version, ''))
TO '/Users/nitaai/tmp/ausleihe-toni_all-unretired-items.csv' (format csv)

COPY
  (SELECT m.id,
          m.product || ' ' || coalesce(m.version, '') AS model_name,
          extract(YEAR FROM c.created_at) AS year,
          count(DISTINCT r.contract_id) AS number_of_contracts,
          eg.name AS entitlement_groups_name
   FROM items i
   JOIN models m ON m.id = i.model_id
   LEFT JOIN reservations r ON r.item_id = i.id
   LEFT JOIN users ON r.user_id = users.id 
   LEFT JOIN entitlement_groups_users egu ON egu.user_id = users.id
   LEFT JOIN entitlement_groups eg ON eg.inventory_pool_id = i.inventory_pool_id AND eg.id = egu.entitlement_group_id
   LEFT JOIN contracts c ON r.contract_id = c.id
   WHERE i.retired IS NULL
     AND eg.name like 'DDK - FFI'
     AND i.inventory_pool_id = (SELECT id FROM inventory_pools WHERE name like 'Ausleihe Toni-Areal')
   GROUP BY m.id, extract(YEAR FROM c.created_at), eg.name
   ORDER BY m.product || ' ' || coalesce(m.version, ''), extract(YEAR FROM c.created_at) DESC)
TO '/Users/nitaai/tmp/ausleihe-toni_contracts-per-year.csv' (format csv)
