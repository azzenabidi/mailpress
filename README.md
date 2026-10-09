# Mailpress

A blog with no admin panel: **every post is published by sending an email.**

Mailpress is a small, complete Rails 8 application that turns inbound email into
blog posts. Send a message to your inbound address and it appears on the site —
with the option to keep it as a draft, publish it immediately, or edit an
existing post — all driven by the subject line.

## How it works

```
 ┌────────────┐   email.received   ┌──────────────────────────────┐
 │   Author   │ ──── email ──────▶ │  Resend (inbound email)      │
 └────────────┘                    └──────────────┬───────────────┘
                                                  │ webhook (svix signed)
                                                  ▼
                    POST /rails/action_mailbox/resend/inbound_emails
                                                  │
                                        ┌─────────▼─────────┐
                                        │  Action Mailbox   │
                                        │  SenderPolicy     │
                                        │  PostMailbox      │
                                        └─────────┬─────────┘
                                                  │ creates / updates
                                                  ▼
                              ┌───────────┐   ┌───────────────┐
                              │  SQLite   │◀──│  Post (Action │
                              │  (Solid*) │   │  Text + files)│
                              └─────┬─────┘   └───────┬───────┘
                                    │                 │ Turbo broadcast
                                    ▼                 ▼
                              public blog (Hotwire + Tailwind)
```

1. [Resend](https://resend.com) receives the email and posts an `email.received`
   webhook to the app.
2. The official `resend` gem's Action Mailbox ingress verifies the webhook
   signature and fetches the full message from Resend.
3. `PostMailbox` checks the sender against an allowlist, parses the subject, and
   creates or updates a `Post` — sanitizing the HTML body and attaching images.
4. Published posts are broadcast over Turbo Streams, so open browser tabs update
   live. The author gets a confirmation email back through the Resend API.

## Email conventions

The subject line is the command. `RE:` / `FW:` prefixes are ignored, so you can
simply reply to your own confirmation emails.

| Subject                        | Result                                            |
| ------------------------------ | ------------------------------------------------- |
| `PUBLISH: My new post`         | Creates a **published** post                      |
| `DRAFT: My new post`           | Creates a **draft**                               |
| `My new post`                  | Also creates a draft                              |
| `EDIT: my-new-post`            | Replaces that post's body with this email's body  |
| `EDIT: my-new-post \| New title` | Replaces the body and renames the post          |

The email's HTML part becomes the post body (sanitized to a safe allowlist),
falling back to the text part rendered as paragraphs. Image attachments are
stored with Active Storage and shown under the post.

## Stack

- **Rails 8.1** — Solid Queue, Solid Cache, Solid Cable, Propshaft, Thruster
- **SQLite** for the primary, queue and cache databases
- **Action Mailbox** for inbound email, **Action Mailer** for outbound
- **Resend** as the inbound ingress and outbound delivery method
- **Hotwire** (Turbo + Stimulus) and **Tailwind CSS 4**
- **Minitest**, RuboCop, Brakeman and bundler-audit wired into CI

## Getting started

Requirements: Ruby 4.0+, SQLite 3.

```bash
bin/setup          # install gems, prepare databases, seed demo posts
bin/dev            # http://localhost:3000 (Rails + Tailwind watcher)
```

Run the test suite and linters:

```bash
bin/rails test
bin/rubocop
bin/brakeman
bin/bundler-audit
```

## Configuring inbound email (Resend)

1. Create a [Resend](https://resend.com) account and **verify a domain** you
   want to publish from.
2. Enable inbound email for that domain and add an address such as
   `blog@your-domain.com`. Point the domain's MX records where Resend asks.
3. Create a webhook subscribed to the **`email.received`** event targeting:

   ```
   https://your-host/rails/action_mailbox/resend/inbound_emails
   ```

4. Copy the webhook's signing secret (`whsec_...`) and your API key
   (`re_...`) into the environment.

## Configuration

Copy `.env.example` to `.env` and fill it in:

| Variable                       | Purpose                                                                 |
| ------------------------------ | ----------------------------------------------------------------------- |
| `RESEND_API_KEY`               | Sends confirmations and fetches full inbound messages                    |
| `RESEND_INGRESS_SIGNING_SECRET`| svix signing secret used to verify webhooks (`whsec_...`)                |
| `MAILPRESS_ALLOWED_SENDERS`    | Comma-separated allowlist; supports `*@domain.com`. Empty in dev = allow all |
| `MAILPRESS_MAIL_FROM`          | From address for confirmation/bounce mail (verified Resend domain)       |
| `MAILPRESS_HOST`               | Public host used in email links (production)                             |

In production, set the same variables (for example with [Kamal](https://kamal-deploy.org)
and `.kamal/secrets`). Solid Queue processes jobs via `bin/jobs`.

## Testing email locally

Action Mailbox ships a developer conductor at
<http://localhost:3000/rails/conductor/action_mailbox/inbound_emails> where you
can paste a raw RFC822 message. You can also drive the whole pipeline from a
console:

```bash
bin/rails runner '
  raw = "From: me@example.com\nTo: blog@example.com\nSubject: PUBLISH: Hi from the console\n\n<p>Hello</p>\n"
  inbound = ActionMailbox::InboundEmail.create_and_extract_message_id!(raw)
  ApplicationMailbox.route(inbound)
'
```

Without an allowlist configured, development accepts email from any sender so
you can try things out before setting up a domain.

## License

Released under the [MIT License](LICENSE).
