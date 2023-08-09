class CreateInitialDataWriteStatus < ActiveRecord::Migration[7.0]
  def up
    DataWriteStatus.create!(in_progress: false) # Создание начальной записи
  end

  def down
    DataWriteStatus.destroy_all
  end
end
