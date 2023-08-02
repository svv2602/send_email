require_relative '../models/leftover'
require_relative 'response_aggregator'

class MyService
  def process_leftovers
    results = ResponseAggregator.group_by_artikul_with_sum
    # Добавьте свою логику обработки результатов
    puts results
  end
end

f = MyService.new
f.process_leftovers