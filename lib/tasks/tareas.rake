desc "Actualiza todas inscripciones segun el reglamento"
task :update_all_enrollment_status => :environment do
	begin
		p 'iniciando... '
		AcademicProcess.reorder(name: :asc).each do |ap|
			p "Periodo: #{ap.period_name}"
			ap.enroll_academic_processes.each do |eap| 
				if eap.finished?
					print eap.update(permanence_status: eap.get_regulation) ? '.' : 'x'

				else
					print "-#{eap.id}-"
				end
			end
			p "/"
    	end

	rescue StandardError => e
		p e
	end
	
end

desc "Actualiza los numeritos de las inscripciones"
task :update_enroll_academic_processes_numbers => :environment do
	begin
		p 'iniciando... '
		AcademicProcess.reorder(name: :asc).each do |ap|
			p "Periodo: #{ap.period_name}"
			ap.enroll_academic_processes.each do |eap| 


				print eap.update(efficiency: eap.calculate_efficiency, simple_average: eap.calculate_average, weighted_average: eap.calculate_weighted_average) ? '.' : "x#{eap.id}"
			end
			p "/"
		end

	rescue StandardError => e
		p e
	end
	
end


  def update_all_efficiency

    Grados.each do |gr| 
      academic_records = gr.academic_records
      cursados = academic_records.total_credits_coursed
      aprobados = academic_records.total_credits_approved

      eficiencia = (cursados and cursados > 0) ? (aprobados.to_f/cursados.to_f).round(4) : 0.0

      aux = academic_records.coursed

      promedio_simple = aux ? aux.round(4) : 0.0

      aux = academic_records.weighted_average
      ponderado = (cursados > 0) ? (aux.to_f/cursados.to_f).round(4) : 0.0
    end

  end

desc "Actualiza el start_process_id de todos los grados con su primer enroll_academic_process"
task :update_grades_start_process => :environment do
  begin
    puts "Actualizando start_process_id de #{Grade.where(start_process_id: nil).count} los grados..."
    Grade.where(start_process_id: nil).find_each do |grade|
      first = grade.first_enrolled
      if first
		first.update_column(:permanence_status, EnrollAcademicProcess.permanence_statuses[:nuevo])
        grade.update_column(:start_process_id, first.academic_process_id)
        print '.'
      else
        print 'x'
      end
    end
    puts "\nActualización completada de #{Grade.where(start_process_id: nil).count} grados sin start_process_id."
  rescue StandardError => e
    puts e
  end
end

desc "Actualiza permanence_status a :nuevo para el primer enroll_academic_process de cada grado"
task :set_first_enroll_permanence_to_nuevo => :environment do
  begin
    puts 'Actualizando permanence_status a :nuevo para los primeros enroll_academic_process de cada grado...'
    EnrollAcademicProcess.find_each do |eap|
      if eap.is_the_first_enroll_of_grade?
        eap.update_column(:permanence_status, EnrollAcademicProcess.permanence_statuses[:nuevo])
        print '.'
      end
    end
    puts "\nActualización completada."
  rescue StandardError => e
    puts e
  end
end
