class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
    	t.string :long_name
		  t.string :name
  		t.string :nick
  		t.string :email
  		t.string :email_corp
  		t.string :address
  		t.integer :phone
      t.string :hashed_password
      t.string :salt
      t.string :activation_code
      t.string :state
      t.datetime :activated_at
      t.datetime :deleted_at
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
