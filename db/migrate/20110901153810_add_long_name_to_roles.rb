class AddLongNameToRoles < ActiveRecord::Migration
  def self.up
    add_column :roles, :long_name, :string
  end

  def self.down
    remove_column :roles, :long_name
  end
end
