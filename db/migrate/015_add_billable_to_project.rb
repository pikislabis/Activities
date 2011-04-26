class AddBillableToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :billable, :boolean
  end

  def self.down
    remove_column :projects, :billable
  end
end
