class CreateSpendings < ActiveRecord::Migration
  def self.up
    create_table :spendings, :id => false do |t|
      t.date :date
      t.integer :user_id
      t.string :place
      t.decimal :kms, :precision => 5, :scale => 2
      t.decimal :parking, :precision => 5, :scale => 2
      t.decimal :food, :precision => 5, :scale => 2
      t.decimal :represent, :precision => 5, :scale => 2

      t.timestamps
    end
  end

  def self.down
    drop_table :spendings
  end
end
