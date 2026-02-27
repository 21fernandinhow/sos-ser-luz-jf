module Ngo
  class HelpRequestsController < ApplicationController
    before_action :require_ngo_login
    before_action :set_help_request, only: [:destroy, :update]

    def index
      scope = HelpRequest.where.not(status: "completed")
      @neighborhoods = scope.distinct.pluck(:neighborhood).compact.sort_by { |b| b.to_s.upcase }
      scope = apply_neighborhood_filter(scope)
      @help_requests = apply_order(scope, :index).limit(500)
    end

    def completed
      scope = HelpRequest.where(status: "completed")
      @neighborhoods = scope.distinct.pluck(:neighborhood).compact.sort_by { |b| b.to_s.upcase }
      scope = apply_neighborhood_filter(scope)
      @help_requests = apply_order(scope, :completed).limit(500)
    end

    def destroy
      @help_request.destroy
      redirect_to ngo_help_requests_path, notice: "Pedido apagado."
    end

    def update
      new_status = %w[pending completed].include?(params[:status]) ? params[:status] : "pending"
      @help_request.update!(status: new_status)
      if @help_request.status == "completed"
        redirect_to ngo_completed_help_requests_path, notice: "Pedido marcado como concluído."
      else
        redirect_to ngo_help_requests_path, notice: "Pedido desmarcado como concluído."
      end
    end

    private

    def set_help_request
      @help_request = HelpRequest.find(params[:id])
    end

    def apply_neighborhood_filter(scope)
      valor = params[:neighborhood].to_s.strip.upcase
      return scope if valor.blank?
      scope.where("UPPER(TRIM(neighborhood)) = ?", valor)
    end

    def apply_order(scope, action)
      if params[:order] == "oldest"
        scope = action == :completed ? scope.order(updated_at: :asc, id: :asc) : scope.order(created_at: :asc, id: :asc)
      else
        scope = action == :completed ? scope.order(updated_at: :desc, id: :desc) : scope.order(created_at: :desc, id: :desc)
      end
      scope
    end
  end
end
