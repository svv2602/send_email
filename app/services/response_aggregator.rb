module ResponseAggregator

  def hash_query_params_all(skl, grup, price, product, max_count)
    array_query1_where = []
    array_query2_where = []
    array_query1_select = []
    array_query2_select = []
    array_name = []
    array_name_sum = []

    # обработка списка складов
    hash = { Sklad: skl, GruppaSkladov: grup }
    hash.each do |key, value|
      strSQL = key == :Sklad ? "Leftovers.Sklad" : "Leftovers.GruppaSkladov"

      if value.is_a?(Array) && !value.empty?
        value.each do |element|
          array_name_sum << element
          array_query1_where << "#{strSQL} = '#{element}'"

          array_query1_select << "CASE
          WHEN SUM(CASE WHEN #{strSQL} = '#{element}' THEN CAST(Leftovers.Kolichestvo AS INTEGER) ELSE 0 END) < #{max_count} THEN
          SUM(CASE WHEN #{strSQL} = '#{element}' THEN CAST(Leftovers.Kolichestvo AS INTEGER) ELSE 0 END)
          ELSE
          #{max_count}
          END AS Field_#{array_name_sum.index(element)}"

          array_query2_select << "0 as Field_#{array_name_sum.index(element)}"
        end
      end
    end

    # Обработка списка цен
    if price.is_a?(Array) && !price.empty?
      price.each do |element|
        array_name_sum << element
        array_query2_where << "Prices.Vidceny = '#{element}' "
        array_query2_select << "SUM(CASE WHEN Prices.Vidceny = '#{element}' THEN CAST(Prices.Cena AS INTEGER) ELSE 0 END) as Field_#{array_name_sum.index(element)}"
        array_query1_select << "0 as Field_#{array_name_sum.index(element)}"
      end
    end

    # Обработка таблицы товаров
    if product.is_a?(Array) && !product.empty?
      product.each do |element|
        array_query1_select << "products.#{element}"
        array_query2_select << "products.#{element}"
        array_name << "#{element}"
      end
    end

    hash_result = {
      array_query1_where: array_query1_where.join(' OR '),
      array_query2_where: array_query2_where.join(' OR '),
      array_query1_select: array_query1_select.join(' , '),
      array_query2_select: array_query2_select.join(' , '),
      array_name: array_name,
      array_name_sum: array_name_sum,
      array_name_sklad: array_name + array_name_sum
    }

  end

  def build_leftovers_combined_query(hash_with_params_sklad)
    @params_sklad = hash_with_params_sklad
    strSql = 'products.*'

    leftover_query = Leftover.joins(:product)
                             .select("Leftovers.Artikul as artikul,
                                    #{@params_sklad[:array_query1_select]}")
                             .where("#{@params_sklad[:array_query1_where]}")
                             .group("Leftovers.Artikul, products.TovarnayaKategoriya")

    price_query = Price.joins(:product)
                       .select("Prices.Artikul as artikul,
                              #{@params_sklad[:array_query2_select]}")
                       .where("#{@params_sklad[:array_query2_where]}")
                       .group("Prices.Artikul, products.TovarnayaKategoriya")

    @combined_results = Leftover.from("(#{leftover_query.to_sql} UNION #{price_query.to_sql}) AS leftovers_combined")
                                .order("leftovers_combined.TovarnayaKategoriya, leftovers_combined.artikul")

  end

  def hash_grouped_name_collumns(hash_with_params)
    attr_query = ["artikul"]
    attr_query_name_collumn = []

    hash_with_params[:array_name].each do |el|
      attr_query_name_collumn << "#{el}"
      attr_query << "#{el} as `#{el}`"
    end

    hash_with_params[:array_name_sum].each_with_index do |el, i|
      attr_query_name_collumn << "#{el}"
      attr_query << "SUM(Field_#{i}) as `#{el}`"
    end

    attr_query
    hash_grouped = { attr_query_name_collumn: attr_query_name_collumn, attr_query: attr_query }
  end

end

class MyClass
  include ResponseAggregator
end

# price = ["Интернет", "Маг", "Маг1", "Маг2", "Маг3", "Маг4", "Мин", "Опт",
#          "Розница", "Спец", "Спец А", "Спец Б", "Спец С", "Тендер"]
# skl = ['Винница ОСПП оптовый склад', 'Главный склад Днепр  оптовый склад']
# grup = ['ОСПП и ТСС', 'РОЗНИЦА']
# product = ["id", "Artikul", "Nomenklatura", "Ves", "Proizvoditel", "VidNomenklatury", "TipTovara", "TovarnayaKategoriya"]
#
# d = MyClass.new
# result = d.hash_query_params_all(skl, grup, price, product)
# hash_with_params_sklad = result
# puts "Debug" + "=" * 100
# puts d.hash_grouped_name_collumns(hash_with_params_sklad)[:attr_query]

puts "=" * 100
# puts "array_query1_select : #{result[:array_name_sklad]}"
puts "=" * 100

# array_query1_where = []
# array_query1_select = []
# array_query2_select = []
# array_name_sklad = []