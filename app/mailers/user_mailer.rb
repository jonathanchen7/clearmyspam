class UserMailer < ApplicationMailer
  def welcome
    @text_preview = "Essential tips and tricks to get you started."

    @user = params[:user]

    mail(to: @user.email, subject: "Welcome to Clear My Spam!")
  end

  def abandoned_cart
    @text_preview = "We'd really appreciate your feedback!"

    @is_marketing_email = true
    @user = params[:user]

    @metrics = @user.metrics
    @discount_code = params[:discount_code] || "FEEDBACK30"

    # return unless @user.send_marketing_emails? && @metrics.disposed_count > 300

    mail(to: @user.email, subject: "One quick question...")
  end
end
