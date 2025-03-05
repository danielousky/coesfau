require 'axlsx'

class XlsAdapterService
    def initialize(data)
        @data = data
    end

    def csv_to_xls #(stream)
        package = Axlsx::Package.new
        workbook = package.workbook

        workbook.add_worksheet(name: "Hoja 1") do |sheet|
            @data.each do |row|
                # Add a row to the sheet with the data from the current line
                sheet.add_row row.to_s.split(';')
                # response.stream.write xls_adapter.to_xls.read
            end
        end

        package.to_stream
    end
end