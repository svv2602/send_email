class MyMailer < ApplicationMailer
  after_action :email_delivered, only: :send_email_with_attachment

  default from: email_address_with_name('info@tot.biz.ua', 'ТОВ "Технооптторг - Трейд"')

  def send_email_with_attachment(email, file_path)
    date = Date.today
    formatted_date = date.strftime('%d_%m_%Y')

    attachments["price#{formatted_date}.xls"] = File.read(file_path)
    unsubscribe_url = "https://www.tot.biz.ua/price?unsubscribe=#{email}"

    mail(to: email, subject: "price #{formatted_date}") do |format|
      format.html {
        render locals: { unsubscribe_url: unsubscribe_url }
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
