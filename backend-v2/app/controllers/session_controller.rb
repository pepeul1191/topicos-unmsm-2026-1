# app/controllers/session_controller.rb
class SessionController < ApplicationController
  layout "blank"
  before_action :redirect_if_logged_in, only:[:sign_in]

  def sign_in
    
  end

  def login
    username = params[:username]
    password = params[:password]

    #result = AuthService.login_by_username(username, password)
    result = AuthService.simple_login(username, password)

    if result[:success]
      user_data = result[:data]
      # Guardar en sesión
      #session[:user_token] = user_data['token'] || user_data[:token]
      #session[:user_id] = user_data['id'] || user_data[:id]

      # Guardar en sesión
      session[:user] = {
        'id' => user_data[:user][:username],
        'username' => user_data[:user][:username],
        'name' => user_data[:user][:name] || user_data[:user][:username],
        'email' => user_data[:user][:email],
        'oauth' => false
      }
      session[:tokens] = user_data[:tokens]
      session[:roles] = user_data[:roles]

      # Registrar login exitoso
      '''
      LoginLog.create!(
        user_id: user_data[:user][:id],
        success: true,
        ip_address: request.remote_ip,
        created_at: Time.current
      )'''

      redirect_to root_path
    else
      flash[:alert] = result[:message]
      render :sign_in 
    end
  end

  def get_session
    if session.present? && session.to_hash.any?
      render json: {
        data: session.to_hash,
        message: 'datos del usuario logueado',
        error: nil,
        success: true
      }
    else
      render json: {
        data: nil,
        message: 'No hay sesión activa',
        error: 'Sesión no encontrada',
        success: false
      }, status: :not_found
    end
  end

  def sign_out
    # Si es OAuth, opcionalmente revocar token
    if session[:user]&.dig('oauth') && session[:tokens]&.dig('access')
      revoke_google_token(session[:tokens]['access'])
    end
    
    reset_session
    flash[:notice] = "Sesión cerrada correctamente"
    redirect_to sign_in_path
  end


  private

  def redirect_if_logged_in
    if session[:user].present?
      redirect_to root_path
    end
  end
end