COPY (
  SELECT m.id,
  m.product || ' ' || coalesce(m.version, '') AS model_name,
  count(*) AS items_count,
  max(i.last_check) AS last_check,
  min(i.created_at) AS first_procurement,
  count(DISTINCT r.contract_id) AS number_of_contracts
  FROM items i
  JOIN models m ON m.id = i.model_id
  LEFT JOIN reservations r ON r.item_id = i.id
  JOIN contracts c ON r.contract_id = c.id
  WHERE i.inventory_pool_id = '77e88ec8-9ff6-5435-818e-dc902fc631a6'
  GROUP BY m.id
  ORDER BY m.product || ' ' || coalesce(m.version, '')
) TO '/Users/nitaai/tmp/all-items.csv' (format csv)

COPY (
  SELECT m.id,
  m.product || ' ' || coalesce(m.version, '') AS model_name,
  count(*) AS items_count,
  max(i.last_check) AS last_check,
  min(i.created_at) AS first_procurement,
  count(DISTINCT r.contract_id) AS number_of_contracts
  FROM items i
  JOIN models m ON m.id = i.model_id
  LEFT JOIN reservations r ON r.item_id = i.id
  JOIN contracts c ON r.contract_id = c.id
  WHERE i.retired IS NULL
  AND i.inventory_pool_id = '77e88ec8-9ff6-5435-818e-dc902fc631a6'
  GROUP BY m.id
  ORDER BY m.product || ' ' || coalesce(m.version, '')
) TO '/Users/nitaai/tmp/all-unretired-items.csv' (format csv)

COPY (
  SELECT m.id,
  m.product || ' ' || coalesce(m.version, '') AS model_name,
  extract(year from c.created_at),
  count(DISTINCT r.contract_id) AS number_of_contracts
  FROM items i
  JOIN models m ON m.id = i.model_id
  LEFT JOIN reservations r ON r.item_id = i.id
  JOIN contracts c ON r.contract_id = c.id
  WHERE i.retired IS NULL
  AND i.inventory_pool_id = '77e88ec8-9ff6-5435-818e-dc902fc631a6'
  GROUP BY m.id, extract(year from c.created_at)
  ORDER BY m.product || ' ' || coalesce(m.version, ''), extract(year from c.created_at) DESC
) TO '/Users/nitaai/tmp/contracts-per-year.csv' (format csv)
