class Price < ApplicationRecord
  belongs_to :product, foreign_key: 'Artikul', primary_key: 'Artikul'
end
