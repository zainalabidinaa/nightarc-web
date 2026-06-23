# Moonlit Email Setup

Domain: `trymoonlit.app`

## SMTP recommendation

Use Zoho Mail for human inboxes and Resend for Supabase Auth delivery.

- Human mailbox: `support@trymoonlit.app` in Zoho Mail
- Supabase sender: `Moonlit <access@trymoonlit.app>` through Resend SMTP

Supabase SMTP values:

```txt
Host: smtp.resend.com
Port: 465
Username: resend
Password: <Resend API key>
Sender email: access@trymoonlit.app
Sender name: Moonlit
```

## Supabase templates

Dashboard path:

```txt
Supabase -> Authentication -> Emails -> Templates
```

Paste these files into the matching templates:

```txt
Confirm signup -> docs/email/confirm-signup.html
Reset password / Recovery -> docs/email/recovery.html
Invite user -> docs/email/invite-user.html
```

Subjects:

```txt
Confirm signup: Complete your Moonlit setup
Reset password: Reset your Moonlit password
Invite user: You're invited to Moonlit
```

## Logo URL

Templates reference:

```txt
https://trymoonlit.app/moonlit-icon.png
```

The repo now contains the asset at:

```txt
public/moonlit-icon.png
```

After deploying the root web app, verify:

```sh
curl -I https://trymoonlit.app/moonlit-icon.png
```

Expected:

```txt
HTTP/2 200
content-type: image/png
```

## Cloudflare records

Status: Resend records are present in Cloudflare and verified by Resend.

Current Resend records:

```txt
TXT resend._domainkey.trymoonlit.app
MX  send.trymoonlit.app -> feedback-smtp.eu-west-1.amazonses.com
TXT send.trymoonlit.app -> v=spf1 include:amazonses.com ~all
Proxy: DNS only
```

DMARC monitoring has been added:

```txt
Type: TXT
Name: _dmarc
Value: v=DMARC1; p=none; adkim=s; aspf=s
Proxy: DNS only
```

For inbox brand logos later, move DMARC to enforcement after verification:

```txt
v=DMARC1; p=quarantine; rua=mailto:dmarc@trymoonlit.app; adkim=s; aspf=s
```

## Inbox profile pictures

Logo inside the email body is handled by the templates. The small sender avatar beside the email subject is controlled by mailbox providers.

Recommended order:

1. Gmail avatar: create/use a Google account for `access@trymoonlit.app`, then set its profile photo to the Moonlit logo.
2. Apple Mail: set up Apple Business Connect Branded Mail for `trymoonlit.app`.
3. BIMI: after SPF, DKIM, and DMARC enforcement are correct, add a BIMI SVG and optional certificate.

## Forgot password status

The email template is prepared, but the current Mac app does not expose a "Forgot password" button or reset-password screen. Supabase can send recovery emails once the recovery template and redirect URL are configured, but the app/web flow still needs a reset-password destination.
