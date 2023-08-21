# FIND
new_end_date = Date.parse('2022-01-31')
target_pool = InventoryPool.find_by!(name: 'IT-Zentrum')
option = Option.find_by!(inventory_code: 'Mo2020')
reservations = Reservation.where(option_id: option.id)
contracts = reservations
.map(&:contract).compact
.select {|c| c.state == 'open' }
.uniq
puts "FOUND #{contracts.count} open contracts with option ID #{option.id}"
moved_count = 0

# MOVE
begin
  ActiveRecord::Base.transaction do
    option.update_attributes!(inventory_pool_id: target_pool.id) 
    contracts.each do |c|
      # NOTE: when the contract contains *other* options, not belonging to the target pool, we can not move!
      if c.reservations.where(type: 'OptionLine').where.not(option_id: option.id).any?
        puts "SKIPPED contract ID #{c.id}"
      else
        c.update_attributes!(inventory_pool_id: target_pool.id)
        c.reservations.each do |r| 
          r.update_attributes!(inventory_pool_id: target_pool.id, end_date: new_end_date)
        end
        c.reservations.map(&:order).compact.uniq.each {|o| o.update_attributes!(inventory_pool_id: target_pool.id)}
        moved_count = moved_count + 1
        puts "MOVED contract ID #{c.id}"
      end
    end
  end
rescue ActiveRecord::RecordInvalid => exception
  binding.pry
end

puts "OK! MOVED #{moved_count}/#{contracts.count} contracts to pool ID #{target_pool.id}"