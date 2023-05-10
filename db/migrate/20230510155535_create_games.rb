class CreateGames < ActiveRecord::Migration[6.0]
  def change
    create_table :games, id: :uuid do |t|
      t.text :state

      t.timestamps
    end
  end
end
