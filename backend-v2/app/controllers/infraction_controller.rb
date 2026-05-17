# app/controllers/infraction_controller.rb
class InfractionController < ApplicationController
  layout "dashboard"

  def new
    @nav_link = 'cars-management'
    @car_id = params[:car_id]
    render "infractions/new"
  end

  def create
    resp = InfractionService.create(infraction_params)

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def edit
    @nav_link = 'cars-management'
    resp = InfractionService.fetch_one(params[:id])

    if resp[:success]
      @infraction = resp[:data]
      @car_id = params[:car_id]
      render "infractions/edit"
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def update
    resp = InfractionService.update(params[:id], infraction_params)

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  def delete
    resp = InfractionService.delete(params[:id])

    if resp[:success]
      redirect_to "/cars/#{params[:car_id]}/edit", notice: resp[:message]
    else
      flash[:alert] = resp[:message]
      redirect_to "/cars/#{params[:car_id]}/edit"
    end
  end

  private

  def infraction_params
    params.permit(:description, :created, :car_id)
  end
end