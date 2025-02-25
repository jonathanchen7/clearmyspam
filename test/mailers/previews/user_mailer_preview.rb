# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def welcome
    user = build(:user)
    UserMailer.with(user: user).welcome
  end
end
