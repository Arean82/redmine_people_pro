
class AddColumnsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :client_type, :string
    add_column :users, :emp_id, :string
    add_column :users, :personal_email_id, :string
    add_column :users, :anual_ctc, :string
    add_column :users, :experience, :string

  end

end
