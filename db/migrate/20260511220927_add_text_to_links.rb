class AddTextToLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :links, :text, :string
  end
end
