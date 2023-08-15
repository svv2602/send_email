Rails.application.routes.draw do
  get 'import_data', to: 'api#import_data_from_api'
  get 'test', to: 'api#test_send_emails'
  get 'send', to: 'api#send_emails_to_partners'
  get 'report', to: 'api#report'
  get 'attr', to: 'api#attr_price'
  root 'readme#show'
end
