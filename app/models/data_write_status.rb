class DataWriteStatus < ApplicationRecord
  def self.in_progress?
    where(in_progress: true).exists?
  end

  def self.set_in_progress(value)
    update_all(in_progress: value)
  end

end
