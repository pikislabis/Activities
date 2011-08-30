# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110622225343) do

  create_table "activities", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "project_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "alerts", :force => true do |t|
    t.integer  "user_id"
    t.string   "text"
    t.date     "date"
    t.integer  "frequency"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "attachments", :force => true do |t|
    t.string   "name"
    t.integer  "record_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "incidences", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "origin"
    t.integer  "user_id"
    t.string   "state"
    t.string   "priority"
    t.string   "type_inc"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "assigned_to"
  end

  create_table "passwords", :force => true do |t|
    t.integer  "user_id"
    t.string   "reset_code"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "billable"
  end

  create_table "projects_users", :id => false, :force => true do |t|
    t.integer  "project_id", :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "records", :force => true do |t|
    t.integer  "user_id"
    t.integer  "incidence_id"
    t.text     "text1"
    t.text     "text2"
    t.integer  "asigned_to"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id", :default => 0, :null => false
    t.integer "user_id", :default => 0, :null => false
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "spendings", :id => false, :force => true do |t|
    t.date     "date"
    t.integer  "user_id"
    t.string   "place"
    t.decimal  "kms",        :precision => 5, :scale => 2
    t.decimal  "parking",    :precision => 5, :scale => 2
    t.decimal  "food",       :precision => 5, :scale => 2
    t.decimal  "represent",  :precision => 5, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "activity_id",                               :null => false
    t.integer  "user_id",                                   :null => false
    t.date     "date",                                      :null => false
    t.decimal  "hours",       :precision => 3, :scale => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks_validateds", :force => true do |t|
    t.integer  "user_id"
    t.integer  "week"
    t.integer  "year"
    t.integer  "validated"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "long_name"
    t.string   "name"
    t.string   "nick"
    t.string   "email"
    t.string   "email_corp"
    t.string   "address"
    t.integer  "phone"
    t.string   "crypted_password"
    t.string   "salt"
    t.string   "activation_code"
    t.string   "state"
    t.datetime "activated_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
