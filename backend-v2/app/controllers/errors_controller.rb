# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  def not_found
    if should_render_json?
      render json: {
        data: nil,
        sucess: false,
        message: "Recuro no encontrado" ,
        error: "404 - #{request.method} #{request.path}" ,
      }, status: :not_found
    else
      render 'errors/not_found', status: :not_found, layout: 'blank'
    end
  end

  private

  def should_render_json?
    # Si es una petición API
    return true if request.path.start_with?('/api')
    
    # Si no es método GET
    return true unless request.get?
    
    # Si es un archivo estático
    return true if static_asset?
    
    # En cualquier otro caso, renderizar HTML
    false
  end

  def static_asset?
    # Verificar extensiones de archivos estáticos
    static_extensions = ['.js', '.css', '.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg', '.woff', '.woff2', '.ttf', '.eot']
    static_extensions.any? { |ext| request.path.end_with?(ext) }
  end
end