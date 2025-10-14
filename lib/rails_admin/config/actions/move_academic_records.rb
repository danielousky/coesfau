module RailsAdmin
  module Config
    module Actions
      class MoveAcademicRecords < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member do
          true
        end

        register_instance_option :http_methods do
          %i[get post]
        end

        register_instance_option :only do
          [Course, Section]
        end

        register_instance_option :link_icon do
          'fa-solid fa-right-left'
        end

        register_instance_option :controller do
          proc do
            if @object.is_a?(Course)
              @course = @object
              if request.get?
                @destination_courses = Course.where(subject_id: @course.subject_id).where.not(id: @course.id).order(:name)
                @mode = :course
                render action: @action.template_name
              elsif request.post?
                dest_id = params[:dest_course_id].presence
                create_missing = params[:create_missing_sections].to_s == '1'

                unless dest_id
                  flash[:error] = 'Debe seleccionar un curso destino.'
                  redirect_to back_or_index and return
                end

                dest = Course.find_by(id: dest_id)
                unless dest
                  flash[:error] = 'Curso destino no encontrado.'
                  redirect_to back_or_index and return
                end

                if dest.id == @course.id
                  flash[:error] = 'El curso destino no puede ser el mismo.'
                  redirect_to back_or_index and return
                end

                moved = 0
                skipped = 0
                created_sections = 0
                skipped_details = []

                ActiveRecord::Base.transaction do
                  @course.academic_records.includes(:section, :enroll_academic_process).find_each do |ar|
                    src_section = ar.section
                    target_section = dest.sections.where(code: src_section.code).first

                    if target_section.nil? && create_missing
                      target_section = dest.sections.build(
                        code: src_section.code,
                        capacity: src_section.capacity,
                        modality: src_section.modality,
                        qualified: src_section.qualified
                      )
                      if target_section.save
                        created_sections += 1
                      else
                        skipped += 1
                        skipped_details << "No se pudo crear sección #{src_section.code}: #{target_section.errors.full_messages.to_sentence}"
                        next
                      end
                    end

                    if target_section.nil?
                      skipped += 1
                      skipped_details << "Sin sección destino con código #{src_section.code}"
                      next
                    end

                    # Evitar duplicados por validación de unicidad
                    if target_section.academic_records.exists?(enroll_academic_process_id: ar.enroll_academic_process_id)
                      skipped += 1
                      skipped_details << "Duplicado en sección #{target_section.code} para estudiante #{ar.enroll_academic_process_id}"
                      next
                    end

                    unless ar.update_attribute(:section, target_section)
                      skipped += 1
                      skipped_details << "Error moviendo AR##{ar.id} a sección #{target_section.code} (sin validación): #{ar.errors.full_messages.to_sentence}"
                      next
                    end

                    # Lógica para eliminar secciones y curso si quedan vacíos
                    if params[:delete_sections].to_s == '1'
                      src_section.destroy if src_section.academic_records.empty?
                      @course.destroy if @course.academic_records.empty?
                    end

                    moved += 1
                  end
                end

                flash[:success] = "Se movieron #{moved} registros académicos. Se omitieron #{skipped} registros: #{skipped_details.join(', ')}."
                redirect_to back_or_index
              end
            elsif @object.is_a?(Section)
              @section = @object
              if request.get?
                @destination_sections = Section.where(course_id: @section.course_id).where.not(id: @section.id).order(:code)
                @mode = :section
                render action: @action.template_name
              elsif request.post?
                dest_id = params[:dest_section_id].presence

                unless dest_id
                  flash[:error] = 'Debe seleccionar una sección destino.'
                  redirect_to back_or_index and return
                end

                dest = Section.find_by(id: dest_id)
                unless dest
                  flash[:error] = 'Sección destino no encontrada.'
                  redirect_to back_or_index and return
                end

                if dest.id == @section.id
                  flash[:error] = 'La sección destino no puede ser la misma.'
                  redirect_to back_or_index and return
                end

                moved = 0
                skipped = 0
                skipped_details = []

                ActiveRecord::Base.transaction do
                  @section.academic_records.includes(:enroll_academic_process).find_each do |ar|
                    # Evitar duplicados por validación de unicidad
                    if dest.academic_records.exists?(enroll_academic_process_id: ar.enroll_academic_process_id)
                      skipped += 1
                      skipped_details << "Duplicado en sección #{dest.code} para estudiante #{ar.enroll_academic_process_id}"
                      next
                    end

                    unless ar.update_attribute(:section, dest)
                      skipped += 1
                      skipped_details << "Error moviendo AR##{ar.id} a sección #{dest.code} (sin validación): #{ar.errors.full_messages.to_sentence}"
                      next
                    end

                    # Lógica para eliminar sección si queda vacía
                    if params[:delete_sections].to_s == '1'
                      @section.destroy if @section.academic_records.empty?
                    end

                    moved += 1
                  end
                end

                flash[:success] = "Se movieron #{moved} registros académicos. Se omitieron #{skipped} registros: #{skipped_details.join(', ')}."
                redirect_to back_or_index
              end
            end
          end
        end
      end
    end
  end
end
