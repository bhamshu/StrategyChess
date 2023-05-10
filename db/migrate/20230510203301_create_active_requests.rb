class CreateActiveRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :active_requests do |t|
      t.references :from, type: :uuid, null: false, foreign_key: {to_table: :players}, index: true 
      t.references :to, type: :uuid, null: false, foreign_key: {to_table: :players}, index: true

      t.timestamps
    end
  end
end
