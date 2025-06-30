class LargeExportJob < ApplicationJob
  queue_as :default

  def perform(user_id, model_name, objects, schema)
    file_name = "Reporte Coes - #{I18n.t("activerecord.models.#{model_name}.other")&.titleize} #{DateTime.now.strftime('%d-%m-%Y_%I:%M%P')}.xlsx"
    user = User.find(user_id)
    # Aquí generas el Excel (puedes usar Spreadsheet, Axlsx, etc.)
    
    # ExcelConverter.new(objects, schema).to_xlsx
    UserMailer.large_export(user_id, file_name, objects, schema).deliver_now

    export = Export.create!(user: user, status: "listo")
    export.file.attach(io: File.open(file_path), filename: file_name)
    # Notifica al usuario si lo deseas
    # ExportMailer.notify_ready(export).deliver_later
  end
end