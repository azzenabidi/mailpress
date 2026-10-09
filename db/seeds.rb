# Sample content so the blog is never empty on a fresh checkout.
# Safe to re-run: it replaces the demo posts each time.

Post.destroy_all

Post.create!(
  title: "Hello, Mailpress",
  status: :published,
  published_at: 2.days.ago,
  author_email: "author@example.com",
  content: <<~HTML
    <p>This blog has no admin panel. Every post here arrived as an email —
    the subject line decided whether it became a draft or a published post.</p>
    <p>Send a message with the subject <strong>PUBLISH: My first post</strong> to
    the address configured for this app, and it will show up on the home page
    within seconds.</p>
  HTML
)

Post.create!(
  title: "Editing posts from your inbox",
  status: :published,
  published_at: 1.day.ago,
  author_email: "author@example.com",
  content: <<~HTML
    <p>Made a typo? Reply to the confirmation email with the subject</p>
    <pre>EDIT: hello-mailpress</pre>
    <p>and the body of the reply replaces the post's content. Append
    <code>| New title</code> to the subject to also rename it.</p>
  HTML
)

Post.create!(
  title: "A draft that never got published",
  status: :draft,
  author_email: "author@example.com",
  content: "<p>Drafts are only visible in the database until you send an email with <code>PUBLISH:</code> in the subject.</p>"
)

puts "Seeded #{Post.count} posts (#{Post.published.count} published)"
