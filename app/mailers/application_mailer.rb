class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILPRESS_MAIL_FROM", "Mailpress <onboarding@resend.dev>")
  layout "mailer"
end
