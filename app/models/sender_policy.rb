# Decides whether an inbound email comes from a trusted author.
#
# Configure with a comma-separated allowlist in MAILPRESS_ALLOWED_SENDERS, e.g.
#
#   MAILPRESS_ALLOWED_SENDERS="me@example.com,*@myteam.dev"
#
# Entries are matched case-insensitively against the RFC5322 From address.
# The "*@domain" form authorizes a whole domain.
#
# Outside production an empty allowlist accepts everything so the app works
# out of the box in development and tests.
class SenderPolicy
  WILDCARD_DOMAIN = /\A\*@(.+)\z/.freeze

  class << self
    def authorized?(mail)
      patterns = allowed_senders
      return true if patterns.empty? && !Rails.env.production?

      from = Array(mail.from).compact.map(&:downcase)
      from.any? { |address| patterns.any? { |pattern| match?(pattern, address) } }
    end

    def allowed_senders
      ENV.fetch("MAILPRESS_ALLOWED_SENDERS", "")
          .split(",")
          .map(&:strip)
          .reject(&:empty?)
          .map(&:downcase)
    end

    private

    def match?(pattern, address)
      if (domain = pattern[WILDCARD_DOMAIN, 1])
        address.end_with?("@#{domain}")
      else
        pattern == address
      end
    end
  end
end
