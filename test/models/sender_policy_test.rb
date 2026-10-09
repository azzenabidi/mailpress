require "test_helper"

class SenderPolicyTest < ActiveSupport::TestCase
  setup do
    @original = ENV["MAILPRESS_ALLOWED_SENDERS"]
  end

  teardown do
    ENV["MAILPRESS_ALLOWED_SENDERS"] = @original
  end

  test "accepts anyone outside production when the allowlist is empty" do
    ENV.delete("MAILPRESS_ALLOWED_SENDERS")

    assert SenderPolicy.authorized?(mail_from("random@anywhere.com"))
  end

  test "matches exact addresses case-insensitively" do
    ENV["MAILPRESS_ALLOWED_SENDERS"] = "Boss@Example.com"

    assert SenderPolicy.authorized?(mail_from("boss@example.com"))
    assert_not SenderPolicy.authorized?(mail_from("someone@example.com"))
  end

  test "matches wildcard domains" do
    ENV["MAILPRESS_ALLOWED_SENDERS"] = "*@myteam.dev, me@example.com"

    assert SenderPolicy.authorized?(mail_from("anyone@myteam.dev"))
    assert SenderPolicy.authorized?(mail_from("me@example.com"))
    assert_not SenderPolicy.authorized?(mail_from("anyone@notmyteam.dev"))
    assert_not SenderPolicy.authorized?(mail_from("me@elsewhere.com"))
  end

  private

  def mail_from(address)
    Mail.new(from: address, to: "blog@example.com", subject: "hi")
  end
end
