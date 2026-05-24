# app/controllers/car_controller.rb

class CarController < ApplicationController
  layout "dashboard"

  def car_params
    params.permit(:owner, :branch, :model, :color, :frabricated, :plate)
  end

  def index
    @nav_link = 'cars-management'

    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10

    page = 1 if page < 1
    per_page = 10 if per_page < 1

    result = CarService.fetch_all(
      page: page,
      per_page: per_page,
      search_params: params
    )

    if result[:success]
      @cars = result[:data][:cars]
      @pagination = result[:data][:pagination]
    else
      @cars = []
      @pagination = {
        page: page,
        per_page: per_page,
        total_cars: 0,
        total_pages: 0,
        start_record: 0,
        end_record: 0
      }
      flash.now[:alert] = result[:message]
    end

    render 'cars/index'
  end

  def new
    @nav_link = 'cars-management'
    render 'cars/new'
  end

  def create
    resp = CarService.create(car_params)

    if resp[:success]
      redirect_to "/cars/#{resp[:data].id}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/new"
    end
  end

  def edit
    @nav_link = 'cars-management'

    resp = CarService.fetch_one(params[:id])

    if resp[:success]
      @car = resp[:data]

      # =========================
      # TECHNICAL REVIEWS
      # =========================
      page_reviews = params[:page_reviews]&.to_i || 1
      per_page_reviews = params[:per_page_reviews]&.to_i || 5

      result_reviews = TechnicalReviewService.fetch_by_car(
        car_id: @car.id,
        page: page_reviews,
        per_page: per_page_reviews
      )

      @technical_reviews = result_reviews[:data][:reviews]
      @pagination_reviews = result_reviews[:data][:pagination]

      # =========================
      # COMPLAINS
      # =========================
      page_complains = params[:page_complains]&.to_i || 1
      per_page_complains = params[:per_page_complains]&.to_i || 5

      result_complains = ComplainService.fetch_by_car(
        car_id: @car.id,
        page: page_complains,
        per_page: per_page_complains
      )

      @complains = result_complains[:data][:complains]
      @pagination_complains = result_complains[:data][:pagination]

      # =========================
      # INFRACTIONS
      # =========================
      page_infractions = params[:page_infractions]&.to_i || 1
      per_page_infractions = params[:per_page_infractions]&.to_i || 5

      result_infractions = InfractionService.fetch_by_car(
        car_id: @car.id,
        page: page_infractions,
        per_page: per_page_infractions
      )

      @infractions = result_infractions[:data][:infractions]
      @pagination_infractions = result_infractions[:data][:pagination]

      render 'cars/edit'
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/new"
    end
  end

  def update
    resp = CarService.update(params[:id], car_params)

    if resp[:success]
      redirect_to "/cars/#{params[:id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:id]}/edit"
    end
  end

  def delete
    resp = CarService.delete(params[:id])

    if resp[:success]
      redirect_to "/cars", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars"
    end
  end

  def fetch_one
    # ese id es el plate en el OLAP
    resp = EtlExecutionService.fetch_one(params[:plate])

    if resp[:success]
      render json: resp, status: :ok
    else
      render json: resp, status: :not_found
    end

  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end
end