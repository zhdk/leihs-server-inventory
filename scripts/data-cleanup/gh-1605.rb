
# encoding: UTF-8

require('pry')

ActiveRecord::Base.connection.execute <<~SQL
  UPDATE model_links
  SET model_group_id=(SELECT id FROM model_groups WHERE name like 'Möbel- und Grossrequisitenfundus DDK')
  WHERE model_group_id = (SELECT id FROM model_groups WHERE name like 'Möbel NIHA');
SQL
