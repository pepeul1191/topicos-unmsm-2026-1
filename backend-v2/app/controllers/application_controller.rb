class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_custom_header

  private

  def set_custom_header
    response.set_header("Server", "Ubuntu")
  end

  def require_login
    unless logged_in?
      flash[:alert] = "Debes iniciar sesión"
      redirect_to sign_in_path
    end
  end

  def logged_in?
    # Verifica si hay un usuario en sesión
    session[:user].present?
  end

  def redirect_if_logged_in
    if logged_in?
      flash[:notice] = "Ya tienes una sesión activa"
      redirect_to root_path
    end
  end
end
