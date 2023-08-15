Rails.application.routes.draw do
  get 'import_data', to: 'api#import_data_from_api'
  get 'send', to: 'api#send_emails_to_partners'
  get 'report', to: 'api#report'
  get 'attr', to: 'api#attr_price'
  root 'readme#show'
end
