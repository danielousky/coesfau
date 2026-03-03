module SubjectLinksHelper
	def render_haml(haml, locals = {})
		Haml::Engine.new(haml.strip_heredoc).render(locals)
	end

	def badge_order_subject(asignatura)

		capture_haml do
			if asignatura.ordinal.eql? 0
				aux = asignatura.modality ? asignatura.modality.titleize : 0
			else
				aux = asignatura.ordinal
			end
			"<span class='badge bg-info tooltip-btn' rel='tooltip' data-bs-toggle='tooltip' data-bs-placement='top' data-bs-original-title='Orden'>#{aux}</span>".html_safe
		end
	end


	def description_subject_tree(dep, adelante, admin)

		capture_haml do
			
			aux = btn_delete_depend(dep).html_safe if (admin&.authorized_delete? 'Subject')
			asig = adelante ? dep.depend_subject : dep.prelate_subject

			aux2 = simple_toggle "/admin/subject/#{asig.id}", "| #{asig.desc}", "Ir al detalle de " + asig.desc, 'primary', nil
			"#{badge_order_subject(asig)} #{aux} #{aux2}".html_safe
		end
	end

	def btn_delete_depend(dep)
		link_to "/subject_links/#{dep.id}.json", class: "tooltip-btn text-danger", rel: :tooltip, 'data-bs-toggle': :tooltip, 'data-bs-placement': :top, 'data-bs-original-title': 'Eliminar prelación', method: :delete, onclick: "$('#dep#{dep.id}').remove();" do
			capture_haml{"<i class='fa fa-trash'></i>".html_safe}
		end
	end

end
