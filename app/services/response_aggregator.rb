module ResponseAggregator
  # CONST_SKLAD = ['Главный склад Днепр  оптовый склад']
  # CONST_GRUPSKLAD = ['ОСПП и ТСС', 'РОЗНИЦА']
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


  def build_leftovers_combined_query(hash_with_params_sklad)
    @params_sklad = hash_with_params_sklad
    strSql = 'products.*'

    leftover_query = Leftover.joins(:product)
                             .select("Leftovers.Artikul as artikul,
                                    #{@params_sklad[:array_query1_select]},
                                    #{query1_select_price(grouped_vidceny)},
                                    #{strSql}")
                             .where("#{@params_sklad[:array_query1_where]}")
                             .group("Leftovers.Artikul, products.TovarnayaKategoriya")

    price_query = Price.joins(:product)
                       .select("Prices.Artikul as artikul,
                              #{@params_sklad[:array_query2_select]},
                              #{query2_select_price(grouped_vidceny)},
                              #{strSql}")
                       .where("#{query2_where_price(grouped_vidceny)}")
                       .group("Prices.Artikul, products.TovarnayaKategoriya")


    @combined_results = Leftover.from("(#{leftover_query.to_sql} UNION #{price_query.to_sql}) AS leftovers_combined")
                                .order("leftovers_combined.TovarnayaKategoriya, leftovers_combined.artikul")


  end

  def hash_grouped_name_collumns(array_name_sklad)
    attr_query = ["artikul"]
    attr_query_name_collumn = []

    Product.first.attribute_names.each do |el|
      attr_query_name_collumn << "#{el}"
      attr_query << "#{el}  as `#{el}`"
    end

    array_name_sklad.each_with_index do |el, i|
      attr_query_name_collumn << "#{el}"
      attr_query << "SUM(Sklad_#{i}) as `#{el}`"
    end

    grouped_vidceny.each_with_index do |el, i|
      attr_query_name_collumn << "#{el}"
      attr_query << "SUM(Cena_#{i}) as  `#{el}`"
    end

    attr_query
    hash_grouped = {attr_query_name_collumn:attr_query_name_collumn, attr_query:attr_query}
  end



end

class MyClass
  include ResponseAggregator
end

# skl = ['Главный склад Днепр  оптовый склад', 'Главный склад ОСПП и ТСС']
# grup = [ 'ОСПП и ТСС', 'РОЗНИЦА', 'tot']

# d = MyClass.new
# p d.hash_sklad(skl, grup).inspect
# p d.hash_query_params_sklad(skl, grup)
# result = d.hash_query_params_sklad(skl, grup)
puts "="*100

# array_query1_where = []
# array_query1_select = []
# array_query2_select = []
# array_name_sklad = []