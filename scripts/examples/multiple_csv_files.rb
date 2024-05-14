require_relative('./shared/logger')
require_relative('./shared/parse_csv')
# require('pry')

csv_parser_1 = CSVParser.new("#{ENV['CSV_DIR_PATH']}/file1.csv")
csv_parser_2 = CSVParser.new("#{ENV['CSV_DIR_PATH']}/file2.csv")

[csv_parser_1, csv_parser_2].each do |csv_parser|
  csv_parser.for_each_row do |row|
    h = row.to_hash
    log(h, 'info', true)
  end
end
