class AddCompoundUniqueIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :posts, [:namespace,:number], unique: true
  end
end
