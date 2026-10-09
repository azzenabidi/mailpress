require "test_helper"

class PostMailboxTest < ActionMailbox::TestCase
  include ActionMailbox::TestHelper
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  setup { @original = ENV["MAILPRESS_ALLOWED_SENDERS"] }
  teardown { ENV["MAILPRESS_ALLOWED_SENDERS"] = @original }

  test "creates and publishes a post from a PUBLISH: subject" do
    receive_inbound_email_from_source(<<~MAIL)
      From: Author <me@example.com>
      To: blog@example.com
      Subject: PUBLISH: Shipped from my inbox
      Content-Type: text/html; charset=UTF-8

      <p>Hello from <strong>email</strong>.</p>
    MAIL

    post = Post.find_by(slug: "shipped-from-my-inbox")
    assert_not_nil post
    assert post.published?
    assert_not_nil post.published_at
    assert_equal "me@example.com", post.author_email
    assert_includes post.content.to_plain_text, "Hello from email."
  end

  test "creates a draft for a DRAFT: subject, ignoring reply prefixes" do
    receive_inbound_email_from_source(<<~MAIL)
      From: me@example.com
      To: blog@example.com
      Subject: Re: DRAFT: Something I might publish

      Plain text body.
    MAIL

    post = Post.find_by(slug: "something-i-might-publish")
    assert_not_nil post
    assert post.draft?
    assert_nil post.published_at
  end

  test "creates a draft for a plain subject" do
    receive_inbound_email_from_source(<<~MAIL)
      From: me@example.com
      To: blog@example.com
      Subject: Just a normal subject

      Body
    MAIL

    assert Post.find_by(slug: "just-a-normal-subject").draft?
  end

  test "renders plain text bodies as paragraphs" do
    receive_inbound_email_from_source(<<~MAIL)
      From: me@example.com
      To: blog@example.com
      Subject: Two paragraphs
      Content-Type: text/plain; charset=UTF-8

      First paragraph.

      Second paragraph.
    MAIL

    html = Post.find_by(slug: "two-paragraphs").content.body.to_s
    assert_includes html, "<p>First paragraph.</p>"
    assert_includes html, "<p>Second paragraph.</p>"
  end

  test "sanitizes dangerous HTML from emails" do
    receive_inbound_email_from_source(<<~MAIL)
      From: me@example.com
      To: blog@example.com
      Subject: PUBLISH: Dangerous
      Content-Type: text/html; charset=UTF-8

      <p>Safe</p><script>alert(1)</script>
    MAIL

    html = Post.find_by(slug: "dangerous").content.body.to_s
    assert_includes html, "Safe"
    assert_not_includes html, "<script"
  end

  test "updates an existing post from an EDIT: subject" do
    post = Post.create!(title: "Old title", slug: "old-title", status: :published, published_at: Time.current)

    receive_inbound_email_from_source(<<~MAIL)
      From: me@example.com
      To: blog@example.com
      Subject: EDIT: old-title | New title
      Content-Type: text/html; charset=UTF-8

      <p>Replacement body.</p>
    MAIL

    post.reload
    assert_equal "New title", post.title
    assert_equal "old-title", post.slug
    assert_includes post.content.to_plain_text, "Replacement body."
  end

  test "editing a missing slug bounces a notice instead of raising" do
    assert_emails 1 do
      perform_enqueued_jobs do
        receive_inbound_email_from_source(<<~MAIL)
          From: me@example.com
          To: blog@example.com
          Subject: EDIT: does-not-exist

          Body
        MAIL
      end
    end
  end

  test "notifies authorized senders and rejects strangers when an allowlist is set" do
    ENV["MAILPRESS_ALLOWED_SENDERS"] = "boss@example.com"

    inbound = receive_inbound_email_from_source(<<~MAIL)
      From: stranger@example.com
      To: blog@example.com
      Subject: PUBLISH: Let me in

      Body
    MAIL

    assert inbound.bounced?
    assert_nil Post.find_by(slug: "let-me-in")
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob
  end
end
