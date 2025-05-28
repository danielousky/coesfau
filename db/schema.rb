# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_05_27_232605) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "academic_processes", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "period_id", null: false
    t.integer "max_credits"
    t.integer "max_subjects"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "modality", default: 0, null: false
    t.bigint "process_before_id"
    t.string "name"
    t.float "registration_amount", default: 0.0
    t.index ["period_id"], name: "index_academic_processes_on_period_id"
    t.index ["process_before_id"], name: "index_academic_processes_on_process_before_id"
    t.index ["school_id"], name: "index_academic_processes_on_school_id"
  end

  create_table "academic_records", force: :cascade do |t|
    t.bigint "section_id", null: false
    t.bigint "enroll_academic_process_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.index ["enroll_academic_process_id"], name: "index_academic_records_on_enroll_academic_process_id"
    t.index ["section_id"], name: "index_academic_records_on_section_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.string "state"
    t.string "municipality"
    t.string "city"
    t.string "sector"
    t.string "street"
    t.integer "house_type"
    t.string "house_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_addresses_on_student_id"
  end

  create_table "admins", primary_key: "user_id", force: :cascade do |t|
    t.integer "role"
    t.string "env_authorizable_type", default: "Faculty"
    t.bigint "env_authorizable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "profile_id"
    t.index ["env_authorizable_type", "env_authorizable_id"], name: "index_admins_on_env_authorizable"
    t.index ["profile_id"], name: "index_admins_on_profile_id"
    t.index ["user_id"], name: "index_admins_on_user_id"
  end

  create_table "admission_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
  end

  create_table "area_authorizables", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "areas", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_area_id"
    t.index ["parent_area_id"], name: "index_areas_on_parent_area_id"
    t.index ["school_id"], name: "index_areas_on_school_id"
  end

  create_table "authorizables", force: :cascade do |t|
    t.bigint "area_authorizable_id", null: false
    t.string "klazz", null: false
    t.string "description"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_authorizable_id"], name: "index_authorizables_on_area_authorizable_id"
    t.index ["klazz", "area_authorizable_id"], name: "index_authorizables_on_klazz_and_area_authorizable_id", unique: true
  end

  create_table "authorizeds", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.bigint "authorizable_id", null: false
    t.boolean "can_create", default: false
    t.boolean "can_read", default: false
    t.boolean "can_update", default: false
    t.boolean "can_delete", default: false
    t.boolean "can_import", default: false
    t.boolean "can_export", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id", "authorizable_id"], name: "index_authorizeds_on_admin_id_and_authorizable_id", unique: true
    t.index ["admin_id"], name: "index_authorizeds_on_admin_id"
    t.index ["authorizable_id"], name: "index_authorizeds_on_authorizable_id"
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.string "code", null: false
    t.string "holder", null: false
    t.bigint "bank_id", null: false
    t.bigint "school_id", null: false
    t.integer "account_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_id"], name: "index_bank_accounts_on_bank_id"
    t.index ["school_id"], name: "index_bank_accounts_on_school_id"
  end

  create_table "banks", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "billboards", force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "courses", force: :cascade do |t|
    t.bigint "academic_process_id", null: false
    t.bigint "subject_id", null: false
    t.boolean "offer_as_pci"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["academic_process_id"], name: "index_courses_on_academic_process_id"
    t.index ["subject_id"], name: "index_courses_on_subject_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "enroll_academic_processes", force: :cascade do |t|
    t.bigint "grade_id", null: false
    t.bigint "academic_process_id", null: false
    t.integer "enroll_status"
    t.integer "permanence_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "efficiency", default: 1.0
    t.float "simple_average", default: 0.0
    t.float "weighted_average", default: 0.0
    t.index ["academic_process_id"], name: "index_enroll_academic_processes_on_academic_process_id"
    t.index ["grade_id"], name: "index_enroll_academic_processes_on_grade_id"
  end

  create_table "enrollment_days", force: :cascade do |t|
    t.bigint "academic_process_id", null: false
    t.datetime "start"
    t.integer "total_duration_hours", limit: 2
    t.integer "max_grades", limit: 2
    t.integer "slot_duration_minutes", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_process_id"], name: "index_enrollment_days_on_academic_process_id"
  end

  create_table "faculties", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "general_setups", force: :cascade do |t|
    t.string "clave"
    t.string "valor"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grades", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "study_plan_id", null: false
    t.integer "graduate_status"
    t.bigint "admission_type_id", null: false
    t.integer "registration_status"
    t.float "efficiency"
    t.float "weighted_average"
    t.float "simple_average"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "appointment_time"
    t.integer "duration_slot_time"
    t.integer "enrollment_status", default: 0, null: false
    t.bigint "enabled_enroll_process_id"
    t.integer "current_permanence_status", default: 0, null: false
    t.bigint "start_id"
    t.bigint "start_process_id"
    t.index ["admission_type_id"], name: "index_grades_on_admission_type_id"
    t.index ["enabled_enroll_process_id"], name: "index_grades_on_enabled_enroll_process_id"
    t.index ["start_id"], name: "index_grades_on_start_id"
    t.index ["start_process_id"], name: "index_grades_on_start_process_id"
    t.index ["student_id", "study_plan_id"], name: "index_grades_on_student_id_and_study_plan_id", unique: true
    t.index ["student_id"], name: "index_grades_on_student_id"
    t.index ["study_plan_id"], name: "index_grades_on_study_plan_id"
  end

  create_table "group_tutorials", force: :cascade do |t|
    t.string "name_group"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parent_areas", force: :cascade do |t|
    t.string "name"
    t.bigint "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_parent_areas_on_school_id"
  end

  create_table "payment_reports", force: :cascade do |t|
    t.float "amount"
    t.string "transaction_id"
    t.integer "transaction_type"
    t.date "transaction_date"
    t.bigint "origin_bank_id", null: false
    t.string "payable_type"
    t.bigint "payable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "receiving_bank_account_id"
    t.index ["origin_bank_id"], name: "index_payment_reports_on_origin_bank_id"
    t.index ["payable_type", "payable_id"], name: "index_payment_reports_on_payable"
    t.index ["receiving_bank_account_id"], name: "index_payment_reports_on_receiving_bank_account_id"
  end

  create_table "period_types", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "periods", force: :cascade do |t|
    t.integer "year", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "period_type_id"
    t.string "name"
    t.index ["period_type_id"], name: "index_periods_on_period_type_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "qualifications", force: :cascade do |t|
    t.bigint "academic_record_id", null: false
    t.integer "value", null: false
    t.integer "type_q", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "definitive", default: true, null: false
    t.index ["academic_record_id"], name: "index_qualifications_on_academic_record_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "section_id", null: false
    t.integer "day"
    t.time "starttime"
    t.time "endtime"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "index_schedules_on_section_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.integer "type_entity", default: 0, null: false
    t.boolean "enable_subject_retreat"
    t.boolean "enable_change_course"
    t.boolean "enable_dependents", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "faculty_id"
    t.string "contact_email", default: "coes.fau@gmail.com", null: false
    t.bigint "active_process_id"
    t.bigint "enroll_process_id"
    t.string "boss_name", default: ""
    t.boolean "enable_enroll_payment_report", default: false, null: false
    t.index ["active_process_id"], name: "index_schools_on_active_process_id"
    t.index ["enroll_process_id"], name: "index_schools_on_enroll_process_id"
    t.index ["faculty_id"], name: "index_schools_on_faculty_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "code"
    t.integer "capacity"
    t.bigint "course_id", null: false
    t.boolean "qualified", default: false, null: false
    t.integer "modality"
    t.boolean "enabled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "teacher_id"
    t.string "classroom"
    t.integer "location", default: 0, null: false
    t.integer "quedan", default: 0, null: false
    t.index ["code", "course_id"], name: "index_sections_on_code_and_course_id", unique: true
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["teacher_id"], name: "index_sections_on_teacher_id"
  end

  create_table "sections_teachers", id: false, force: :cascade do |t|
    t.bigint "section_id", null: false
    t.bigint "teacher_id", null: false
    t.index ["section_id", "teacher_id"], name: "index_sections_teachers_on_section_id_and_teacher_id", unique: true
  end

  create_table "students", primary_key: "user_id", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "disability"
    t.integer "nacionality"
    t.integer "marital_status"
    t.string "origin_country"
    t.string "origin_city"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "grade_title"
    t.string "grade_university"
    t.integer "graduate_year"
    t.integer "sede", default: 0, null: false
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "study_plans", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.bigint "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_credits", default: 0
    t.index ["school_id"], name: "index_study_plans_on_school_id"
  end

  create_table "subject_links", force: :cascade do |t|
    t.bigint "prelate_subject_id", null: false
    t.bigint "depend_subject_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["depend_subject_id"], name: "index_subject_links_on_depend_subject_id"
    t.index ["prelate_subject_id", "depend_subject_id"], name: "link_parent_depend", unique: true
    t.index ["prelate_subject_id"], name: "index_subject_links_on_prelate_subject_id"
  end

  create_table "subject_types", force: :cascade do |t|
    t.bigint "study_plan_id", null: false
    t.string "name"
    t.string "code"
    t.integer "required_credits", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["study_plan_id"], name: "index_subject_types_on_study_plan_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.boolean "active", default: true
    t.integer "unit_credits", default: 24, null: false
    t.integer "ordinal", default: 0, null: false
    t.integer "qualification_type"
    t.integer "modality"
    t.bigint "area_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "force_absolute", default: false
    t.index ["area_id"], name: "index_subjects_on_area_id"
  end

  create_table "teachers", primary_key: "user_id", force: :cascade do |t|
    t.bigint "area_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_teachers_on_area_id"
    t.index ["user_id"], name: "index_teachers_on_user_id"
  end

  create_table "tutorials", force: :cascade do |t|
    t.string "name_function"
    t.bigint "group_tutorial_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_tutorial_id"], name: "index_tutorials_on_group_tutorial_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "ci", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "number_phone"
    t.integer "sex"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "updated_password", default: false, null: false
    t.index ["ci"], name: "index_users_on_ci", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "academic_processes", "academic_processes", column: "process_before_id"
  add_foreign_key "academic_processes", "periods"
  add_foreign_key "academic_processes", "schools"
  add_foreign_key "academic_records", "enroll_academic_processes"
  add_foreign_key "academic_records", "sections"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "students", primary_key: "user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "admins", "users"
  add_foreign_key "areas", "schools"
  add_foreign_key "authorizables", "area_authorizables"
  add_foreign_key "authorizeds", "admins", primary_key: "user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "authorizeds", "authorizables", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bank_accounts", "banks"
  add_foreign_key "bank_accounts", "schools"
  add_foreign_key "courses", "academic_processes"
  add_foreign_key "courses", "subjects"
  add_foreign_key "enroll_academic_processes", "academic_processes"
  add_foreign_key "enroll_academic_processes", "grades"
  add_foreign_key "enrollment_days", "academic_processes"
  add_foreign_key "grades", "academic_processes", column: "enabled_enroll_process_id"
  add_foreign_key "grades", "academic_processes", column: "start_process_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "grades", "admission_types"
  add_foreign_key "grades", "students", primary_key: "user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "grades", "study_plans"
  add_foreign_key "parent_areas", "schools"
  add_foreign_key "payment_reports", "bank_accounts", column: "receiving_bank_account_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "payment_reports", "banks", column: "origin_bank_id"
  add_foreign_key "qualifications", "academic_records"
  add_foreign_key "schedules", "sections"
  add_foreign_key "schools", "academic_processes", column: "active_process_id"
  add_foreign_key "schools", "academic_processes", column: "enroll_process_id"
  add_foreign_key "sections", "courses"
  add_foreign_key "sections", "teachers", primary_key: "user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "sections_teachers", "sections"
  add_foreign_key "sections_teachers", "teachers", primary_key: "user_id"
  add_foreign_key "students", "users"
  add_foreign_key "study_plans", "schools"
  add_foreign_key "subject_links", "subjects", column: "depend_subject_id"
  add_foreign_key "subject_links", "subjects", column: "prelate_subject_id"
  add_foreign_key "subject_types", "study_plans"
  add_foreign_key "subjects", "areas"
  add_foreign_key "teachers", "areas"
  add_foreign_key "teachers", "users"
  add_foreign_key "tutorials", "group_tutorials"
end
