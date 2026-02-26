module Ngo
  class HelpRequestsController < ApplicationController
    before_action :require_ngo_login
    before_action :set_help_request, only: [:destroy, :update]

    def index
      @help_requests = HelpRequest.where.not(status: "completed").order(created_at: :desc, id: :desc).limit(500)
    end

    def completed
      @help_requests = HelpRequest.where(status: "completed").order(updated_at: :desc, id: :desc).limit(500)
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
  end
end
