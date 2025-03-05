# require 'axlsx'
class XlsAdapter
    def initialize(data)
        @data = data.split("\n")
    end

    def to_xls
        service = XlsAdapterService.new(@data)
        service.csv_to_xls

        # package = Axlsx::Package.new
        # workbook = package.workbook

        # workbook.add_worksheet(name: "Hoja 1") do |sheet|
        #     @data.each do |row|
        #         # Add a row to the sheet with the data from the current line
        #         sheet.add_row row.to_s.split(';')
        #     end
        # end

        # package.to_stream
        
    end
end