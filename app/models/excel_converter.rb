require 'caxlsx'


class ExcelConverter
  def initialize(objects = [], schema = nil)
    @fields = []
    @associations = []
    schema ||= {}

    return self if (@objects = objects).blank?

    @model = objects.dup.first.class
    @abstract_model = RailsAdmin::AbstractModel.new(@model)
    @model_config = @abstract_model.config
    @methods = [(schema[:only] || []) + (schema[:methods] || [])].flatten.compact
    @fields = @methods.collect { |m| export_field_for(m) }.compact
    @empty = ::I18n.t('admin.export.empty_value_for_associated_objects')
    schema_include = schema.delete(:include) || {}

    @associations = schema_include.each_with_object({}) do |(key, values), hash|
      association = export_field_for(key)
      next unless association&.association?

      model_config = association.associated_model_config
      abstract_model = model_config.abstract_model
      methods = [(values[:only] || []) + (values[:methods] || [])].flatten.compact

      hash[key] = {
        association: association,
        model: abstract_model.model,
        abstract_model: abstract_model,
        model_config: model_config,
        fields: methods.collect { |m| export_field_for(m, model_config) }.compact,
      }
      hash
    end
  end

  # Método específico para CSV streaming que evita conflictos de ordenamiento
  def to_csv_streaming(response_stream)
    p "  Iniciando exportación CSV streaming    ".center(1000, 'C')
    
    # Generar encabezados
    headers = generate_excel_header
    response_stream.write headers.join(";") + "\n"
    
    processed_count = 0
    batch_size = 20
    
    # Usar find_each sin ordenamiento específico para evitar conflictos
    if @objects.respond_to?(:reorder)
      # Remover cualquier ordenamiento que pueda causar conflictos
      objects_to_process = @objects.reorder(nil)
    else
      objects_to_process = @objects
    end
    
    objects_to_process.find_each(batch_size: batch_size) do |object|
      row_data = generate_excel_row(object)
      response_stream.write row_data.join(";") + "\n"
      processed_count += 1
    end

  end

  def to_xlsx_streaming(response_stream)
    require 'xlsxtream'

    headers = generate_excel_header
    scope = @objects.respond_to?(:reorder) ? @objects.reorder(nil) : @objects

    Xlsxtream::Workbook.open(response_stream) do |xlsx|
      xlsx.write_worksheet('Datos') do |sheet|
        sheet << headers
        scope.find_each(batch_size: 20) do |object|
          sheet << generate_excel_row(object)
        end
      end
    end
  end

  private

  def export_field_for(method, model_config = @model_config)
    model_config.export.fields.detect { |f| f.name == method }
  end

  def generate_excel_header
    @fields.collect do |field|
      ::I18n.t('admin.export.csv.header_for_root_methods', name: field.label, model: @abstract_model.pretty_name)
    end +
      @associations.flat_map do |_association_name, option_hash|
        option_hash[:fields].collect do |field|
          ::I18n.t('admin.export.csv.header_for_association_methods', name: field.label, association: option_hash[:association].label)
        end
      end
  end

  def generate_excel_row(object)
    @fields.collect do |field|
      field.with(object: object).export_value
    end +
      @associations.flat_map do |association_name, option_hash|
        associated_objects = [object.send(association_name)].flatten.compact
        option_hash[:fields].collect do |field|
          associated_objects.collect { |ao| field.with(object: ao).export_value.presence || @empty }.join(',')
        end
      end
  end
end
