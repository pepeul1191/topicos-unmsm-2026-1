# app/services/infraction_service.rb
class InfractionService < ApplicationService

  def self.fetch_one(id)
    infraction = Infraction.find_by(id: id)
    return handle_not_found("Infracción no encontrada") unless infraction

    build_response(data: infraction, message: "OK")
  rescue => e
    handle_error("Error al buscar infracción: #{e.message}", e.backtrace)
  end

  def self.create(params)
    infraction = Infraction.new(params)

    if infraction.save
      build_response(data: infraction, message: "Infracción creada correctamente")
    else
      handle_validation_error(infraction)
    end
  rescue => e
    handle_error("Error al crear infracción: #{e.message}", e.backtrace)
  end

  def self.update(id, params)
    infraction = Infraction.find_by(id: id)
    return handle_not_found("Infracción no encontrada") unless infraction

    if infraction.update(params)
      build_response(data: infraction, message: "Infracción actualizada correctamente")
    else
      handle_validation_error(infraction)
    end
  rescue => e
    handle_error("Error al actualizar infracción: #{e.message}", e.backtrace)
  end

  def self.delete(id)
    infraction = Infraction.find_by(id: id)
    return handle_not_found("Infracción no encontrada") unless infraction

    if infraction.destroy
      build_response(message: "Infracción eliminada correctamente")
    else
      handle_error("No se pudo eliminar la infracción")
    end
  rescue => e
    handle_error("Error al eliminar infracción: #{e.message}", e.backtrace)
  end

  def self.fetch_by_car(car_id:, page: 1, per_page: 5)
    infractions = Infraction.where(car_id: car_id).order(created: :asc)

    total = infractions.count
    total_pages = (total.to_f / per_page).ceil
    offset = (page - 1) * per_page

    paginated = infractions.offset(offset).limit(per_page)

    build_response(
      data: {
        infractions: paginated,
        pagination: {
          page: page,
          per_page: per_page,
          total: total,
          total_pages: total_pages,
          start_record: offset + 1,
          end_record: [offset + per_page, total].min
        }
      },
      message: "OK"
    )
  rescue => e
    handle_error("Error al listar infracciones: #{e.message}", e.backtrace)
  end
end