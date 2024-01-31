# require_relative './parse_csv.rb'
# require_relative './logger.rb'
require_relative('shared/logger')
require_relative('shared/parse_csv')
require 'date'

# TODO: remove this
# RUN: bundle exec rails runner lib/scripts/import_models_and_items.rb
# https://github.com/leihs/leihs/issues/1665

# FYI: comma separated values
IMPORT_FILE_MODELS = ENV['IMPORT_FILE'] # "model-import.csv"
IMPORT_FILE_ITEMS = ENV['IMPORT_FILE'] # "items-import.csv"

# set this from "test-" to "" for production/stage
PREFIX_WITH_DASH_FOR_TEST_ENTRIES = "test-"

PROPERTY_KEY_INSTALLATION_STATUS = "installation_status"
DEFAULT_RETIRED_REASON = "retired"

module ModelKeys
  MODEL = "model"
  MANUFACTURER = "supplier"
  TECHNICAL_DETAILS = "technical_detail"
  DESCRIPTION = "description"
end

module ItemKeys
  NOTE = "note"
  SERIAL_NUMBER = "serial_number"
  RETIRED = "retired"
  IS_BROKEN = "is_broken"
  OWNER = "owner"
  RESPONSIBLE_DEPARTMENT = "inventory_pool"
  BUILDING = "building"
  ROOM = "room"
  PROPERTIES = "properties_installation_status"
  MODEL = "model"
  INVENTORY_CODE = "inventory_code"
end

def to_bool(str, row)
  puts "row: >#{row}<"
  puts "str: >#{str}<"
  case str.downcase
  when 'true', 't', 'yes', 'y', '1'
    true
  when 'false', 'f', 'no', 'n', '0'
    false
  else
    nil
  end
end

def gen_model_attributes(row)
  model_attributes = {
    product: "#{PREFIX_WITH_DASH_FOR_TEST_ENTRIES}#{row[ModelKeys::MODEL]}",
    manufacturer: row[ModelKeys::MANUFACTURER],
    technical_detail: row[ModelKeys::TECHNICAL_DETAILS],
    description: row[ModelKeys::DESCRIPTION]
  }
  return model_attributes
end

def import_models_from_csv(error_map)
  csv_parser = CSVParser.new(IMPORT_FILE_MODELS)
  csv_parser.for_each_row do |row|
    model_attributes = gen_model_attributes(row)

    begin
      Model.create(model_attributes).save!
    rescue => e
      error_map["model/#{model_attributes[:product]}"] = { 'data': model_attributes, 'error': e.message }
    end
  end
end

def extract_building_name_and_code(building_name)
  building_name_extracted = building_name.match(/^(.*)\s\((.*)\)$/)[1]
  building_code_extracted = building_name.match(/^(.*)\s\((.*)\)$/)[2]

  return building_code_extracted, building_name_extracted
end

def gen_item_attributes(row)
  model_name = "#{PREFIX_WITH_DASH_FOR_TEST_ENTRIES}#{row[ModelKeys::MODEL]}"
  if !PREFIX_WITH_DASH_FOR_TEST_ENTRIES.empty?
    log("DEV-MODE: model_name modified! model_name: #{model_name}", :warn, true)
  end

  owner_name = row[ItemKeys::OWNER]
  is_retired = to_bool(row[ItemKeys::RETIRED], row)
  responsible_department_name = row[ItemKeys::RESPONSIBLE_DEPARTMENT]

  building_name = row[ItemKeys::BUILDING]
  building_code_extracted, building_name_extracted = extract_building_name_and_code(building_name)

  room_name = row[ItemKeys::ROOM]
  model_rec = Model.find_by!(product: model_name)
  owner_rec = InventoryPool.find_by!(name: owner_name)
  responsible_department_name_rec = InventoryPool.find_by!(name: responsible_department_name)
  building_rec = Building.find_by!(name: building_name_extracted, code: building_code_extracted)
  room_rec = Room.find_by!(building_id: building_rec.id, name: room_name)

  item_attributes = {
    note: "#{PREFIX_WITH_DASH_FOR_TEST_ENTRIES}#{row[ItemKeys::NOTE]}",
    inventory_code: Item.proposed_inventory_code(responsible_department_name_rec, :lowest),
    serial_number: row[ItemKeys::SERIAL_NUMBER],
    is_broken: to_bool(row[ItemKeys::IS_BROKEN], row),
    owner_id: owner_rec.id,
    inventory_pool_id: responsible_department_name_rec.id,
    room_id: room_rec.id,
    properties: { PROPERTY_KEY_INSTALLATION_STATUS => row[ItemKeys::PROPERTIES] },
    model_id: model_rec.id
  }

  # FIXME / FYI: there is no "retired" attribute on the Item model
  if is_retired
    item_attributes[:retired] = Date.today
    item_attributes[:retired_reason] = DEFAULT_RETIRED_REASON
  end

  item_attributes
end

def import_items_from_csv(error_map)
  csv_parser = CSVParser.new(IMPORT_FILE_ITEMS)
  csv_parser.for_each_row do |row|
    item_attributes = gen_item_attributes(row)

    begin
      Item.create(item_attributes).save!
    rescue => e
      error_map["items/#{item_attributes[:note]}"] = { 'data': item_attributes, 'error': e.message }
    end
  end
end

def log_errors_and_rollback(error_map)
  log("#{error_map.length} errors occurred", :error, true)
  log(error_map.to_json, :error, true)

  raise ActiveRecord::Rollback
end

def import_models_and_items
  ActiveRecord::Base.transaction do
    error_map = {}

    # FIXME: has to be done separately
    import_models_from_csv(error_map)
    import_items_from_csv(error_map)

    if error_map.length > 0 then
      log_errors_and_rollback(error_map)
    end

    log('IMPORT-PROCESS SUCCESSFULLY COMPLETED', :info, true)
  end
end

import_models_and_items
