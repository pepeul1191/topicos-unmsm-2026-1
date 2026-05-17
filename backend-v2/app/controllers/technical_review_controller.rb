# app/controllers/technical_review_controller.rb
class TechnicalReviewController < ApplicationController
  layout "dashboard"

  def new
    @nav_link = 'cars-management'
    @car_id = params[:car_id]
    render "technical_reviews/new"
  end

  def create
    resp = TechnicalReviewService.create(review_params)

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def edit
    @nav_link = 'cars-management'
    resp = TechnicalReviewService.fetch_one(params[:id])

    if resp[:success]
      @technical_review = resp[:data]
      @car_id = params[:car_id]
      render "technical_reviews/edit"
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def update
    resp = TechnicalReviewService.update(params[:id], review_params)

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def delete
    resp = TechnicalReviewService.delete(params[:id])

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  private

  def review_params
    params.permit(:description, :created, :car_id)
  end
end