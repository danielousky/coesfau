module ApplicationHelper
	def render_haml(haml, locals = {})
		Haml::Engine.new(haml.strip_heredoc, format: :html5).render(locals)
	end

	def to_bs value
		ActionController::Base.helpers.number_to_currency(value, unit: 'Bs.', separator: ",", delimiter: ".")
	end

	def btn_toggle type, icon, href, title_tooltip, value, onclick_action=nil

		target = ''
		rel = ''

		if (icon.include? 'fa-download')
			target = '_blank'
			rel = 'noopener noreferrer'
		end
		link_to href, class: "btn btn-sm #{type}", title: title_tooltip, onclick: onclick_action, target: target, rel: rel do
			capture_haml{"<i class= '#{icon}'></i> #{value}".html_safe}
		end
	end

	def btn_toggle_download classes, href, title_tooltip, value, onclick_action=nil
		btn_toggle classes, 'fa fa-download', href, title_tooltip, value, onclick_action
	end

	def label_status(klazz, content)
		text_color = ((klazz.eql? 'bg-info') or (klazz.eql? 'bg-success') or (klazz.eql? 'bg-warning')) ? 'text-dark' : ''
		capture_haml{"<span class='text-center badge #{klazz} #{text_color}'>#{content}</span>".html_safe }
	end


	def button_add_section course_id

		content_tag :button, rel: :tooltip, 'data-bs-target': "#NewSectionModal", 'data-bs-placement': :top, 'data-bs-original-title': 'Agregar Nueva Sección', class: "btn btn-sm btn-success mx-1 addSection", "data-bs-toggle": :modal, course_id: course_id, onclick: "$('#_sectioncourse_id').val(this.attributes['course_id'].value);" do
			capture_haml{"<i class='fas fa-plus'></i>".html_safe }
		end
		
	end

	def total_sections_stiky total
		sticky_label 0, 0, 'bg-success', 'text-dark', 'Total Secciones', total
	end

	def sticky_label top, right, bg_color, text_color, title, content
		content_tag :div, title: title, class: "btn btn-sm #{bg_color} #{ text_color}", style: "top: #{top}px; right: #{right};font-size: xx-small;" do
			capture_haml{"#{content}".html_safe }
		end	
	end

	def label_link_with_tooptip(href, klazz, content, title, placement='top')
		klazz += ' text-dark' if (klazz.include? 'bg-info' or klazz.include? 'bg-success' or klazz.include? 'bg-warning')
		content_tag :a, href: href, rel: :tooltip, 'data-bs-toggle': :tooltip, 'data-bs-placement': placement, 'data-bs-original-title': title do
			capture_haml{"<span class='text-center badge #{klazz}'>#{content}</span>".html_safe }
		end	
	end	

	def btn_link_with_tooptip(href, klazz, content, title, placement='top')

		content_tag :a, href: href, rel: :tooltip, 'data-bs-toggle': :tooltip, 'data-bs-placement': placement, 'data-bs-original-title': title, class: "btn btn-sm #{klazz}" do
			capture_haml{"<span class='text-center'>#{content}</span>".html_safe }
		end	
	end	

	def label_status_with_tooptip(klazz, content, title, placement='top')
		text_color = ((klazz.eql? 'bg-info') or (klazz.eql? 'bg-success') or (klazz.eql? 'bg-warning')) ? 'text-dark' : ''

		content_tag :b, rel: :tooltip, 'data-bs-toggle': 'tooltip', 'data-bs-placement': placement, 'data-bs-original-title': title do
			capture_haml{"<span class='text-center badge #{klazz} #{text_color}'>#{content}</span>".html_safe }
		end	
	end

	def translate_model model
		I18n.t("activerecord.models.#{model}.other")
	end

	def checkbox_auth id, action, value, area_id, onclick=nil

		content_tag :a do
			check_box_tag "[model#{id}][can_#{action}]", nil, value, {class: "area#{area_id} can_all#{id} read#{id}", onclick: onclick}
		end
	end

	def simple_toggle href, value, title_tooltip, color_type, icon, onclick_action = nil
		target = (href.include? 'descargar') ? '_blank' : ''
		link_to href, class: "tooltip-btn text-#{color_type}", onclick: onclick_action, target: target, 'data_toggle': :tooltip, title: title_tooltip do
			capture_haml{"<i class= '#{icon}'></i> #{value}".html_safe}
		end

	end

	def signatures

		capture_haml {
			".signatures
				.font-title.text-center FACULTAD
					%table.no_border
						%thead
							%tr
							%th.text-center{style: 'width: 500px'} JURADO EXAMINADOR
							%th.text-center{style: 'width: 500px'} SECRETARÍA
					%br
					%table.no_border
						%thead
							%tr
								%th APELLIDOS Y NOMBRES
								%th FIRMAS
								%th 
							%tr{style: 'height:30px'}
								%th _________________________________
								%th ______________________
								%th NOMBRE ______________________        
							%tr{style: 'height:30px'}
								%th _________________________________
								%th ______________________
								%th FIRMA _______________________
							%tr{style: 'height:30px'}
								%th _________________________________
								%th ______________________
								%th FECHA _______________________"
		}

	end	

end
