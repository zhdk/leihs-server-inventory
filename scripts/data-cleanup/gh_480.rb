# run with "rails runner -e production PATH_TO_THIS_FILE"
# WARNING: USE AT YOUR OWN RISK!!!

query = <<-SQL
  with fundus_item_ids
  as (
  	select
  		distinct items.id
  	from
  		items,
  		inventory_pools
  	where
      items.inventory_pool_id = inventory_pools.id
      and items.owner_id = inventory_pools.id
  		and inventory_pools.name = 'Fundus-TdK'
  )
  update
  	items
  set
  	note = (
      select case
        when items.note is null or items.note = '' then
          name
        else
          items.note || chr(10) || name
      end
    )
  where
  	items.id in (select * from fundus_item_ids)
    and items.name is not null
    and items.name <> ''
    and items.name <> 'no name'
    and items.name <> 'ohne namen'
    and items.name <> 'no Name'
    and items.name <> 'ohne Namen'
SQL

ActiveRecord::Base.transaction do
  ActiveRecord::Base.connection.exec_update query
end
