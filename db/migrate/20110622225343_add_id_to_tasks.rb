class AddIdToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :id, :primary_key
  end

  def self.down
    remove_column :tasks, :id
  end
end