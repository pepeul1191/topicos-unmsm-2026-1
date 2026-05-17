# app/services/car_service.rb
class CarService < ApplicationService

  def self.fetch_all(page: 1, per_page: 10, search_params: {})
    begin
      cars = Car.all.order(id: :asc)

      if search_params[:owner].present?
        cars = cars.where("owner LIKE ?", "%#{search_params[:owner]}%")
      end

      if search_params[:plate].present?
        cars = cars.where("plate LIKE ?", "%#{search_params[:plate]}%")
      end

      if search_params[:branch].present?
        cars = cars.where("branch LIKE ?", "%#{search_params[:branch]}%")
      end

      total_cars = cars.count
      total_pages = (total_cars.to_f / per_page).ceil
      offset = (page - 1) * per_page

      paginated = cars.offset(offset).limit(per_page)

      data = {
        cars: paginated,
        pagination: {
          page: page,
          per_page: per_page,
          total_cars: total_cars,
          total_pages: total_pages,
          start_record: offset + 1,
          end_record: [offset + per_page, total_cars].min
        }
      }

      build_response(data: data, message: "Lista de carros obtenida correctamente")
    rescue => e
      handle_error("Error al obtener carros: #{e.message}", e.backtrace)
    end
  end

  def self.fetch_one(id)
    car = Car.find_by(id: id)
    return handle_not_found("Carro no encontrado") unless car

    build_response(data: car, message: "Carro encontrado")
  rescue => e
    handle_error("Error al buscar carro: #{e.message}", e.backtrace)
  end

  def self.create(params)
    car = Car.new(params)

    if car.save
      build_response(data: car, message: "Carro creado exitosamente")
    else
      handle_validation_error(car)
    end
  rescue => e
    handle_error("Error al crear carro: #{e.message}", e.backtrace)
  end

  def self.update(id, params)
    car = Car.find_by(id: id)
    return handle_not_found("Carro no encontrado") unless car

    if car.update(params)
      build_response(data: car, message: "Carro actualizado exitosamente")
    else
      handle_validation_error(car)
    end
  rescue => e
    handle_error("Error al actualizar carro: #{e.message}", e.backtrace)
  end

  def self.delete(id)
    car = Car.find_by(id: id)
    return handle_not_found("Carro no encontrado") unless car

    if car.destroy
      build_response(message: "Carro eliminado exitosamente")
    else
      handle_error("No se pudo eliminar el carro")
    end
  rescue => e
    handle_error("Error al eliminar carro: #{e.message}", e.backtrace)
  end
end