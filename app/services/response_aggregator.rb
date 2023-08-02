module ResponseAggregator
  CONST_SKLAD = ['Главный склад Днепр  оптовый склад', 'ОСПП и ТСС', 'РОЗНИЦА']
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

    grouped_results = build_leftovers_combined_query.group(:artikul).select( attr_query )
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

class TestMe
  include ResponseAggregator
end

grouped_vidceny = ["Интернет", "Маг", "Маг1", "Маг2", "Маг3", "Маг4", "Мин", "Опт",
                   "Розница", "Спец", "Спец А", "Спец Б", "Спец С", "Тендер"]
d = TestMe.new
# puts d.query1_where_sklad
# puts d.query1_select_sklad
puts d.query2_select_sklad
# puts d.query2_where_price(grouped_vidceny)
# puts d.query2_select_price(grouped_vidceny)
# puts d.query1_select_price(grouped_vidceny)

