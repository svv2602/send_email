module ResponseAggregatorMethods
  extend ActiveSupport::Concern

  included do
    def hash_query_params_all(skl, city, grup, podrazdel, price, product, max_count, sheet_select)
      array_query1_where = []
      array_query2_where = []
      array_query1_select = []
      array_query2_select = []
      array_name_product = {}
      array_name_sum = []

      # обработка списка складов
      hash = { Gorod: city, Sklad: skl, GruppaSkladov: grup, Podrazdelenie: podrazdel }
      hash.each do |key, value|
        strSQL = "Leftovers.#{key.to_s}"

        if value.is_a?(Array) && !value.empty? && value != ""
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

      # Обработка таблицы товаров (cвойства номенклатуры в столбцы)
      if product.is_a?(Array) && !product.empty?
        hash_product = db_columns[:Product]
        product.each do |element|

          str = element.gsub(" ", "")
          hash_product.each do |key, value|
            if value.downcase == str.downcase
              array_query1_select << "products.#{key}"
              array_query2_select << "products.#{key}"
              array_name_product[key] = value
              # array_name << element
            end
          end

        end
      end

      # Массивы преобразовываем в строку
      str_array_query1_where = "(#{array_query1_where.join(' OR ')})"
      str_array_query2_where = "(#{array_query2_where.join(' OR ')})"
      str_array_query1_select = array_query1_select.join(' , ')
      str_array_query2_select = array_query2_select.join(' , ')

      # обработка критериев отбора по листу и добавление их в итоговую строку отбора
      sheet_select.each do |key, value|
        if value.is_a?(Array) && !value.empty?
          arr = []
          value.each do |element|
            arr << "products.#{key.to_s} = '#{element}' " if key == :VidNomenklatury #
          end
          unless arr.empty?
            str_array_query1_where += " AND (#{arr.join(' OR ')})"
            str_array_query2_where += " AND (#{arr.join(' OR ')})"
          end
        end
      end

      hash_result = {
        array_query1_where: str_array_query1_where.gsub("() AND ", ""),
        array_query2_where: str_array_query2_where.gsub("() AND ", ""),
        array_query1_select: str_array_query1_select,
        array_query2_select: str_array_query2_select,
        array_name_sum: array_name_sum,
        array_name_product: array_name_product
      }

    end

    def contains_only_brackets?(string)
      # регулярное выражение для проверки наличия в строке только скобок
      /^[()]*$/.match?(string)
    end

    def build_leftovers_combined_query(hash_with_params_sklad)
      @params_sklad = hash_with_params_sklad
      strSql = 'products.*'

      leftover_query = Leftover.joins(:product)
                               .select("Leftovers.Artikul as artikul, products.TovarnayaKategoriya as Tovar_Kategoriya,
                                    #{@params_sklad[:array_query1_select]}")
                               # .where("(#{@params_sklad[:array_query1_where]})")
                               .tap do |query|
                                  unless @params_sklad[:array_query1_where].blank? || contains_only_brackets?(@params_sklad[:array_query1_where])
                                    query.where!("(#{@params_sklad[:array_query1_where]})")
                                  end
                                end
                               .group("Leftovers.Artikul, products.TovarnayaKategoriya")

      price_query = Price.joins(:product)
                         .select("Prices.Artikul as artikul, products.TovarnayaKategoriya as Tovar_Kategoriya,
                              #{@params_sklad[:array_query2_select]}")
                         # .where("(#{@params_sklad[:array_query2_where]})")
                          .tap do |query|
                            unless @params_sklad[:array_query2_where].blank? || contains_only_brackets?(@params_sklad[:array_query2_where])
                              query.where!("(#{@params_sklad[:array_query2_where]})")
                            end
                          end
                         .group("Prices.Artikul, products.TovarnayaKategoriya")

      @combined_results = Leftover.from("(#{leftover_query.to_sql} UNION #{price_query.to_sql}) AS leftovers_combined")
                                  .order("leftovers_combined.Tovar_Kategoriya, leftovers_combined.artikul")

    end

    def hash_grouped_name_collumns(hash_with_params)
      attr_query = ["artikul", "Tovar_Kategoriya"]
      attr_query_name_collumn = []

      hash_with_params[:array_name_product].each do |key, value|
        attr_query_name_collumn << "#{key}"
        attr_query << "#{key} as `#{key}`"
      end

      hash_with_params[:array_name_sum].each_with_index do |el, i|
        attr_query_name_collumn << "#{el}"
        attr_query << "SUM(Field_#{i}) as `#{el}`"
      end

      { attr_query_name_collumn: attr_query_name_collumn, attr_query: attr_query } # Возвращаем хеш напрямую

    end

  end

end
