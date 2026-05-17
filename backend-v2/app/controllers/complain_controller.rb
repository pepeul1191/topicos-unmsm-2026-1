# app/controllers/complain_controller.rb
class ComplainController < ApplicationController
  layout "dashboard"

  def new
    @car_id = params[:car_id]
    render "complains/new"
  end

  def create
    @nav_link = 'cars-management'
    resp = ComplainService.create(complain_params)

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def edit
    @nav_link = 'cars-management'
    resp = ComplainService.fetch_one(params[:id])

    if resp[:success]
      @complain = resp[:data]
      @car_id = params[:car_id]
      render "complains/edit"
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def update
    resp = ComplainService.update(params[:id], complain_params)

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def delete
    resp = ComplainService.delete(params[:id])

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  private

  def complain_params
    params.permit(:description, :created, :car_id)
  end
end