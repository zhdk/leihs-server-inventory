# run with "rails runner -e production PATH_TO_THIS_FILE"
# WARNING: USE AT YOUR OWN RISK!!!

require_relative('shared/logger')
require_relative('shared/parse_csv')
# require('pry')

csv_parser = CSVParser.new(ENV['IMPORT_FILE'])

counter = 1
csv_parser.for_each_row do |row|
  building_id = Building.find_by!(name: row['Liegenschaft']).id
  name = row['Raumnummer']
  description = row['RBez. Reservierung']

  begin
    room = \
      Room
      .where('lower(name) = lower(?)', name)
      .where(building_id: building_id)
      .first

    if room
      room.update_attributes!(name: name, description: description)
      log "#{counter} updating: #{row['Liegenschaft']} - #{row['Raumnummer']}", :info, true
      csv_parser.row_success!
    else
      Room.create!(building_id: building_id, name: name, description: description)
      log "#{counter} creating: #{row['Liegenschaft']} - #{row['Raumnummer']}", :info, true
      csv_parser.row_success!
    end

  rescue => e
    log "#{counter} #{e.message}", :error, true
  end

  counter += 1
end
