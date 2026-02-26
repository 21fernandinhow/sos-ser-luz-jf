class HomeController < ApplicationController
  def index
    # Do not load or send help requests to the view. Public home only shows CTA.
  end
end
