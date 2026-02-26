class SessionsController < ApplicationController
  def new
    redirect_to ngo_help_requests_path if user_signed_in?
  end

  def create
    user = User.find_by(email: params[:email]&.strip&.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to ngo_help_requests_path, notice: "Login realizado."
    else
      flash.now[:alert] = "E-mail ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Você saiu da área da ONG."
  end
end
