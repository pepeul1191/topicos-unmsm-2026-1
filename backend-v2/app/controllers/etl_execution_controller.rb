# app/controllers/etl_execution_controller.rb
class EtlExecutionController < ApplicationController
  layout "dashboard"

  def index
    @nav_link = 'etl-process'

    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10

    page = 1 if page < 1
    per_page = 10 if per_page < 1

    result = EtlExecutionService.fetch_all(page: page, per_page: per_page)

    if result[:success]
      @etl_executions = result[:data][:etl_executions]
      @pagination = result[:data][:pagination]
    else
      @etl_executions = []
      @pagination = {
        page: page,
        per_page: per_page,
        total: 0,
        total_pages: 0,
        start_record: 0,
        end_record: 0
      }

      flash.now[:alert] = result[:message]
    end

    render 'etl_executions/index'
  end

  def run
    resp = EtlExecutionService.execute()

    if resp[:success]
      flash[:notice] = resp[:message]
    else
      flash[:alert] = resp[:message]
    end

    redirect_to "/etl-executions"
  end
end