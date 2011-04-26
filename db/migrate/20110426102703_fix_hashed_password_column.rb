class FixHashedPasswordColumn < ActiveRecord::Migration
  def self.up
    rename_column :users, :hashed_password, :crypted_password
  end

  def self.down
    rename_column :users, :crypted_password, :hashed_password
  end
end
