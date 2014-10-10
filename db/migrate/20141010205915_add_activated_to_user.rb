class AddActivatedToUser < ActiveRecord::Migration
  def change
    add_column :users, :activated, :boolean, default: false
    User.update_all(activated: true)
  end
end
