class Post < ApplicationRecord
  belongs_to :inbound_email, class_name: "ActionMailbox::InboundEmail", optional: true
  has_rich_text :content
  has_many_attached :images

  enum :status, { draft: 0, published: 1 }, default: :draft, scopes: false

  scope :published, -> { where(status: :published).where.not(published_at: nil).order(published_at: :desc, id: :desc) }
  scope :draft, -> { where(status: :draft) }
  scope :chronological, -> { order(published_at: :desc, id: :desc) }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { case_sensitive: true }

  before_validation :generate_slug, on: :create

  after_save_commit :broadcast_update, if: :saved_change_to_status?

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def to_param
    slug
  end

  def excerpt(length = 280)
    plain = content&.to_plain_text.to_s.strip
    plain.truncate(length)
  end

  private

  def generate_slug
    return if title.blank? || slug.present?

    base = title.parameterize.presence || "untitled"
    candidate = base
    n = 2
    while Post.exists?(slug: candidate)
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end

  def broadcast_update
    return unless published?

    BroadcastPostJob.perform_later(id)
  end
end
