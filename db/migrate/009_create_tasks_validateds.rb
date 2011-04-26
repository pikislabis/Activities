class CreateTasksValidateds < ActiveRecord::Migration
  def self.up
    create_table :tasks_validateds do |t|
      t.integer :user_id
      t.integer :week
      t.integer :year
      t.integer :validated

      t.timestamps
    end
  end

  def self.down
    drop_table :tasks_validated
  end
end
