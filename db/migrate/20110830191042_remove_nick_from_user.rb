class RemoveNickFromUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :nick
  end

  def self.down
    add_column :users, :nick, :string
  end
end
