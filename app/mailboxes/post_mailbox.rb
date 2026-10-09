# Turns inbound emails into posts.
#
# Subject grammar (prefixes are case-insensitive, "RE:"/"FW:" are ignored):
#
#   PUBLISH: My new post title   -> creates a published post
#   DRAFT: My new post title     -> creates a draft (plain subjects also create drafts)
#   EDIT: existing-slug          -> replaces the post's content
#   EDIT: existing-slug | New title  -> replaces content and title
#
# The HTML part of the email becomes the post body (sanitized), the text part
# is used when no HTML is present, and image attachments are attached to the
# post through Active Storage.
class PostMailbox < ApplicationMailbox
  REPLY_PREFIX = /\A\s*(?:re|aw|fw|fwd):\s*/i
  PUBLISH_PREFIX = /\A\s*publish:\s*/i
  DRAFT_PREFIX = /\A\s*draft:\s*/i
  EDIT_PREFIX = /\A\s*edit:\s*(?<slug>[a-z0-9][a-z0-9\-]*)(?:\s*\|\s*(?<title>.+))?\s*\z/im

  ALLOWED_TAGS = %w[
    p br strong b em i u s del ins mark blockquote pre code
    ul ol li dl dt dd
    h1 h2 h3 h4 h5 h6
    a hr span img figure figcaption
  ].freeze
  ALLOWED_ATTRIBUTES = %w[href title alt src width height].freeze

  def process
    case command
    when :edit then update_post
    when :publish then create_post(publish: true)
    else create_post(publish: false)
    end
  end

  private

  def command
    subject = normalized_subject
    return :edit if subject.match?(EDIT_PREFIX)
    return :publish if subject.match?(PUBLISH_PREFIX)
    return :draft if subject.match?(DRAFT_PREFIX)

    :plain
  end

  def normalized_subject
    subject = mail.subject.to_s.strip
    subject = subject.sub(REPLY_PREFIX, "") while subject.match?(REPLY_PREFIX)
    subject
  end

  def post_title
    normalized_subject.sub(PUBLISH_PREFIX, "").sub(DRAFT_PREFIX, "").strip.presence || "Untitled"
  end

  def create_post(publish:)
    post = Post.new(title: post_title, author_email: sender, inbound_email: inbound_email)
    post.content = post_body if post_body.present?

    if publish
      post.status = :published
      post.published_at = Time.current
    end

    post.save!
    attach_images(post)
    notify(post, publish ? "published" : "created as a draft")
  end

  def update_post
    match = normalized_subject.match(EDIT_PREFIX)
    post = Post.find_by(slug: match[:slug])

    if post.nil?
      notify_missing(match[:slug])
      return
    end

    post.title = match[:title].strip if match[:title].present?
    post.content = post_body if post_body.present?
    post.save!
    attach_images(post)
    notify(post, "updated")
  end

  def notify(post, verb)
    return if sender.blank?

    NotifyMailer.post_processed(post, to: sender, verb: verb).deliver_later
  end

  def notify_missing(slug)
    return if sender.blank?

    NotifyMailer.missing_post(slug, to: sender).deliver_later
  end

  def attach_images(post)
    image_attachments.each do |attachment|
      post.images.attach(
        io: StringIO.new(attachment.body.decoded),
        filename: attachment.filename.presence || "image"
      )
    end
  rescue StandardError => e
    Rails.logger.warn("PostMailbox: could not attach images: #{e.message}")
  end

  def image_attachments
    mail.attachments.select { |attachment| attachment.mime_type.to_s.start_with?("image/") }
  end

  def post_body
    @post_body ||=
      if html_body.present?
        sanitize_html(html_body)
      elsif text_body.present?
        text_to_html(text_body)
      end
  end

  def html_body
    if mail.html_part
      mail.html_part.decoded
    elsif mail.mime_type.to_s.include?("html")
      mail.decoded
    end
  end

  def text_body
    if mail.text_part
      mail.text_part.decoded
    elsif mail.mime_type.to_s == "text/plain"
      mail.decoded
    end
  end

  def sanitize_html(html)
    if defined?(Rails::HTML5::SafeListSanitizer)
      Rails::HTML5::SafeListSanitizer.new.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
    else
      Rails::HTML::SafeListSanitizer.new.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
    end
  end

  def text_to_html(text)
    text.split(/\n{2,}/).map do |paragraph|
      "<p>#{ERB::Util.html_escape(paragraph.strip).gsub("\n", "<br>")}</p>"
    end.join
  end

  def sender
    mail.from&.first
  end
end
