# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)

    alias_action :create, :read, :update, :export, to: :crue
    alias_action :read, :update, to: :ru
    alias_action :create, :read, to: :cr
    alias_action :create, :update, to: :cu
    alias_action :create, :update, :export, to: :cue

    user ||= User.new

    if user.admin?
      can :access, :rails_admin
      can :manage, :dashboard
      can :read, [Faculty, Tutorial]

      if user.admin.desarrollador?
        can :manage, :all

      elsif user.admin.jefe_control_estudio?
        can :import, Authorizable::IMPORTABLES
        can :manage, [Admin, Student, Teacher, Area, ParentArea, Subject, Course, Grade, AcademicProcess, AcademicRecord, Section, AdmissionType, PeriodType, Address, StudyPlan, Period, SubjectLink, Schedule, EnrollmentDay, Billboard, User, EnrollAcademicProcess, PaymentReport, Bank, BankAccount]
        can :ru, [School]
        can :organization_chart, [School] 
      else
        can :manage, [User]
        user.admin.authorizeds.each do |authd|
            if authd.authorizable.klazz.eql? 'Subject' and authd.can_manage?
                can :manage, [SubjectLink, Area, ParentArea]
            end
            if authd.authorizable.klazz.eql? 'Student' and authd.can_manage?
                can :manage, [Address, Grade]
                can :read, [AdmissionType, StudyPlan]
            end
            if authd.authorizable.klazz.eql? 'AcademicProcess' and authd.can_read?
                can :programation, [AcademicProcess]
                can :enrollment_day, [AcademicProcess]
            end
            if authd.authorizable.klazz.eql? 'School' and authd.can_read?
               can :organization_chart, [School] 
            end
            if authd.authorizable.klazz.eql? 'School' and authd.can_manage?
               can :manage, [Bank, BankAccount] 
            end
            if authd.authorizable.klazz.eql? 'AcademicProcess' and authd.can_manage?
                can :manage, [Period, PeriodType]
            end
            if authd.authorizable.klazz.eql? 'Section' and authd.can_manage?
                can :manage, [Schedule]
            end
            if authd.authorizable.klazz.eql? 'AcademicRecord' and authd.can_manage?
                can :read, [Section, EnrollAcademicProcess]
            end            

            can :read, authd.authorizable_klazz_constantenize if authd.can_read?
            can :create, authd.authorizable_klazz_constantenize if authd.can_create?
            can :update, authd.authorizable_klazz_constantenize if authd.can_update?
            can :destroy, authd.authorizable_klazz_constantenize if authd.can_delete?
            can :import, authd.authorizable_klazz_constantenize if authd.can_import?
            can :export, authd.authorizable_klazz_constantenize if authd.can_export?
            # can :history, authd.authorizable_klazz_constantenize

        end


        # cannot :manage, [User, Admin, Student, Teacher, Area, Subject, School, Bank, BankAccount, PaymentReport, Course, Grade, AcademicProcess, EnrollAcademicProcess, AcademicRecord, Section, AdmissionType, PeriodType, Address]
      end
    end
  end
end
