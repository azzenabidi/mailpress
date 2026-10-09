# Bounces emails from senders that are not on MAILPRESS_ALLOWED_SENDERS.
class RejectMailbox < ApplicationMailbox
  def process
    if sender.present?
      bounce_with NotifyMailer.unauthorized_sender(to: sender)
    else
      bounced!
    end
  end

  private

  def sender
    mail.from&.first
  end
end
