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

  end
end