class CreateUserProjects < ActiveRecord::Migration
  def self.up
    create_table :user_projects, :id => false do |t|
		t.integer :project_id, :null => false, :options =>
			"CONSTRAINT fk_user_project_projects REFERENCES projects(id)"
		t.integer :user_id, :null => false, :options =>
			"CONSTRAINT fk_user_project_users REFERENCES users(id)"

      	t.timestamps
    end
  end

  def self.down
    drop_table :user_projects
  end
end
