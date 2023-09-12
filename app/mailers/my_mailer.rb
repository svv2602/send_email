class MyMailer < ApplicationMailer
  after_action :email_delivered, only: :send_email_with_attachment

  default from: email_address_with_name('info@tot.biz.ua', 'ТОВ "Технооптторг - Трейд"')

  def send_email_with_attachment(email, file_path, osnovnoi_meneger, telefon_podrazdeleniia, telefon_menedzher)
    date = Date.today
    formatted_date = date.strftime('%d_%m_%Y')
    formatted_date_body = date.strftime('%d.%m.%Y')

    attachments["price#{formatted_date}.xls"] = File.read(file_path)
    unsubscribe_url = "https://www.tot.biz.ua/price?unsubscribe=#{email}"

    text_subject = "Асортиментний перелік товарів компанії ТЕХНООПТТОРГ станом на  #{formatted_date_body}"

    mail(to: email, subject: text_subject) do |format|
      format.html {
        render locals: { unsubscribe_url: unsubscribe_url,
                         formatted_date_body: formatted_date_body,
                         osnovnoi_meneger: osnovnoi_meneger,
                         telefon_podrazdeleniia: telefon_podrazdeleniia,
                         telefon_menedzher: telefon_menedzher}
      }
    end
  end

  private

  def email_delivered
    # Запись информации об успешной доставке письма в базу данных
    recipient = mail.to.first
    subject = mail.subject
    body = mail.body.raw_source

    Rails.logger.info("Email delivered successfully. Recipient: #{recipient}, Subject: #{subject}")

    Email.create(to: recipient, subject: subject, body: body, delivered: true)
    puts "Create record email"
  end
end
