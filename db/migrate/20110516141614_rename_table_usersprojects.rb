class RenameTableUsersprojects < ActiveRecord::Migration
  def self.up
    rename_table :user_projects, :projects_users
  end

  def self.down
    rename_table :projects_users, :user_projects
  end
end
