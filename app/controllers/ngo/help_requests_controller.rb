require "csv"

module Ngo
  class HelpRequestsController < ApplicationController
    before_action :require_ngo_login
    before_action :set_help_request, only: [ :destroy, :update, :update_observation, :clear_observation ]

    def index
      @status = normalize_status(params[:status])
      scope = HelpRequest.where(status: @status)
      @neighborhoods = scope.distinct.pluck(:neighborhood).compact
        .uniq { |b| b.to_s.strip.upcase }
        .sort_by { |b| b.to_s.strip.upcase }
      scope = apply_neighborhood_filter(scope)
      @help_requests = apply_order(scope, @status).limit(500)
    end

    def completed
      redirect_to ngo_help_requests_path({
        status: "completed",
        neighborhood: params[:neighborhood],
        order: params[:order]
      }.compact)
    end

    def destroy
      @help_request.destroy
      redirect_to ngo_help_requests_path({
        status: normalize_status(params[:status]),
        neighborhood: params[:neighborhood],
        order: params[:order]
      }.compact), notice: "Pedido apagado."
    end

    def update
      new_status = normalize_status(params[:status])
      @help_request.update!(status: new_status)
      redirect_to ngo_help_requests_path({
        status: @help_request.status,
        neighborhood: params[:neighborhood],
        order: params[:order]
      }.compact), notice: status_notice(@help_request.status)
    end

    def update_observation
      @help_request.update!(observation: params[:observation].to_s.strip.presence)
      redirect_to ngo_help_requests_path({
        status: @help_request.status,
        neighborhood: params[:neighborhood],
        order: params[:order]
      }.compact), notice: "Observação salva."
    end

    def clear_observation
      @help_request.update!(observation: nil)
      redirect_to ngo_help_requests_path({
        status: @help_request.status,
        neighborhood: params[:neighborhood],
        order: params[:order]
      }.compact), notice: "Observação apagada."
    end

    def export
      status = normalize_status(params[:status])
      scope = HelpRequest.where(status: status)
      scope = apply_neighborhood_filter(scope)
      help_requests = apply_order(scope, status)

      csv_string = CSV.generate(headers: true, force_quotes: true, col_sep: ";") do |csv|
        csv << [
          "Nome", "Telefone", "Endereço", "Bairro", "O que precisa", "Tipo de situação",
          "Urgente", "Status", "Pessoas", "Observação", "Criado em", "Atualizado em"
        ]
        help_requests.find_each do |hr|
          csv << [
            hr.name,
            hr.phone,
            hr.address,
            hr.neighborhood,
            hr.need,
            hr.situation_type,
            hr.urgent? ? "Sim" : "Não",
            export_status_label(hr.status),
            hr.people_count_label,
            hr.observation,
            hr.created_at.strftime("%d/%m/%Y %H:%M"),
            hr.updated_at.strftime("%d/%m/%Y %H:%M")
          ]
        end
      end

      bom = "\uFEFF"
      send_data(
        bom + csv_string,
        filename: "pedidos-#{status}-#{Date.current.iso8601}.csv",
        type: "text/csv; charset=utf-8",
        disposition: "attachment"
      )
    end

    private

    def set_help_request
      @help_request = HelpRequest.find(params[:id])
    end

    def normalize_status(raw)
      status = raw.to_s
      return "pending" if status.blank?
      return status if HelpRequest::STATUSES.include?(status)
      "pending"
    end

    def status_notice(status)
      case status
      when "pending"
        "Pedido marcado como pendente."
      when "in_progress"
        "Pedido marcado como em atendimento."
      when "completed"
        "Pedido marcado como concluído."
      else
        "Status atualizado."
      end
    end

    def export_status_label(status)
      case status
      when "pending" then "Pendente"
      when "in_progress" then "Em atendimento"
      when "completed" then "Concluído"
      else status.to_s
      end
    end

    def apply_neighborhood_filter(scope)
      valor = params[:neighborhood].to_s.strip.upcase
      return scope if valor.blank?
      scope.where("UPPER(TRIM(neighborhood)) = ?", valor)
    end

    def apply_order(scope, status)
      time_column = status == "completed" ? :updated_at : :created_at
      if params[:order] == "oldest"
        scope = scope.order(time_column => :asc, id: :asc)
      else
        scope = scope.order(time_column => :desc, id: :desc)
      end
      scope
    end
  end
end
