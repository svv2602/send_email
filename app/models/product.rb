class Product < ApplicationRecord
  has_many :prices, foreign_key: 'Artikul', primary_key: 'Artikul', dependent: :destroy
  has_many :leftovers, foreign_key: 'Artikul', primary_key: 'Artikul', dependent: :destroy

end
