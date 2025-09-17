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
      "#{translate_attr(field)}: #{boolean_transition_label(field, prev, curr)}"
    else
      "#{translate_attr(field)}: #{prev} → #{curr}"
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
end

# Incluir el módulo en la clase base de PaperTrail para que esté disponible siempre
PaperTrail::Version.include(PaperTrailVersionExtensions)
