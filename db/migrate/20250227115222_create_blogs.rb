class CreateBlogs < ActiveRecord::Migration[7.0]
  def change
    create_table :blogs, id: :uuid do |t|
      t.string :slug, null: false, index: { unique: true }
      t.string :title, null: false
      t.string :subtitle, null: false
      t.string :tag, null: false
      t.datetime :published_at, null: false

      t.timestamps
    end
  end
end
