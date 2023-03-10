Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  # match "/admin/:model_name/import" => "custom_admin#import" , :as => "import", :via => [:get, :post]
  
  match "/importer/entities" => "importer#entities" , :as => "importer_entities", :via => [:get, :post]
  match "/importer/students" => "importer#students" , :as => "importer_students", :via => [:get, :post]
  match "/importer/teachers" => "importer#teachers" , :as => "importer_teachers", :via => [:get, :post]
  match "/importer/subjects" => "importer#subjects" , :as => "importer_subjects", :via => [:get, :post]
  match "/importer/academic_records" => "importer#academic_records" , :as => "importer_academic_records", :via => [:get, :post]

  resources :page, only: :show
  resources :qualifications, only: :update
  resources :period_types
  resources :academic_processes, :enroll_academic_processes, :academic_records, :periods, :profiles, :sections, :courses

  resources :enrollment_days, only: [:create, :destroy]

  resources :users, only: [:edit, :update] do
    member do
      get 'edit_images'
    end

  end
  resources :students do
    collection do
      get :countries
    end

    resources :addresses do
      collection do
        get :getMunicipalities
        get :getCities
      end
    end
  end

  resources :banks do
    resources :payment_reports
  end
  
  resources :faculties do
    resources :schools do
      resources :admission_types, :grades, :study_plans
      resources :areas do
        resources :subjects
      end
    end
  end

    resources :downloader do
      member do
        get 'section_list'
      end
    end

  # devise_for :users
  devise_for :users, controllers: { sessions: 'sessions', passwords: 'passwords' }
  root to: "pages#home"
  get 'pages/multirols', to: 'pages#multirols'

  get 'teacher_session/dashboard', to: 'teacher_session#dashboard'
  get 'student_session/dashboard', to: 'student_session#dashboard'



  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
