class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name("jonathan@clearmyspam.com", "Clear My Spam")

  layout "mailer"
end
