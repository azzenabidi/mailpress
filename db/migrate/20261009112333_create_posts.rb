class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.string :author_email
      t.references :inbound_email, foreign_key: { to_table: :action_mailbox_inbound_emails }

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :status
    add_index :posts, :published_at
  end
end
