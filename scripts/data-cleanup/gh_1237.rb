# FIND
# when prolonging again, only this date needs to be changed:
new_end_date = Date.parse "2022-07-31"
# ##########################################################
target_pool = InventoryPool.find_by!(name: "IT-Zentrum")
option = Option.find_by!(inventory_code: "Mo2020")
reservations = Reservation.where(option_id: option.id, status: "signed")
puts "FOUND #{reservations.count} open reservations with option ID #{option.id}"

# PROLONG
reservations.each do |r|
  old_end_date = r.end_date
  r.update_attributes!(end_date: new_end_date)
  puts "prolonged reservation / was #{old_end_date} / contract ID #{r.contract.compact_id} / ID #{r.id} "
end
puts "OK! prolonged #{reservations.count} reservations until #{new_end_date}"
