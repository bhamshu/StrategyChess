class CreatePlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :players, id: :uuid do |t|
      t.references :games, null: false, foreign_key: true, type: :uuid
      t.string :uniq_pub_name

      t.timestamps
    end
    add_index :players, :uniq_pub_name, unique: true
  end
end
