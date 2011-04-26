class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
    	t.string :name
		t.text :description
		t.integer :project_id, :null => false, :options =>
			"CONSTRAINT fk_activity_projects REFERENCES projects(id)"

      t.timestamps
    end
  end

  def self.down
    drop_table :activities
  end
end
