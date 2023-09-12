# app/controllers/concerns/data_access_methods.rb
module DataAccessMethods
  extend ActiveSupport::Concern

  included do
    def bracket_replacement
      # удаление скобок - вызывают ошибку в запросах SQL (или заменить на экранирование)
      ActiveRecord::Base.connection.execute("UPDATE leftovers SET Sklad = REPLACE(Sklad, '(', '') WHERE Sklad LIKE '%(%'")
      ActiveRecord::Base.connection.execute("UPDATE leftovers SET Sklad = REPLACE(Sklad, ')', '') WHERE Sklad LIKE '%)%'")
    end

    def type_replacement
      # очистка типа партнеров, у которых отсутствует основной менеджер
      ActiveRecord::Base.connection.execute("UPDATE partners SET TipKontragentaILSh = '' WHERE OsnovnoiMeneger LIKE ''")
      ActiveRecord::Base.connection.execute("UPDATE partners SET TipKontragentaCMK = '' WHERE OsnovnoiMeneger LIKE ''")
      ActiveRecord::Base.connection.execute("UPDATE partners SET TipKontragentaSHOP = '' WHERE OsnovnoiMeneger LIKE ''")

    end

    def email_replacement
      # Получаем всех партнеров, у которых поле Email не пустое
      partners_with_email = Partner.where.not(Email: nil)

      # Обновляем поле Email для каждого партнера, оставляя только адреса
      partners_with_email.each do |partner|
        email = partner.Email.scan(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/).join(', ')
        partner.update(Email: email)
      end
    end

    def list_partners_to_send_email
      # В запросе дублируемые email объединяются в один 
      # типы прайсов дублируемых email объеденяются в один соответствующий массив
      sql_query = <<-SQL
SELECT partners_select.*,
       TipKontragentaILSh || ',' || TipKontragentaCMK || ',' || TipKontragentaSHOP || ',' || Podrazdelenie as params
FROM
    (SELECT Email                                     AS Email,
            Partner               AS Partner,
            OsnovnoiMeneger       AS OsnovnoiMeneger,
            TelefonPodrazdeleniia AS TelefonPodrazdeleniia,
            TelefonMenedzher      AS TelefonMenedzher,
            Gorod                 AS Gorod,
            Podrazdelenie         AS Podrazdelenie,
            GROUP_CONCAT(DISTINCT TipKontragentaILSh) AS TipKontragentaILSh,
            GROUP_CONCAT(DISTINCT TipKontragentaCMK)  AS TipKontragentaCMK,
            GROUP_CONCAT(DISTINCT TipKontragentaSHOP) AS TipKontragentaSHOP
     FROM partners
     where Email is not null
       and Email != ""
     GROUP BY Email
     HAVING COUNT(*) > 1
     union
     SELECT Email                 AS Email,
            Partner               AS Partner,
            OsnovnoiMeneger       AS OsnovnoiMeneger,
            TelefonPodrazdeleniia AS TelefonPodrazdeleniia,
            TelefonMenedzher      AS TelefonMenedzher,
            Gorod                 AS Gorod,
            Podrazdelenie         AS Podrazdelenie,
            TipKontragentaILSh,
            TipKontragentaCMK,
            TipKontragentaSHOP
     FROM partners
     where Email is not null
       and Email != ""
     GROUP BY Email
     HAVING COUNT(*) = 1) AS partners_select
         LEFT JOIN (
    SELECT emails.*
    FROM "emails"
    WHERE DATE("emails"."created_at") = DATE('now')
) as "emails_date" ON "emails_date"."to" = "partners_select"."Email"
WHERE "emails_date"."to" IS NULL AND "partners_select"."Email" != ""
ORDER BY params;
      SQL

      results = ActiveRecord::Base.connection.execute(sql_query)
    end


    def request_report(params_send)
      if params_send
        sql_query = <<-SQL
SELECT partners.*
FROM "partners"
         LEFT JOIN (
    SELECT emails.*
    FROM "emails"
    WHERE DATE("emails"."created_at") = DATE('now')
) as "emails_date" ON "emails_date"."to" = "partners"."Email"
WHERE "emails_date"."to" IS NULL AND "partners"."Email" != ""
ORDER BY Email;
        SQL
        deliveries = ActiveRecord::Base.connection.execute(sql_query)
      else
        deliveries = Email.where("DATE(emails.created_at) = DATE('now')")
      end

      deliveries
    end

    def report_out(deliveries, params_send)
      @msg_data_load = ""
      # Вывести email-адреса получателей
      deliveries.each_with_index do |delivery, i|
        ind = i < 5 ** 10 ? 5 - (i + 1).to_s.length.to_i : 1
        if params_send
          str = "#{" " * ind} #{delivery["Email"]};   #{delivery["Kontragent"]}"
        else
          str = "#{" " * ind} #{delivery.created_at }    #{delivery.to}; #{delivery.body}"
        end
        @msg_data_load_select = "#{i + 1}:  #{str}\n"
        @msg_data_load += @msg_data_load_select
        # puts @msg_data_load_select
      end
    end

  end

end