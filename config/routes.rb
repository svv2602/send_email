Rails.application.routes.draw do
  get 'import_data', to: 'api#import_data_from_api'
  get 'xls', to: 'api#create_xls'
  get 'send_email', to: 'api#send_email'
  get 'report', to: 'api#report'
  get 'grup', to: 'api#grup_partner'
  get 'attr', to: 'api#params_price_partner'
  root 'readme#show'
end
