class AddAssignedToToIncidence < ActiveRecord::Migration
  def self.up
    add_column :incidences, :assigned_to, :integer
  end

  def self.down
    remove_column :incidences, :assigned_to
  end
end