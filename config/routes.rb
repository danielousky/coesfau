Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  # match "/admin/:model_name/import" => "custom_admin#import" , :as => "import", :via => [:get, :post]
  
  match "/importer/entities" => "importer#entities" , :as => "importer_entities", :via => [:get, :post]
  match "/importer/students" => "importer#students" , :as => "importer_students", :via => [:get, :post]
  match "/importer/teachers" => "importer#teachers" , :as => "importer_teachers", :via => [:get, :post]
  match "/importer/subjects" => "importer#subjects" , :as => "importer_subjects", :via => [:get, :post]
  match "/importer/academic_records" => "importer#academic_records" , :as => "importer_academic_records", :via => [:get, :post]

  match "/export_csv/academic_records/:id" => "export_csv#academic_records", via: :get
  match "/export_csv/enroll_academic_processes/:id" => "export_csv#enroll_academic_processes", via: :get
  match "/export/xls/:id" => "export#xls", via: :get
  match "/session_admin/change_period_session" => "session_admin#change_period_session", via: :post
  match "/admin/course/:id/move_academic_records_progress" => "rails_admin/main#move_academic_records", via: :get, as: :move_academic_records_progress

  resources :validar, only: :index do
    member do
      get 'constancias'
    end
  end
  resources :subject_links, only: :destroy
  resources :page, only: :show
  resources :qualifications, only: :update
  resources :period_types
  resources :academic_records, :periods, :profiles, :sections, :courses
  
  resources :sections do
    member do
      get :export
    end
    collection do
      post :bulk_delete
    end

  end

  resources :enroll_academic_processes do
    member do
      put :total_retire
      post :update_permanece_status
    end
    collection do
      post :reserve_space
      post :enroll
    end
  end

  resources :authorizeds do
    collection do
      post :update_authorize
    end

  end

  resources :enrollment_days, only: [:create, :destroy] do
    member do
      get 'destroy_all'
      get 'export'
    end 
  end

  resources :academic_processes do
    member do
      get 'massive_confirmation'
      get 'clean_courses'
      get 'run_regulation'
    end
    collection do
      post :change_process_session
      post 'clone_sections'
    end
  end

  devise_for :users, controllers: { sessions: 'sessions', passwords: 'passwords' }

  resources :users, only: [:edit, :update] do
    member do
      get :edit_images
      get :edit_password
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
  resources :payment_reports
  resources :schools, only: [:update] do
    member do
      get 'export_grades'
      get 'export_grades_stream'
    end
  end
  resources :subjects, only: [:show]
  resources :faculties do
    resources :schools do
      resources :admission_types, :study_plans
      resources :areas do
        resources :subjects
      end
    end
  end

  resources :grades do
    member do
      get 'kardex'
    end
  end

  resources :downloader do
    member do
      get 'section_list'
    end
  end


  root to: "pages#home"
  get 'pages/multirols', to: 'pages#multirols'

  get 'teacher_session/dashboard', to: 'teacher_session#dashboard'
  get 'student_session/dashboard', to: 'student_session#dashboard'



  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
