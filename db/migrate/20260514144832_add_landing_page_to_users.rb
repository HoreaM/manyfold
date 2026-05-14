class AddLandingPageToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :landing_page, :string, null: true, default: nil
  end
end
