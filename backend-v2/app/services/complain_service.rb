# app/services/complain_service.rb
class ComplainService < ApplicationService

  def self.fetch_one(id)
    complain = Complain.find_by(id: id)
    return handle_not_found("Denuncia no encontrada") unless complain

    build_response(data: complain, message: "OK")
  rescue => e
    handle_error("Error al buscar denuncia: #{e.message}", e.backtrace)
  end

  def self.create(params)
    complain = Complain.new(params)

    if complain.save
      build_response(data: complain, message: "Denuncia creada correctamente")
    else
      handle_validation_error(complain)
    end
  rescue => e
    handle_error("Error al crear denuncia: #{e.message}", e.backtrace)
  end

  def self.update(id, params)
    complain = Complain.find_by(id: id)
    return handle_not_found("Denuncia no encontrada") unless complain

    if complain.update(params)
      build_response(data: complain, message: "Denuncia actualizada correctamente")
    else
      handle_validation_error(complain)
    end
  rescue => e
    handle_error("Error al actualizar denuncia: #{e.message}", e.backtrace)
  end

  def self.delete(id)
    complain = Complain.find_by(id: id)
    return handle_not_found("Denuncia no encontrada") unless complain

    if complain.destroy
      build_response(message: "Denuncia eliminada correctamente")
    else
      handle_error("No se pudo eliminar la denuncia")
    end
  rescue => e
    handle_error("Error al eliminar denuncia: #{e.message}", e.backtrace)
  end

  def self.fetch_by_car(car_id:, page: 1, per_page: 5)
    complains = Complain.where(car_id: car_id).order(created: :asc)

    total = complains.count
    total_pages = (total.to_f / per_page).ceil
    offset = (page - 1) * per_page

    paginated = complains.offset(offset).limit(per_page)

    build_response(
      data: {
        complains: paginated,
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
    handle_error("Error al listar denuncias: #{e.message}", e.backtrace)
  end
end