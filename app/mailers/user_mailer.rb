class UserMailer < ApplicationMailer
  def welcome
    @text_preview = "Essential tips and tricks to get you started."

    @user = params[:user]

    mail(to: @user.email, subject: "Welcome to Clear My Spam!")
  end

  def re_engagement
    @text_preview = "Thanks for giving Clear My Spam a try! Here's a $#{SentEmail::RE_ENGAGEMENT_COUPON_DISCOUNT_DOLLARS} credit for your feedback."

    @is_marketing_email = true
    @user = params[:user]

    @metrics = @user.metrics
    @discount_code = params[:discount_code]

    mail(to: @user.email, subject: "A $#{SentEmail::RE_ENGAGEMENT_COUPON_DISCOUNT_DOLLARS} credit for your feedback 🤝")
  end

  def re_engagement_reminder
    @text_preview = "Your $#{SentEmail::RE_ENGAGEMENT_COUPON_DISCOUNT_DOLLARS} credit is expiring soon!"

    @is_marketing_email = true
    @user = params[:user]

    @metrics = @user.metrics
    @discount_code = params[:discount_code]

    mail(to: @user.email, subject: "Your $#{SentEmail::RE_ENGAGEMENT_COUPON_DISCOUNT_DOLLARS} credit is expiring soon 📅")
  end
end
