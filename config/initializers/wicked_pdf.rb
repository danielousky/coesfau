# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

WickedPdf.config = {
  # Path to the wkhtmltopdf executable: This usually isn't needed if using
  # one of the wkhtmltopdf-binary family of gems.
  # exe_path: '/usr/local/bin/wkhtmltopdf',
  #   or
  exe_path: Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf'),

  # Needed for wkhtmltopdf 0.12.6+ to use many wicked_pdf asset helpers
  enable_local_file_access: true,
  # Optimización: deshabilitar JS para evitar esperas de timeouts y reflows
  disable_javascript: true,
  # Usar media print para CSS
  print_media_type: true,
  # DPI de salida razonable (reduce peso)
  dpi: 96,
  image_dpi: 96


  # Layout file to be used for all PDFs
  # (but can be overridden in `render :pdf` calls)
  # layout: 'pdf.html',

  # Using wkhtmltopdf without an X server can be achieved by enabling the
  # 'use_xvfb' flag. This will wrap all wkhtmltopdf commands around the
  # 'xvfb-run' command, in order to simulate an X server.
  #
  # use_xvfb: true,
}

WickedPdf.config ||= {}
WickedPdf.config.merge!({
  layout: "layouts/pdf",
  orientation: "Portrait", # Landscape
  page_size: "letter",
  lowquality: true,
  zoom: 1
})