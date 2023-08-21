# encoding: UTF-8
# run with "rails runner -e production PATH_TO_THIS_FILE"
# WARNING: USE AT YOUR OWN RISK!!!

require_relative('shared/logger')
# require_relative('shared/parse_csv')
# require('pry')

User.where("organization != 'zhdk.ch' and email ~* '@zhdk\\.ch$'").each do |user|
  log("#{user.id},#{user.name},#{user.email}", :info, true)
  h = { "old_email" => user.email }
  if user.extended_info 
    user.extended_info.merge!(h)
  else
    user.extended_info = h
  end
  user.email = nil
  user.save!
end
