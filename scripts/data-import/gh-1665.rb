# require_relative './parse_csv.rb'
# require_relative './logger.rb'

# test-server config
require_relative('logger')
# require_relative('shared/parse_csv')
require_relative('parse_csv')
require 'date'

# TODO: remove this
# RUN: bundle exec rails runner lib/scripts/import_models_and_items.rb
# https://github.com/leihs/leihs/issues/1665

# WORKFLOW
# 1. Upload csv-files (/tmp/leihs-scripts/*) by scp
# 2. Script runs once - commits only if all data are correct (all or nothing)
#  a) errors will be gathered and logged

# ------------------------------------------------------------------

# #  test-server: absolute path
IMPORT_FILE_MODELS = "/tmp/leihs-scripts/models-import.csv"
IMPORT_FILE_ITEMS = "/tmp/leihs-scripts/items-import.csv"

# current_path = Dir.pwd
# puts "Current Path is: #{current_path}"
# current_path = "#{current_path}/data-import"
# puts "Files Path is: #{current_path}"
#
# #  local setup
# IMPORT_FILE_MODELS = "#{current_path}/models-import.csv"
# IMPORT_FILE_ITEMS = "#{current_path}/items-import.csv"

# ------------------------------------------------------------------

# set this from "test-" to "" for production/stage
PREFIX_WITH_DASH_FOR_TEST_ENTRIES = ""

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

def to_bool(str, row, info)
  # puts "row[#{info}]: >#{row}<"
  # puts "str[#{info}]: >#{str}<"

  if str.nil?
    return nil
  end

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

    if row == "model;supplier;technical_detail;description"
      next
    end

    model_attributes = gen_model_attributes(row)

    begin
      # puts ">>?? model_attributes: #{model_attributes[:product]}"
      model = Model.find_by_name(model_attributes[:product])
      # puts ">> model: #{model}"



      if model.nil?
        Model.create(model_attributes).save!
      else
        puts "CAUTION: Model already exists: #{model_attributes[:product]}, description: #{model_attributes[:description]}"
      end

    rescue => e
      error_map["model/#{model_attributes[:product]}"] = { 'detail:': row, 'data': model_attributes, 'error': e.message }
    end
  end
end

def extract_building_name_and_code(building_name)
  puts "Expected format: '<building_name> <building_code>', building_name: >#{building_name}<"

  building_name_extracted = nil
  building_code_extracted = nil

  if building_name.include? ' ('
    building_name_extracted = building_name.match(/^(.*)\s\((.*)\)$/)[1]
    building_code_extracted = building_name.match(/^(.*)\s\((.*)\)$/)[2]

  else
    building_name_extracted = building_name
  end

  return building_code_extracted, building_name_extracted
end

def gen_item_attributes(row)
  model_name = "#{PREFIX_WITH_DASH_FOR_TEST_ENTRIES}#{row[ModelKeys::MODEL]}"

  # puts ">> model_name: #{model_name}"
  # puts ">> row: #{row}"

  if !PREFIX_WITH_DASH_FOR_TEST_ENTRIES.empty?
    log("DEV-MODE: model_name modified! model_name: #{model_name}", :warn, true)
  end

  owner_name = row[ItemKeys::OWNER]
  is_retired = to_bool(row[ItemKeys::RETIRED], row, 'is_retired/item-reason')
  responsible_department_name = row[ItemKeys::RESPONSIBLE_DEPARTMENT]

  room_name = row[ItemKeys::ROOM]
  puts ">> gen_item_attributes2 product: #{model_name}"

  model_rec = nil
  begin
    model_rec = Model.find_by!(product: model_name) # here
  rescue => e
    raise "#{model_name}: Model not found by model_name! model.name='#{model_name}' not found!"
  end

  puts ">> gen_item_attributes3"
  # owner_rec = InventoryPool.find_by!(name: owner_name)
  # puts ">> gen_item_attributes4"

  owner_rec = nil
  begin
    owner_rec = InventoryPool.find_by!(name: owner_name)

  rescue => e
    raise "#{owner_name}: No active Owner-InventoryPool found by name! InventoryPool.name='#{owner_name}' not found!"
  end

  responsible_department_name_rec = nil
  begin
    responsible_department_name_rec = InventoryPool.find_by!(name: responsible_department_name)

  rescue => e
    # raise "InventoryPool not found by name! InventoryPool/#{model_name} not found!" [:test "message"]
    raise "#{responsible_department_name}: No active InventoryPool found by name! InventoryPool.name='#{responsible_department_name}' not found!"
  end

  building_name = row[ItemKeys::BUILDING]
  building_code_extracted, building_name_extracted = extract_building_name_and_code(building_name)

  building_rec = nil
  begin
    if building_code_extracted.nil?
      building_rec = Building.find_by!(name: building_name)
    else
      building_rec = Building.find_by!(name: building_name_extracted, code: building_code_extracted)
    end
  rescue => e
    raise "#{building_name}: Building not found by name! Building.name='{building_name}' not found!"
  end

  room_rec = nil
  begin
    room_rec = Room.find_by!(building_id: building_rec.id, name: room_name)
  rescue => e
    raise "#{room_name}: Room not found by name! Room.building_id='#{building_rec.id}' / '#{building_rec.name}', name='#{room_name}' not found!"
  end

  item_attributes = {
    note: "#{PREFIX_WITH_DASH_FOR_TEST_ENTRIES}#{row[ItemKeys::NOTE]}",
    inventory_code: Item.proposed_inventory_code(responsible_department_name_rec, :lowest),
    serial_number: row[ItemKeys::SERIAL_NUMBER],
    is_broken: to_bool(row[ItemKeys::IS_BROKEN], row, "is_broken/#{room_name}/#{building_name}"),
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
    begin

      if row == "note;serial_number;retired;is_broken;owner;inventory_pool;building;room;properties_installation_status;model;inventory_code"
        next
      end

      item_attributes = gen_item_attributes(row)
      # puts ">> row: #{row}"
      # puts ">> item_attributes: #{item_attributes}"

      Item.create(item_attributes).save!
    rescue => e

      # puts ">> e.message: #{e.message}"
      # puts ">> item_attributes: #{item_attributes}"
      # puts ">> cl: #{item_attributes}"

      if item_attributes.nil?
        key = e.message.split(":")[0]
        error_map["items/#{key}"] = { 'data': key, 'error': e.message }
      else
        error_map["items/#{item_attributes[:note]}"] = { 'data': item_attributes, 'error': e.message }
      end
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

