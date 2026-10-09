# Resend is used both as the Action Mailer delivery method (outbound
# confirmations) and as the Action Mailbox ingress (inbound posts).
#
#   RESEND_API_KEY                - API key used to send mail and fetch inbound messages
#   RESEND_INGRESS_SIGNING_SECRET - svix signing secret of the email.received webhook
#
Resend.api_key = ENV["RESEND_API_KEY"] if ENV["RESEND_API_KEY"].present?
