class Marketing::UnsubscribeController < ApplicationController
  def index
    @email = params[:email]
    @user = User.find_by(email: @email) if @email.present?

    if @email.present? && @user.present?
      @user.update!(send_marketing_emails: false)
      @success = true
    elsif @email.present?
      @error = "Email not found."
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("unsubscribe_form", partial: "unsubscribe_form")
      end
    end
  end
end
