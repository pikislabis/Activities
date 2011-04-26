class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks, :id => false do |t|
		t.integer :activity_id, :null => false, :options =>
			"CONSTRAINT fk_task_activities REFERENCES activities(id)"
		t.integer :user_id, :null => false, :options =>
			"CONSTRAINT fk_task_users REFERENCES users(id)"
		t.date :date, :null => false
		t.decimal :hours, :precision => 3, :scale => 1
      t.timestamps
    end
  end
  
  def self.down
    drop_table :tasks
  end
end