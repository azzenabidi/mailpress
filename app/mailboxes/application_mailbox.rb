class ApplicationMailbox < ActionMailbox::Base
  routing ->(inbound_email) { SenderPolicy.authorized?(inbound_email.mail) } => :post
  routing all: :reject
end
