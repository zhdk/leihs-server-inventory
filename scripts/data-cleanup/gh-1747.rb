require_relative('shared/logger')
require_relative('shared/parse_csv')
# require('pry')

csv_parser = CSVParser.new("#{ENV['CSV_DIR_PATH']}/import.csv")

csv_parser.for_each_row do |row|
  h = row.to_hash
  begin
    item = Item.find_by_inventory_code(h["Inventarcode"])
    if item.retired and item.retired_reason.nil?
      item.update!(retired_reason: 'Ausmusterungsgrund unbekannt')
    end
    item.update!(room_id: h["RAUM NEU"])
    csv_parser.row_success!
  rescue => e
    log("Item-ID #{item.id}: #{e.message}", 'info', true)
  end
end
