module ResponseAggregator
  CONST_SKLAD = ['Главный склад Днепр  оптовый склад']
  CONST_GRUPSKLAD = ['ОСПП и ТСС', 'РОЗНИЦА']
  # CONST_PRICE = ["Интернет", "Маг", "Маг1", "Маг2", "Маг3", "Маг4", "Мин", "Опт",
  #                "Розница", "Спец", "Спец А", "Спец Б", "Спец С", "Тендер"]

  def query1_select_price(grouped_vidceny)
    str = ""
    grouped_vidceny.each_with_index do |el, i|
      str += "0 as Cena_#{i}"
      str += " , " if i < grouped_vidceny.length - 1
    end
    str
  end

  def query2_where_price(grouped_vidceny)
    str = ""
    grouped_vidceny.each_with_index do |el, i|
      str += "Prices.Vidceny = '#{el}' "
      str += " OR " if i < grouped_vidceny.length - 1
    end
    str
  end

  def query2_select_price(grouped_vidceny)
    str = ""
    grouped_vidceny.each_with_index do |el, i|
      str += "SUM(CASE WHEN Prices.Vidceny = '#{el}' THEN CAST(Prices.Cena AS INTEGER) ELSE 0 END) as Cena_#{i}"
      str += " , " if i < grouped_vidceny.length - 1
    end
    str
  end

  def hash_sklad (el,grup_el)
    h = {Sklad: el, GruppaSkladov: grup_el}
  end

  def arr_sklad
    sklad = "Винница ОСПП оптовый склад"
    arr = [sklad] + CONST_SKLAD
  end

  def query1_where_sklad
    str = ""
    arr_sklad.each_with_index do |el, i|
      str += i < 2 ? "Leftovers.Sklad = '#{el}' " : "Leftovers.GruppaSkladov = '#{el}' "
      str += " OR " if i < 3
    end
    str
  end

  def hash_query_params_sklad(skl, grup)
    hash = {Sklad: skl, GruppaSkladov: grup}
    array_query1_where = []
    array_query1_select = []
    array_query2_select = []
    array_name_sklad = []
    hash.each do |key, value|
      strSQL = key == :Sklad ? "Leftovers.Sklad" : "Leftovers.GruppaSkladov"

      if value.is_a?(Array) && !value.empty?
        value.each do |element|
          array_name_sklad << element
          array_query1_where << "#{strSQL} = '#{element}'"
          array_query1_select << "SUM(CASE WHEN #{strSQL} = '#{element}' THEN CAST(Leftovers.Kolichestvo AS INTEGER) ELSE 0 END) as Sklad_#{array_name_sklad.index(element)}"
          array_query2_select << "0 as Sklad_#{array_name_sklad.index(element)}"
        end
      end
    end


    hash_result = {
      array_query1_where: array_query1_where.join(' OR '),
      array_query1_select:array_query1_select.join(' , '),
      array_query2_select:array_query2_select.join(' , '),
      array_name_sklad: array_name_sklad
    }

  end


  def build_leftovers_combined_query_new(skl, grup)
    params_sklad = hash_query_params_sklad(skl, grup)
    # array_query1_where = []
    # array_query1_select = []
    # array_query2_select = []
    # array_name_sklad = []

    strSql = 'products.*'
    query1_select_sklad

    leftover_query = Leftover.joins(:product)
                             .select("Leftovers.Artikul as artikul,
                                    #{params_sklad[:array_query1_select]},
                                    #{query1_select_price(grouped_vidceny)},
                                    #{strSql}")
                             .where("#{params_sklad[:array_query1_where]}")
                             .group("Leftovers.Artikul, products.TovarnayaKategoriya")

    price_query = Price.joins(:product)
                       .select("Prices.Artikul as artikul,
                              #{params_sklad[:array_query2_select]},
                              #{query2_select_price(grouped_vidceny)},
                              #{strSql}")
                       .where("#{query2_where_price(grouped_vidceny)}")
                       .group("Prices.Artikul, products.TovarnayaKategoriya")


    @combined_results = Leftover.from("(#{leftover_query.to_sql} UNION #{price_query.to_sql}) AS leftovers_combined")
                                .order("leftovers_combined.TovarnayaKategoriya, leftovers_combined.artikul")


  end


  def query1_select_sklad
    str = ""
    arr_sklad.each_with_index do |el, i|
      param = i < 2 ? "Leftovers.Sklad = '#{el}' " : "Leftovers.GruppaSkladov = '#{el}' "
      str += "SUM(CASE WHEN #{param} THEN CAST(Leftovers.Kolichestvo AS INTEGER) ELSE 0 END) as Sklad_#{i}"
      str += " , " if i < 3
    end
    str
  end

  def query2_select_sklad
    str = ""
    arr_sklad.each_with_index do |el, i|
      str += "0 as Sklad_#{i}"
      str += " , " if i < 3
    end
    str
  end

  def build_leftovers_combined_query
    strSql = 'products.*'
    query1_select_sklad

    leftover_query = Leftover.joins(:product)
                             .select("Leftovers.Artikul as artikul,
                                    #{query1_select_sklad},
                                    #{query1_select_price(grouped_vidceny)},
                                    #{strSql}")
                             .where("#{query1_where_sklad}")
                             .group("Leftovers.Artikul, products.TovarnayaKategoriya")

    price_query = Price.joins(:product)
                       .select("Prices.Artikul as artikul,
                              #{query2_select_sklad},
                              #{query2_select_price(grouped_vidceny)},
                              #{strSql}")
                       .where("#{query2_where_price(grouped_vidceny)}")
                       .group("Prices.Artikul, products.TovarnayaKategoriya")


    @combined_results = Leftover.from("(#{leftover_query.to_sql} UNION #{price_query.to_sql}) AS leftovers_combined")
                                .order("leftovers_combined.TovarnayaKategoriya, leftovers_combined.artikul")


  end

  def grouped_results_all
    attr_query = ["artikul"]

    grouped_vidceny.each_with_index do |el, i|
      attr_query << "SUM(Cena_#{i}) as  `#{el}`"
    end

    arr_sklad.each_with_index do |el, i|
      attr_query << "SUM(Sklad_#{i}) as `#{el}`"
    end

    Product.first.attribute_names.each do |el|
      attr_query << "#{el}  as `#{el}`"
    end

    # grouped_results = build_leftovers_combined_query.group(:artikul).select( attr_query )

    skl = ['Винница ОСПП оптовый склад','Главный склад Днепр  оптовый склад']
    grup = ['ОСПП и ТСС', 'РОЗНИЦА']
    results = build_leftovers_combined_query_new(skl, grup)
    grouped_results = results.group(:artikul).select( attr_query )

  end

  def grouped_name_collumns_results_all
    attr_query = []

    Product.first.attribute_names.each do |el|
      attr_query << "#{el}"
    end

    arr_sklad.each_with_index do |el, i|
      attr_query << "#{el}"
    end

    grouped_vidceny.each_with_index do |el, i|
      attr_query << "#{el}"
    end

    attr_query
  end


end

class MyClass
  include ResponseAggregator
end

skl = ['Главный склад Днепр  оптовый склад', 'Главный склад ОСПП и ТСС']
grup = [ 'ОСПП и ТСС', 'РОЗНИЦА', 'tot']

d = MyClass.new
# p d.hash_sklad(skl, grup).inspect
p d.hash_query_params_sklad(skl, grup)
result = d.hash_query_params_sklad(skl, grup)
puts "="*100
puts "DEBUG array_query1_select: #{result[:array_query1_select]}"
puts "="*100
puts "DEBUG array_query1_where: #{result[:array_query1_where]}"
puts "="*100
puts "DEBUG array_query2_select: #{result[:array_query2_select]}"
puts "="*100
puts "DEBUG array_query2_select: #{result[:array_name_sklad]}"

# array_query1_where = []
# array_query1_select = []
# array_query2_select = []
# array_name_sklad = []