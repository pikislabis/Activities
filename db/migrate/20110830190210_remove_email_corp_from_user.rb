class RemoveEmailCorpFromUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :email_corp
  end

  def self.down
    add_column :users, :email_corp, :string
  end
end
