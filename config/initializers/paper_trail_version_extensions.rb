# Extensiones para PaperTrail::Version accesibles en toda la app
# Evita depender de una subclase específica cuando el código utiliza PaperTrail::Version directamente

module PaperTrailVersionExtensions

  # Hash con cambios ya parseados desde object_changes (compat con versiones antiguas)
  def formatted_object_change
    return {} unless object_changes.present?
    permitted = [Time, Date, Symbol]
    begin
      YAML.safe_load(object_changes, permitted_classes: permitted + [ActiveSupport::TimeWithZone, ActiveSupport::Duration, BigDecimal], aliases: true).reject { |k, _| %w[updated_at created_at].include?(k) }
    rescue NameError, ArgumentError
      YAML.safe_load(object_changes, permitted_classes: permitted).reject { |k, _| %w[updated_at created_at].include?(k) }
    end || {}
  end

  # Traduce atributos usando I18n, con fallback a humanize
  def translate_attr(field)
    I18n.t("activerecord.attributes.#{model_i18n_key}.#{field}", default: field.to_s.humanize)
  end

  # Clave de I18n para el modelo de la versión
  def model_i18n_key
    item_type.to_s.underscore
  end

  # Ícono FontAwesome sugerido para esta versión
  # object: el registro actual para comparar contra version.whodunnit (opcional)
  def fa_icon(object = nil)
    color = if whodunnit.present? && object && (whodunnit.to_s != object&.id.to_s)
      ' text-success'
    else
      ' text-info'
    end
    if event&.include?('destroy')
      'fa fa-trash text-danger'
    elsif event&.include?('registra')
      'fa fa-plus text-success'
    elsif event&.include?('generó')
      'fa fa-download' + color
    elsif object_changes&.include?('last_sign_in_at')
      'fa fa-user' + color
    elsif ['¡Completada inscripción en oferta académica!', '¡Expediente Registrado con Éxito!'].include?(event) or event.include?('registrad')
      'fa fa-check' + color
    else
      'fa fa-info-circle' + color
    end

  end

  # Descripción unificada de cambios/evento para esta versión
  # Devuelve texto plano con saltos HTML si está disponible html_safe en el entorno
  def version_desc
    # Caso especial de sesiones de usuario
    if event == 'destroy'
        
        # Buscar el EnrollAcademicProcess y la sección por sus IDs si existen
        name_values = []
        begin
            data = formatted_object_change

            data.each do |key, values|
                if key.end_with?('_id')
                    class_name = key.sub(/_id$/, '').camelize
                    begin
                        klass = class_name.constantize
                        class_name_translated = I18n.t("activerecord.models.#{klass.model_name.i18n_key}.one", default: class_name)
                        obj = klass.find_by(id: values.first)
                        name_values << (obj&.respond_to?(:name) ? obj.name : "#{class_name_translated}: Desconocido")
                    rescue NameError
                        name_values << "#{class_name}: #{values.first}"
                    end
                end
            end
            return name_values.join('<br/> ').presence || "Eliminado: #{item_type} ##{item_id}"

        rescue Exception => e
            p "Error al parsear object_changes: #{e.message}"
            # Si falla el parseo, se mantienen los valores por defecto
            return "Eliminado: #{item_type} ##{item_id}"
        end
        
    end

    if item_type.to_s == 'User'
      if object_changes&.include?('last_sign_in_at')
        return 'Inició sesión'
      end
      changes = formatted_object_change
      unless changes.empty?
        if changes.key?('encrypted_password') && changes.size < 3
          return 'Reseteo de Contraseña'
        end
        parts = changes.map { |field, values| describe_change_line(field, Array(values)) }
        joined = parts.join('</br> ')
        return joined.respond_to?(:html_safe) ? joined.html_safe : joined
      end
    end

    # Genérico para otros modelos
    if object_changes.present?
      changes = formatted_object_change
      unless changes.empty?
        parts = changes.map { |field, values| describe_change_line(field, Array(values)) }
        joined = parts.join('</br> ')
        return joined.respond_to?(:html_safe) ? joined.html_safe : joined
      end
    end

    # Fallback al evento
    event
  end

  private

  # Construye una línea descriptiva para un cambio de atributo
  def describe_change_line(field, values)
    prev, curr = values
    if [true, false].include?(prev) && [true, false].include?(curr)
      return "#{translate_attr(field)}: #{boolean_transition_label(field, prev, curr)}"
    else
      # Intentar resolver nombres si el field corresponde a una clase y prev/curr son IDs
      begin
        klass = field.to_s.safe_constantize || field.to_s.sub(/_id$/, '').camelize.safe_constantize
        if klass
          translate_klass = I18n.t("activerecord.models.#{klass.model_name.i18n_key}.one", default: klass.name)
          prev_name = resolve_name_from_id(klass, prev)
          curr_name = resolve_name_from_id(klass, curr)
          # Solo si ambos se pueden resolver a nombre usamos la versión "bonita"; si no, fallback

          if prev_name && curr_name
            return "Cambio de #{translate_klass}:</br><b>de:</b></br> #{prev_name} </br><b>a:</b></br> #{curr_name}".html_safe
          elsif curr_name && prev_name.blank? 
            
            if obj = klass.where(id: curr).first
              if obj.is_a?(EnrollAcademicProcess)
                return "<b>#{translate_klass} #{obj&.academic_process&.period_name} </b>".html_safe
              elsif obj.is_a?(Section)
                return "Selección de #{translate_klass} <b><a href='/admin/section/#{obj&.id}'>#{obj&.code}</a></b> </br><b style='font-size: small;color:darkcyan;'>#{obj.subject&.desc}</b>".html_safe
              else
                return "<b>#{translate_klass}</b>:<br/> #{curr_name}".html_safe
              end
            else
              return "Objeto no encontrado: </b>#{translate_klass}: #{curr_name} </b>. Pudo ser eliminado".html_safe
            end
          end
        end
      rescue => _e
        # En caso de cualquier error, mantener el fallback actual
        return "Intento #{translate_attr(field)}: #{prev} → #{curr}: #{_e.message}"
      end

      if field.eql? 'enroll_status'
        if prev.eql? 1 and curr.eql? 0
          return "<b>¡Preinscripción Completada!</b> ".html_safe
        elsif curr.eql? 1
          return "<b>¡Preinscripción Iniciada!</b> ".html_safe
        end
      elsif field.eql? 'permanence_status'
        if prev and curr
          prev_val = EnrollAcademicProcess.permanence_statuses.keys[prev]
          curr_val = EnrollAcademicProcess.permanence_statuses.keys[curr]
          return "Cambio de #{translate_attr(field)} de <b>#{prev_val.humanize}</b> a <b>#{curr_val.humanize}</b>".html_safe
        elsif prev.nil? && curr
          curr_val = EnrollAcademicProcess.permanence_statuses.keys[curr]
          return "Asignación de #{translate_attr(field)} a <b>#{curr_val.humanize}</b>".html_safe
        end
      elsif field.eql? 'status'
        prev_val = AcademicRecord.statuses.keys[prev] if prev
        curr_val = AcademicRecord.statuses.keys[curr] if curr
        if prev_val && curr_val
          return "Cambio de #{translate_attr(field)} de <b>#{prev_val.humanize}</b> a <b>#{curr_val.humanize}</b>".html_safe
        elsif prev.nil? && curr_val
          return "Asignación de #{translate_attr(field)} a <b>#{curr_val.humanize}</b>".html_safe
        end
      else
        return "Cambio de #{translate_attr(field)}: #{prev} → #{curr}"
      end
    end
  end

  # Etiquetas por transición booleana, con posibilidad de especializar por modelo
  def boolean_transition_label(field, prev, curr)
    # Especial para Section (mantiene semántica previa)
    if item_type.to_s == 'Section'
      return 'Reactivada' if prev == true && curr == false
      return 'Completada' if prev == false && curr == true
    end

    # Genérico
    return 'Apagada' if prev == true && curr == false
    return 'Encendida' if prev == false && curr == true
    # Sin cambio
    curr.to_s
  end

  # Resuelve el nombre de un objeto dado su clase y un id
  # Devuelve nil si no puede resolver o si el objeto no responde a :name
  def resolve_name_from_id(klass, id)
    return nil if id.nil? || (id.is_a?(String) && id.strip.empty?)
    # Si viene como string numérico, convertir a entero de forma segura
    safe_id = begin
      Integer(id)
    rescue ArgumentError, TypeError
      id
    end
    obj = klass.find_by(id: safe_id)
    return nil unless obj
    return obj.name if obj.respond_to?(:name)
    nil
  end
end

# Incluir el módulo en la clase base de PaperTrail para que esté disponible siempre
PaperTrail::Version.include(PaperTrailVersionExtensions)
