class IntroducePermissionsForUsersToManageCourses < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.references :user
      t.references :course
      t.text :permissions

      t.timestamps
    end
    add_index :permissions, [:user_id, :course_id], :unique => true
  end
end
