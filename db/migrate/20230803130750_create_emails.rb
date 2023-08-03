class CreateEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :emails do |t|
      t.string :to
      t.string :subject
      t.text :body
      t.boolean :delivered, default: false

      t.timestamps
    end
  end
end
