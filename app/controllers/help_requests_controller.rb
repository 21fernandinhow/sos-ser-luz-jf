class HelpRequestsController < ApplicationController
  def new
    @help_request = HelpRequest.new
  end

  def create
    @help_request = HelpRequest.new(help_request_params)
    if @help_request.save
      redirect_to root_path, notice: "Pedido de ajuda ##{@help_request.id} registrado. Em breve entraremos em contato."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def help_request_params
    params.require(:help_request).permit(
      :name, :phone, :address, :neighborhood, :need
    )
  end
end
