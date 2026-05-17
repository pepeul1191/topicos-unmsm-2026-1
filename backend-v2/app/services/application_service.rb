# app/services/application_service.rb
class ApplicationService
  protected

  def self.build_response(data: nil, message: nil, error: nil, success: true)
    {
      data: data,
      message: message,
      error: error,
      success: success
    }
  end

  def self.handle_error(message, error_details = nil)
    build_response(
      data: nil,
      message: message,
      error: error_details || message,
      success: false
    )
  end

  def self.handle_not_found(message = "Registro no encontrado")
    handle_error(message, "Registro no encontrado en la base de datos")
  end

  def self.handle_validation_error(record)
    error_message = record.errors.full_messages.join(', ')
    handle_error("Error de validación #{error_message}", error_message)
  end
end