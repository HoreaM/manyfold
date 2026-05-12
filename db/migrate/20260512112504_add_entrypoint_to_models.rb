class AddEntrypointToModels < ActiveRecord::Migration[8.0]
  def change
    add_reference :models, :entrypoint, null: true, foreign_key: {to_table: :model_files}
  end
end
