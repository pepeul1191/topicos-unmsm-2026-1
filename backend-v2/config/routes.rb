Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get 'sign-in', to: 'session#sign_in', as: :sign_in
  get 'reset-password', to: 'session#reset_password', as: :reset_password
  get 'sign-up', to: 'session#sign_up', as: :sign_up
  post 'sign-in', to: 'session#login', as: :login
  delete 'sign-out', to: 'session#sign_out', as: :sign_out_delete
  get 'sign-out', to: 'session#sign_out', as: :sign_out

  # car
  get 'cars', to: 'car#index'
  get 'cars/new', to: 'car#new'
  post 'cars', to: 'car#create'
  put 'cars/:id', to: 'car#update'
  get 'cars/:id/edit', to: 'car#edit'
  get 'cars/:id/delete', to: 'car#delete'
  get 'api/v1/cars/:plate', to: 'car#fetch_one'

  # technical_reviews
  get 'cars/:car_id/technical_reviews/new', to: 'technical_review#new'
  post 'cars/:car_id/technical_reviews', to: 'technical_review#create'
  get 'cars/:car_id/technical_reviews/:id/edit', to: 'technical_review#edit'
  put 'cars/:car_id/technical_reviews/:id', to: 'technical_review#update'
  get 'cars/:car_id/technical_reviews/:id/delete', to: 'technical_review#delete'

  # complains
  get 'cars/:car_id/complains/new',to: 'complain#new'
  post 'cars/:car_id/complains', to: 'complain#create'
  get 'cars/:car_id/complains/:id/edit', to: 'complain#edit'
  put 'cars/:car_id/complains/:id', to: 'complain#update'
  get 'cars/:car_id/complains/:id/delete', to: 'complain#delete'

  # infractions
  get 'cars/:car_id/infractions/new', to: 'infraction#new'
  post 'cars/:car_id/infractions', to: 'infraction#create'
  get 'cars/:car_id/infractions/:id/edit', to: 'infraction#edit'
  put 'cars/:car_id/infractions/:id', to: 'infraction#update'
  get 'cars/:car_id/infractions/:id/delete', to: 'infractions#delete'

  # etl executions
  get 'etl-executions', to: 'etl_execution#index'
  post 'etl-executions', to: 'etl_execution#run'

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "home#index"

  match '*unmatched', to: 'errors#not_found', via: :all
end
