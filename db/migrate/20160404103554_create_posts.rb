class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.string :namespace
      t.integer :number
      t.text :name
      t.text :url
      t.integer :revision_number
      t.integer :comments_count
      t.integer :stargazers_count
      t.integer :watchers_count

      t.timestamps
    end
  end
end
