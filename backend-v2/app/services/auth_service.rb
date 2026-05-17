# app/services/auth_service.rb
class AuthService < ApplicationService
  include HTTParty

  default_timeout 30
  headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'

  def self.simple_login(username, password)
    admin_username = ENV['USERNAME']
    admin_password = ENV['PASSWORD']

    if admin_username.blank? || admin_password.blank?
      return handle_error("admin credentials not configured")
    end

    if username == admin_username && password == admin_password
      login_response = {
        user: {
          id: 1,
          username: admin_username,
          name: "Admin User",
          email: "jovaldiv@ulima.edu.pe",
        },
        roles: ["admin"],
        tokens: {
          access: "admin-access-token",
          file: "admin-file-token"
        }
      }
      build_response(data: login_response, message: "Admin login successful")
    else
      
    end
  end

  private

  # Health check method
  def self.health_check
    url = ENV['URL_ACCESS_SERVICE']
    
    if url.blank?
      return handle_error("Authentication service URL not configured")
    end

    begin
      response = get("#{url}/health", timeout: 5)

      if response.success?
        build_response(message: "Authentication service available")
      else
        handle_error("Authentication service not available")
      end

    rescue => e
      handle_error("Error checking authentication service", e.message)
    end
  end
end