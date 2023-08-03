class MyMailer < ApplicationMailer
  def send_email_with_attachment(email, file_path)
    date = Date.today
    formatted_date = date.strftime('%d_%m_%Y')
    attachments["price#{formatted_date}.xls"] = File.read(file_path)
    mail(to: email, subject: "price #{formatted_date}")
  end
end
