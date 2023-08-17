Rails.application.routes.draw do
  get 'import', to: 'api#import_data_from_api'
  get 'test', to: 'api#test_send_emails'
  get 'send', to: 'api#send_emails'
  get 'report', to: 'api#report'
  get 'import_attr', to: 'api#import_attr'
  get 'import_data', to: 'api#import_data'
  get 'export_to_excel', to: 'export#export_to_excel'
  root 'readme#show'
end
