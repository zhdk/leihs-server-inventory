# encoding: UTF-8
# run with "rails runner -e production PATH_TO_THIS_FILE"
# WARNING: USE AT YOUR OWN RISK!!!

require_relative('shared/logger')
require_relative('shared/parse_csv')
# require('pry')

csv_parser = CSVParser.new(ENV['IMPORT_FILE'])

csv_parser.for_each_row do |row|
  ic = row['Inventarcode']
  log("updating #{ic}", :info, true)
  item = Item.find_by_inventory_code(ic)
  if item
    item.is_inventory_relevant = true
    item.properties['anschaffungskategorie'] = row['Beschaffungsgruppe']
    item.save!
    csv_parser.row_success!
  else
    log("could not find #{ic}", :info, true)
  end
end
