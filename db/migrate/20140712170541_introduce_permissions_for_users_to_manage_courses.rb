class IntroducePermissionsForUsersToManageCourses < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.references :user
      t.references :course
      t.string :permissions, array: true

      t.timestamps
    end
  end
end
