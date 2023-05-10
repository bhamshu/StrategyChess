class AddTurnToGame < ActiveRecord::Migration[6.0]
  def change
    add_column :games, :turn, :uuid, null: true, foreign_key: {to_table: :players}, type: :uuid
  end
end
