# encoding: UTF-8

require('pry')
# require_relative('shared/logger')
# require_relative('shared/parse_csv')

#################################################################################
# DOES NOT WORK ON STAGING ######################################################
#################################################################################
# pool_old = InventoryPool.find_by!(name: "Fundus-DDK")
# pool_new = InventoryPool.find_by!(name: "Fundus Niederhasli-DDK")
# items = Item.where(inventory_pool: pool_old).where("inventory_code LIKE 'N%'")
# room = Room.find_by!(id: "1368a869-18e6-40f6-8073-eb1b54fd5453")
# category = Category.find_by!(id: "6849fe50-d5f8-440b-ab66-928729805e8b")
# # delete_category = Category.find_by!(name: "Fundus LÖSCHEN")

# items.each do |item|
#   item.update!(inventory_pool: pool_new,
#                owner: pool_new,
#                room: room,
#                is_borrowable: true)
#   item.model.update!(categories: [category])
# end

# delete_category.destroy!
#################################################################################
#################################################################################
#################################################################################

ActiveRecord::Base.connection.execute <<~SQL
  UPDATE items
  SET inventory_pool_id = '561c02a0-e7e1-404b-aafe-c4d5d63da8a3',
      owner_id = '561c02a0-e7e1-404b-aafe-c4d5d63da8a3',
      room_id = '1368a869-18e6-40f6-8073-eb1b54fd5453',
      is_borrowable = TRUE
  WHERE inventory_pool_id = 'a02b8163-9a16-5066-b48e-9eb74cf8b791' 
    AND inventory_code LIKE 'N%'
SQL

ActiveRecord::Base.connection.execute <<~SQL
  DELETE FROM model_links
  WHERE model_id IN (
    SELECT model_id
    FROM items
    WHERE inventory_pool_id = 'a02b8163-9a16-5066-b48e-9eb74cf8b791'
      AND inventory_code LIKE 'N%'
  );
SQL

ActiveRecord::Base.connection.execute <<~SQL
  INSERT INTO model_links (model_id, model_group_id)
  SELECT DISTINCT(model_id), '6849fe50-d5f8-440b-ab66-928729805e8b'::uuid
  FROM items
  WHERE inventory_pool_id = '561c02a0-e7e1-404b-aafe-c4d5d63da8a3'
    AND inventory_code LIKE 'N%'
SQL
