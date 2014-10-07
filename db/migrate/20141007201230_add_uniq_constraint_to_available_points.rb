class AddUniqConstraintToAvailablePoints < ActiveRecord::Migration
  def change
    add_index :available_points, [:exercise_id, :name], :unique => true
  end
end
