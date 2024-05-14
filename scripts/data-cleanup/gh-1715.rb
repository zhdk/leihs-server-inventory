require_relative('shared/logger')
require_relative('shared/parse_csv')
# require('pry')

csv_parser = CSVParser.new("#{ENV['CSV_DIR_PATH']}/import.csv")

class ProcurementRequest < ActiveRecord::Base
end

csv_parser.for_each_row do |row|
  h = row.to_hash
  begin
    old_room = Room.find(h["id1"])
    new_room = Room.find(h["new_room_id"])
    old_room.items.update_all(room_id: new_room.id)
    ProcurementRequest.where(room_id: old_room.id).update_all(room_id: new_room.id)
    old_room.destroy! unless old_room.general?
    csv_parser.row_success!
  rescue => e
    log(e.message, 'info', true)
  end
end
