# frozen_string_literal: true
class SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super do |user|
      send_sign_in_notification(user)
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def send_sign_in_notification(user)
    return if user.blank?

    login_data = {
      sign_in_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent.to_s,
      device: detect_device(request.user_agent.to_s),
      browser: detect_browser(request.user_agent.to_s),
      os: detect_os(request.user_agent.to_s),
      location: detect_location
    }

    UserMailer.login_alert(user, login_data).deliver_now
  rescue StandardError => e
    Rails.logger.error("[SIGN_IN_ALERT] No se pudo enviar el correo para User##{user&.id}: #{e.class} - #{e.message}")
  end

  def detect_location
    city = request.headers['HTTP_CF_IPCITY'].presence || request.headers['HTTP_X_CITY'].presence
    region = request.headers['HTTP_CF_REGION'].presence || request.headers['HTTP_X_REGION'].presence
    country = request.headers['HTTP_CF_IPCOUNTRY'].presence ||
              request.headers['HTTP_CLOUDFRONT_VIEWER_COUNTRY'].presence ||
              request.headers['HTTP_X_COUNTRY_CODE'].presence

    [city, region, country].compact.join(', ').presence || 'No disponible'
  end

  def detect_device(user_agent)
    return 'Móvil' if user_agent.match?(/Mobile|Android|iPhone|iPad/i)

    'Escritorio'
  end

  def detect_browser(user_agent)
    return 'Edge' if user_agent.include?('Edg/')
    return 'Chrome' if user_agent.include?('Chrome/')
    return 'Firefox' if user_agent.include?('Firefox/')
    return 'Safari' if user_agent.include?('Safari/') && !user_agent.include?('Chrome/')

    'Desconocido'
  end

  def detect_os(user_agent)
    return 'Windows' if user_agent.match?(/Windows/i)
    return 'macOS' if user_agent.match?(/Mac OS X|Macintosh/i)
    return 'Linux' if user_agent.match?(/Linux/i)
    return 'Android' if user_agent.match?(/Android/i)
    return 'iOS' if user_agent.match?(/iPhone|iPad|iPod/i)

    'Desconocido'
  end
end
