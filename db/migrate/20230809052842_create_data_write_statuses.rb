class CreateDataWriteStatuses < ActiveRecord::Migration[7.0]
  def change
    create_table :data_write_statuses do |t|
      t.boolean :in_progress

      t.timestamps
    end
  end
end
