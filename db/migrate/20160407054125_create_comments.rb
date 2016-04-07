class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.string :namespace
      t.integer :number
      t.references :post
      t.text :url
      t.integer :revision_number, default: 1
      t.integer :stargazers_count, default: 0

      t.timestamps
    end

    add_index :comments, [:namespace,:number], unique: true
  end
end
