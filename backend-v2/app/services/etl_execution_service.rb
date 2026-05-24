# app/services/etl_execution_service.rb
class EtlExecutionService < ApplicationService

  def self.fetch_all(page: 1, per_page: 10)
    begin
      executions = EtlExecution.order(created: :desc)

      total = executions.count
      total_pages = (total.to_f / per_page).ceil
      offset = (page - 1) * per_page

      paginated = executions.offset(offset).limit(per_page)

      build_response(
        data: {
          etl_executions: paginated,
          pagination: {
            page: page,
            per_page: per_page,
            total: total,
            total_pages: total_pages,
            start_record: offset + 1,
            end_record: [offset + per_page, total].min
          }
        },
        message: "Ejecuciones ETL listadas correctamente"
      )
    rescue => e
      handle_error("Error al listar ETL executions: #{e.message}", e.backtrace)
    end
  end

  def self.execute
    begin
      # borrar olap
      FileUtils.rm_rf(OLAP_PATH)
      # query a oltp
      cars = Car.includes(:technical_reviews, :infractions, :complains)
      cars = cars.as_json(
        include: [
          :technical_reviews,
          :infractions,
          :complains
        ]
      )
      technical_reviews = 0
      infractions = 0
      complains = 0
      # convertir datos de oltp a olap
      cars.each do |car|
        plate = car["plate"]
        tmp = {
          plate => {
            "car" => {
              "id"=> car["id"], 
              "owner"=> car["owner"], 
              "branch"=> car["branch"], 
              "model"=> car["model"], 
              "color"=> car["color"], 
              "frabricated"=> car["frabricated"], 
              "plate"=> car["plate"]
            }, 
            "technical_reviews"=> car["technical_reviews"], 
            "infractions"=> car["infractions"], 
            "complains"=> car["complains"]
          } 
        }
        technical_reviews = technical_reviews + car["technical_reviews"].length
        infractions = infractions + car["infractions"].length
        complains = complains + car["complains"].length
        # insertar a olap
        OLAP_DB.put(plate, JSON.generate(tmp))
      end
      # insert
      message = "Se cargaron #{cars.length} autos, con #{technical_reviews} revisiones técnicas, #{infractions} infracciones y #{complains} denuncias"
      EtlExecution.create(
        description: message,
        created: Time.current,
        succeded: true
      )
      # return
      build_response(
        data: {},
        message: "Se cargaron #{cars.length} autos, con #{technical_reviews} revisiones técnicas, #{infractions} infracciones y #{complains} denuncias"
      )
    rescue => e
      EtlExecution.create(
        description: "No se cargaron los autos. #{e.message}",
        created: Time.current,
        succeded: false
      )
      # insert
      handle_error("Error al ejecutar ETL: #{e.message}", e.backtrace)
    end
  end

  def self.fetch_one(plate)
    raw = OLAP_DB.get(plate)

    if raw.nil?
      return handle_error(
        "Carro no encontrado",
        "No existe placa registrada en el OLAP"
      )
    end
    puts '1 ++++++++++++++++++++++++++++++++++++'
    data = JSON.parse(raw)[plate]  # <-- Extraemos solo el valor de la placa

    build_response(
      data: data,
      message: "Carro encontrado"
    )

  rescue => e
    handle_error("Error al buscar carro: #{e.message}", e.backtrace)
  end
end