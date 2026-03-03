module ImporterHelper
  def render_haml(haml, locals = {})
    Haml::Engine.new(haml.strip_heredoc, format: :html5).render(self, locals)
  end

  def importer_csv_instructions

    render_haml <<-HAML
      .text-center
        = image_tag image_url('example_csv_import_students.png')
        %p 
          .float-right.text-success.ml-2 #campos opcionales
          .float-right.text-danger.ml-2 #campos obligatorios
          .float-right.text-info.ml-2 #nombres de la cabecera
        %br

    HAML
  end

  def descripcion_arbol(dep, adelante)

    render_haml <<-HAML, dep: dep, adelante: adelante
      - if (current_admin and current_admin.autorizado? 'Dependencias', 'destroy')
        = btn_eliminar_prelacion(dep)
      - asig = adelante ? dep.asignatura_dependiente : dep.asignatura

      = simple_toggle asignatura_path(asig) + "?dependencias=true", nil, "Ir al detalle de " + asig.descripcion, :primary, 'zoom-in'

      = badge_orden_asignatura(asig)
      |
      = asig.descripcion_id

    HAML
  end



  def btn_eliminar_prelacion(dep)

    link_to dependencia_path(dep), class: "tooltip-btn text-danger", rel: :tooltip, 'data-bs-toggle': :tooltip, 'data-bs-placement': :top, 'data-bs-original-title': 'Eliminar prelación', method: :delete do
      capture_haml{glyph :trash}
    end
  end
end
