class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def user_signed_in?
    current_user.present?
  end

  def require_ngo_login
    return if user_signed_in?
    redirect_to ngo_login_path, alert: "Faça login para acessar a área da ONG."
  end
end
