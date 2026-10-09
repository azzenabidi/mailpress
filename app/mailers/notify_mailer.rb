class NotifyMailer < ApplicationMailer
  # Confirmation sent to the author after their email became a post.
  def post_processed(post, to:, verb:)
    @post = post
    @verb = verb
    mail to: to, subject: "Mailpress: #{post.title} #{verb}"
  end

  def missing_post(slug, to:)
    @slug = slug
    mail to: to, subject: "Mailpress: no post found for '#{slug}'"
  end

  def unauthorized_sender(to:)
    @allowlist = SenderPolicy.allowed_senders
    mail to: to, subject: "Mailpress: sender not authorized"
  end
end
