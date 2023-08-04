class AddPodrazdelenieToLeftovers < ActiveRecord::Migration[7.0]
  def change
    add_column :leftovers, :Podrazdelenie, :string, default: ""
  end
end
