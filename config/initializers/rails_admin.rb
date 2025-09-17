require 'same_period_validator'

Dir[Rails.root.join('app', 'rails_admin', '**/*.rb')].each { |file| require file }

# RailsAdmin::Config::Actions.register(:custom_export, RailsAdmin::Config::Actions::CustomExport)

RailsAdmin.config do |config|
  config.asset_source = :webpack

  ### Popular gems integration
  config.main_app_name = Proc.new { |controller| [ "Coes", "FAU" ] }

  ## == Devise ==
  config.authenticate_with do
    begin
      warden.authenticate! scope: :user
    rescue Exception => e
      reset_session
      flash[:danger] = "Por favor inicie sesión antes de continuar" 
      redirect_to '/users/sign_in'
    end
  end

  config.current_user_method(&:current_user)

  ## == CancanCan ==
  config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  config.show_gravatar = false

  config.label_methods << :description # Default is [:name, :title]

  # NO FUNCIONA
  # config.show_gravatar do |config|
  #   config.gravatar_url do
  #     main_app.url_for(current_user.profile_picture_as_thumbs)
  #   end
  # end

  # IMPORTER:

  config.configure_with(:import) do |config|
    config.logging = false
    config.line_item_limit = 3000
    config.update_if_exists = true
    config.rollback_on_error = false
  end

  # config.navigation_static_links = {
  #   'Cambiar Período' => 'http://www.google.com'
  # }
  # config.navigation_static_label = "Opciones"

  config.actions do
    dashboard do                     # mandatory
      # require_relative '../../lib/rails_admin/config/actions/dashboard'
      show_in_menu false
      show_in_navigation false
      visible false
    end

    index do                         # mandatory

      require_relative '../../lib/rails_admin/config/actions/index'
      except [SectionTeacher, Profile, Address, EnrollmentDay, Qualification, SubjectLink]
      # except [Address, SectionTeacher, Profile, User, StudyPlan, Period, Course, Faculty]

    end

    member :programation do 
      # subclass Base. Accessible at /admin/<model_name>/<id>/my_member_action
      only [AcademicProcess]
      # i18n_key :edit # will have the same menu/title labels as the Edit action.
      link_icon do
          'fa-solid fa-shapes'
      end
    end

    member :organization_chart do 

      only [School]
      link_icon do
          'fa-solid fa-shapes'
      end
    end

    member :enrollment_day do 

      only [AcademicProcess]
      link_icon do
          'fa-solid fa-bell'
      end
    end

    member :personal_data do 
      only [Student]
      link_icon do
          'fa-solid fa-id-card'
      end
    end

    new do
      except [School, Faculty, EnrollAcademicProcess, Course]
    end

    export do
      require_relative '../../lib/rails_admin/config/actions/export'
      except [Faculty, School, StudyPlan, GroupTutorial, Tutorial, ParentArea]
    end

    bulk_delete do
      only [AcademicRecord, Section]
    end

    show do
      except [StudyPlan, AcademicRecord]
    end

    edit do
      except [EnrollAcademicProcess, Course]
    end

    delete do
      except [School, StudyPlan, Faculty, EnrollAcademicProcess, Course]
    end

    import do
      only [Student, Teacher, Subject, Section, AcademicRecord]
    end
    # show_in_app

    ## With an audit adapter, you can add:
    history_index do
      only []
    end

    history_show do
      except [School, StudyPlan, ParentArea]
    end
  end

  # config.model Section do
  #   field :course do
  #     # visible false
  #     associated_collection_cache_all false  # REQUIRED if you want to SORT the list as below
  #     associated_collection_scope do
  #       # bindings[:object] & bindings[:controller] are available, but not in scope's block!
  #       # team = bindings[:object]
  #       Proc.new { |scope|
  #         # scoping all Players currently, let's limit them to the team's league
  #         # Be sure to limit if there are a lot of Players and order them by position
  #         scope = scope.joins(:course)
  #         scope = scope.limit(30) # 'order' does not work here
  #       }
  #     end
  #   end
  # end



  config.model "ActionText::EncryptedRichText" do
    visible false
  end

  config.model "ActionText::RichText" do
    visible false
  end  

  # config.model 'User' do
  #   configure :preview do
  #     children_fields [:name, :last_name, :email, :ci]
  #   end
  # end

  config.model "ActiveStorage::Blob" do
    visible false
  end
  config.model "ActiveStorage::Attachment" do
    visible false
  end
  config.model "ActiveStorage::VariantRecord" do
    visible false
  end

  config.parent_controller = 'EnhancedController'
end
