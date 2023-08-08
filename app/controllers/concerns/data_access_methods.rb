# app/controllers/concerns/data_access_methods.rb
module DataAccessMethods
  extend ActiveSupport::Concern

  included do
    def bracket_replacement
      ActiveRecord::Base.connection.execute("UPDATE leftovers SET Sklad = REPLACE(Sklad, '(', '') WHERE Sklad LIKE '%(%'")
      ActiveRecord::Base.connection.execute("UPDATE leftovers SET Sklad = REPLACE(Sklad, ')', '') WHERE Sklad LIKE '%)%'")
    end

    def type_replacement
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
      sql_query = <<-SQL
    SELECT partners.*,
           TipKontragentaILSh || ',' || TipKontragentaCMK || ',' || TipKontragentaSHOP || ',' || Podrazdelenie as params
    FROM "partners"
    LEFT JOIN (
      SELECT emails.*
      FROM "emails"
      WHERE DATE("emails"."created_at") = DATE('now')
    ) as "emails_date" ON "emails_date"."to" = "partners"."Email"
    WHERE "emails_date"."to" IS NULL AND "partners"."Email" != ""
    ORDER BY params;
      SQL

      results = ActiveRecord::Base.connection.execute(sql_query)

    end

    def list_partners_to_send_email?
      list_partners_to_send_email.any?
    end

  end
end