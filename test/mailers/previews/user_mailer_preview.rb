# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def welcome
    user = build(:user)
    UserMailer.with(user: user).welcome
  end

  def re_engagement
    user = build(:user)
    UserMailer.with(user: user, discount_code: "123456").re_engagement
  end

  def re_engagement_reminder
    user = build(:user)
    UserMailer.with(user: user, discount_code: "123456").re_engagement_reminder
  end
end
