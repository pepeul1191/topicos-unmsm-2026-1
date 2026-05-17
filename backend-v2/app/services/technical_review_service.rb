# app/services/technical_review_service.rb
class TechnicalReviewService < ApplicationService

  def self.fetch_one(id)
    review = TechnicalReview.find_by(id: id)
    return handle_not_found("Revisión no encontrada") unless review

    build_response(data: review, message: "OK")
  rescue => e
    handle_error("Error al buscar revisión: #{e.message}", e.backtrace)
  end

  def self.create(params)
    review = TechnicalReview.new(params)

    if review.save
      build_response(data: review, message: "Revisión creada correctamente")
    else
      handle_validation_error(review)
    end
  rescue => e
    handle_error("Error al crear revisión: #{e.message}", e.backtrace)
  end

  def self.update(id, params)
    review = TechnicalReview.find_by(id: id)
    return handle_not_found("Revisión no encontrada") unless review

    if review.update(params)
      build_response(data: review, message: "Revisión actualizada correctamente")
    else
      handle_validation_error(review)
    end
  rescue => e
    handle_error("Error al actualizar revisión: #{e.message}", e.backtrace)
  end

  def self.delete(id)
    review = TechnicalReview.find_by(id: id)
    return handle_not_found("Revisión no encontrada") unless review

    if review.destroy
      build_response(message: "Revisión eliminada correctamente")
    else
      handle_error("No se pudo eliminar la revisión")
    end
  rescue => e
    handle_error("Error al eliminar revisión: #{e.message}", e.backtrace)
  end

  def self.fetch_by_car(car_id:, page: 1, per_page: 5)
    reviews = TechnicalReview.where(car_id: car_id).order(created: :asc)

    total = reviews.count
    total_pages = (total.to_f / per_page).ceil
    offset = (page - 1) * per_page

    paginated = reviews.offset(offset).limit(per_page)

    build_response(
      data: {
        reviews: paginated,
        pagination: {
          page: page,
          per_page: per_page,
          total_reviews: total,
          total_pages: total_pages,
          start_record: offset + 1,
          end_record: [offset + per_page, total].min
        }
      },
      message: "OK"
    )
  rescue => e
    handle_error("Error al listar revisiones: #{e.message}", e.backtrace)
  end
end