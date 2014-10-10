class AddAccountConfirmationKey < ActiveRecord::Migration
  def change
    create_table :account_confirmation_keys do |t|
      t.integer :user_id, :null => false
      t.text :code, :null => false

      t.timestamps
    end

    add_foreign_key "account_confirmation_keys", "users", :dependent => :delete
  end
end
