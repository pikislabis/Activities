class CreateIncidences < ActiveRecord::Migration
  def self.up
    create_table :incidences do |t|
      t.string :title
      t.text :description
      t.integer :origin
      t.integer :user_id
      t.string :state
      t.string :priority
      t.string :type_inc

      t.timestamps
    end
  end

  def self.down
    drop_table :incidences
  end
end
