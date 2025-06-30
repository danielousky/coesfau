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

  def to_xlsx
    package = Axlsx::Package.new
    workbook = package.workbook

    workbook.add_worksheet(name: "Datos") do |sheet|
      sheet.add_row generate_excel_header

      method = @objects.respond_to?(:find_each) ? :find_each : :each
      @objects.send(method) do |object|
        sheet.add_row generate_excel_row(object)
      end
    end

    package.to_stream.read
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
