# Take stories from Wonky Write on your blog

This guide is for blog owners and their developers. It shows how to let people write a story
for your blog in [Wonky Write](https://wonky.work/write/) and send it to your review queue with
one button.

How it works:

1. Your blog links to Wonky Write with a **Write for us** button.
2. The contributor signs in (or signs up), agrees to send their story to your blog, and writes in
   their own Wonky document. Co-authors, comments, suggestions and offline editing all work as
   usual.
3. The contributor presses **Submit**. Wonky sends the story to your server as a signed webhook,
   and you put it in your review queue.
4. Your moderators read the story, and can comment and suggest edits in the Wonky document.
5. Your moderation tool tells Wonky the outcome: *changes requested*, *declined* or *published*,
   with an optional message. The contributor sees it in the document and gets a notification.
   After changes, they press **Resubmit** and the story comes back to your queue.

```
 Your blog                         Wonky                               Contributor
 ─────────                         ─────                               ───────────
 "Write for us" link ───────────▶  /write/new?publication=pub_…  ◀──── opens link, signs in
                                   new document for the story    ◀──── writes, presses Submit
 webhook receiver   ◀── POST ───── submission.submitted (signed)
 review queue
 moderator opens the document ───▶ comments / suggestions        ────▶ notified
 status API  ── POST ────────────▶ "changesRequested" + message  ────▶ notified, edits, Resubmit
 webhook receiver   ◀── POST ───── submission.submitted (sequence 2)
 status API  ── POST ────────────▶ "published" + post URL        ────▶ "Published · View post"
```

What you need:

- A Wonky account (free, at [wonky.work](https://wonky.work)).
- An HTTPS endpoint on your server that can receive webhooks (port 443, a public address).
- A place on your server to keep two secrets: the **signing secret** and the **API key**. Never
  put them in your website's frontend code.
- Your moderators' Wonky accounts, if they should read and comment on stories in Wonky.

The full design is in [specs/18-publications-and-submissions.md](../specs/18-publications-and-submissions.md).

---

## 1. Create a publication

In Wonky, open **Settings › Publications** (any app: account menu › *Wonky Work settings*) and
choose **New publication**.

| Setting | What to enter |
|---------|---------------|
| Name | What contributors see, e.g. *Serverpod blog* (up to 60 characters) |
| Site URL | Your blog's address, origin only: `https://blog.example.com` |
| Webhook URL | Where Wonky sends submissions: `https://blog.example.com/api/wonky/webhook`. It must be `https` on port 443 and reachable from the internet. Wonky doesn't follow redirects |
| Terms URL | Optional. Your contributor terms. When set, contributors must agree to them before they start |
| Template | Optional. One of your own Wonky Write documents. New stories start as a copy of it (without its comments), so you can include guidelines and a suggested structure |
| Submission fields | The title is always asked for. Turn on *Summary*, *Tags* (optionally from a fixed list), *Cover image*, *Author bio* and *Note to the moderators*, each optional or required |
| Moderators | The email addresses of your moderators' Wonky accounts (up to 20). A moderator without an account gets access once they sign up with that email |

When you create the publication, Wonky shows the **signing secret** (`whsec_…`) **once**. Copy
it into your server's secret store now. Then choose **Create API key** and store the key
(`wpk_…`) as well; it's also shown only once.

The publication page also shows the **publication id** (`pub_…`) and the **contributor link**.
Neither is a secret.

## 2. Verify your site

Verification shows contributors a ✓ next to your site's name, so they know the publication is
really yours. Without it, Wonky shows your webhook's host instead of your site and a warning.

Serve this file at `https://blog.example.com/.well-known/wonky-publications.json`:

```json
{ "publications": ["pub_7Hk2xQ9mR4tLwP0aZc3VbN"] }
```

List every publication id that belongs to the site. Then choose **Verify** on the publication
page. Changing the site URL later removes the verification; verify again.

## 3. Add the "Write for us" link

```html
<a href="https://wonky.work/write/new?publication=pub_7Hk2xQ9mR4tLwP0aZc3VbN">Write for us</a>
```

You can add `&ref=<your id>` (up to 64 characters: letters, digits, `-` and `_`) to tell
submissions apart, for example by a call for posts: `…&ref=cfp-2026`. Wonky passes `ref` back
in every webhook. Treat it as a hint from the link, not as proof of anything.

The link always works the same way, so it can sit on a static page. A contributor who already
has an unsubmitted story for your blog is offered to continue it.

## 4. Receive webhooks

Wonky sends `POST` requests with a JSON body to your webhook URL, signed per the
[Standard Webhooks](https://www.standardwebhooks.com/) specification. There are libraries for
most languages (`standardwebhooks` on npm and PyPI, and others); you can also check the
signature yourself in a few lines (below).

### 4.1 Headers

| Header | Value |
|--------|-------|
| `webhook-id` | `msg_…`, unique per event. A retry of the same event uses the **same id** |
| `webhook-timestamp` | Unix time in seconds when this attempt was sent |
| `webhook-signature` | `v1,<base64>`. During a secret rotation there are two, separated by a space; accept the request if either matches |
| `content-type` | `application/json` |

### 4.2 Check the signature

1. Take the secret without its `whsec_` prefix and base64-decode it: that's the HMAC key.
2. Build the signed content: `<webhook-id>.<webhook-timestamp>.<raw request body>`. Use the raw
   body exactly as received, before any JSON parsing.
3. Compute HMAC-SHA256 with the key, base64-encode it, and compare it with each `v1,` signature
   in the header using a constant-time comparison.
4. Reject the request if the timestamp is more than 5 minutes away from your clock.
5. Remember the `webhook-id`s you've handled (a day is enough) and ignore repeats.

**Node.js**

```js
import crypto from "node:crypto";

export function verifyWonkyWebhook(rawBody, headers, secret) {
  const id = headers["webhook-id"];
  const timestamp = headers["webhook-timestamp"];
  const signatures = (headers["webhook-signature"] ?? "").split(" ");
  if (!id || !timestamp) return false;
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) return false;
  const key = Buffer.from(secret.replace(/^whsec_/, ""), "base64");
  const expected = crypto
    .createHmac("sha256", key)
    .update(`${id}.${timestamp}.${rawBody}`)
    .digest();
  return signatures.some((s) => {
    const [version, value] = s.split(",");
    if (version !== "v1" || !value) return false;
    const given = Buffer.from(value, "base64");
    return given.length === expected.length && crypto.timingSafeEqual(given, expected);
  });
}
```

**Python**

```python
import base64, hashlib, hmac, time

def verify_wonky_webhook(raw_body: bytes, headers, secret: str) -> bool:
    msg_id = headers.get("webhook-id")
    timestamp = headers.get("webhook-timestamp")
    if not msg_id or not timestamp or abs(time.time() - int(timestamp)) > 300:
        return False
    key = base64.b64decode(secret.removeprefix("whsec_"))
    signed = f"{msg_id}.{timestamp}.".encode() + raw_body
    expected = base64.b64encode(hmac.new(key, signed, hashlib.sha256).digest()).decode()
    return any(
        s.startswith("v1,") and hmac.compare_digest(s[3:], expected)
        for s in headers.get("webhook-signature", "").split(" ")
    )
```

**Dart**

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

bool verifyWonkyWebhook(String rawBody, Map<String, String> headers, String secret) {
  final id = headers['webhook-id'];
  final timestamp = int.tryParse(headers['webhook-timestamp'] ?? '');
  if (id == null || timestamp == null) return false;
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  if ((now - timestamp).abs() > 300) return false;
  final key = base64.decode(secret.substring('whsec_'.length));
  final expected = Hmac(sha256, key).convert(utf8.encode('$id.$timestamp.$rawBody')).bytes;
  for (final s in (headers['webhook-signature'] ?? '').split(' ')) {
    if (!s.startsWith('v1,')) continue;
    final given = base64.decode(s.substring(3));
    if (given.length != expected.length) continue;
    var diff = 0;
    for (var i = 0; i < given.length; i++) {
      diff |= given[i] ^ expected[i];
    }
    if (diff == 0) return true;
  }
  return false;
}
```

**Test vector.** With the secret `whsec_MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw`, the id
`msg_2KWPBgLlAfxdpx2AI54pPJ85f4W`, the timestamp `1674087231` and this body (one line, no
trailing newline):

```
{"type":"publication.ping","createdAt":"2023-01-19T00:13:51Z","publicationId":"pub_7Hk2xQ9mR4tLwP0aZc3VbN"}
```

the signature is `v1,4+meITVYE+3sv8v+3Jl0/CXDGdczBRF7SOHoZxKwobQ=` (skip the timestamp check
when you test with it).

### 4.3 Answer quickly

Answer with any `2xx` status within **10 seconds**; the answer's body is ignored. Store the event
and do slow work (downloading images, notifying moderators) afterwards.

Anything else (an error status, a timeout, a redirect, a connection error) counts as not
delivered. Wonky retries with the same `webhook-id` after about 1 minute, 5 minutes, 30 minutes,
2 hours, 6 hours and 12 hours, then gives up. While it retries, the contributor sees
*Submitting…*; if every attempt fails, they're told that your blog couldn't receive the story.
You can see each attempt, and resend it, under **Deliveries** on the publication page.

Events can arrive more than once and out of order. Use `webhook-id` to ignore repeats and
`sequence` (below) to ignore an older submit that arrives after a newer one.

### 4.4 Events

Every body has these fields:

```json
{
  "type": "submission.submitted",
  "createdAt": "2026-10-20T09:14:03Z",
  "publicationId": "pub_7Hk2xQ9mR4tLwP0aZc3VbN"
}
```

| `type` | When | Other fields |
|--------|------|--------------|
| `publication.ping` | You choose *Send test*, or save a new webhook URL | — |
| `submission.submitted` | Every Submit, Resubmit and Submit update | `submission`, `sequence`, `revision`, `fields`, `markdown`, `assets`, `submittedBy` |
| `submission.withdrawn` | The contributor withdraws the story, or moves the document to the trash | `submission`, `reason`: `author` or `trashed` |
| `submission.disconnected` | The contributor disconnects the document from your blog. No more updates will come for this submission | `submission` |
| `comment.created` | Someone replies in the document's thread of your blog's messages (§6.2) | `submission`, `comment` |

Ignore types you don't know; new ones may be added.

### 4.5 `submission.submitted`

```json
{
  "type": "submission.submitted",
  "createdAt": "2026-10-20T09:14:03Z",
  "publicationId": "pub_7Hk2xQ9mR4tLwP0aZc3VbN",
  "submission": {
    "id": "sub_0192a3b4-5c6d-7e8f-9012-3456789abcde",
    "ref": "cfp-2026",
    "status": "inReview",
    "documentUrl": "https://wonky.work/write/d/0192a3b4-0000-7000-8000-000000000001"
  },
  "sequence": 2,
  "revision": 418,
  "fields": {
    "title": "How we sped up our CI three times",
    "summary": "A short look at caching, sharding and one weird flag.",
    "tags": ["dart", "ci"],
    "coverImage": "ast_0192a3b4-1111-7000-8000-000000000002",
    "authorBio": null,
    "note": "Fixed the code samples, thanks!"
  },
  "markdown": "# How we sped up our CI three times\n\n…\n\n![Build times](https://wonky.work/api/pub/v1/assets/ast_0192a3b4-1111-7000-8000-000000000002)\n",
  "assets": [
    {
      "id": "ast_0192a3b4-1111-7000-8000-000000000002",
      "name": "build-times.png",
      "type": "image/png",
      "bytes": 48213,
      "url": "https://wonky.work/api/pub/v1/assets/ast_0192a3b4-1111-7000-8000-000000000002"
    }
  ],
  "submittedBy": { "name": "Anna Berg", "wonkyUserId": "0191f0e2-aaaa-7000-8000-000000000003" }
}
```

- `submission.id` is stable for the story: use it as the key of your queue entry and update the
  entry on every new submit.
- `sequence` counts the submits of this submission (1, 2, …). Ignore a webhook whose `sequence`
  is lower than the one you have.
- `revision` is the document revision that was sent. When you publish, publish the content of the
  submit you reviewed; the contributor may keep editing in the meantime.
- `fields` holds the fields you turned on; fields you didn't turn on are `null` (`tags` is then
  `[]`). `coverImage` is the id of one of the `assets`. The contributor uploads the cover in the
  Submit dialog, so it is usually **not** in the `markdown`: show it as the post's cover without
  removing anything from the text. Covers uploaded in the dialog are 1200 × 630 WebP images
  (the Open Graph size, cropped to fill).
- Images uploaded to Wonky are WebP (`image/webp`), at most 2048 px on their longest side, with
  their metadata (EXIF, including GPS) removed. Older images can keep the type they were
  uploaded with, so read the `type` of each asset.
- `markdown` is CommonMark with GitHub tables and task lists. Open suggestions in the document are
  sent as the original text; comments are never included. There is no front matter: the title
  and the other fields are in `fields` (the Markdown usually starts with the title as a heading,
  because that's how people write).
- Images uploaded to Wonky appear as asset URLs (§5). Images that were already on the web keep
  their own `https://` URLs.
- `submittedBy.name` is the display name of the person who pressed Submit, which may be a
  co-author. Ask for the byline in a field if you need one. Wonky never sends email addresses.
  `wonkyUserId` is stable per Wonky account; use it to block a user (§7.6).
- `documentUrl` opens the story in Wonky. Your moderators can open it once Wonky has granted them
  access (§6.1).

### 4.6 `comment.created`

```json
{
  "type": "comment.created",
  "createdAt": "2026-10-21T08:02:11Z",
  "publicationId": "pub_7Hk2xQ9mR4tLwP0aZc3VbN",
  "submission": { "id": "sub_…", "ref": "cfp-2026", "status": "changesRequested",
                  "documentUrl": "https://wonky.work/write/d/…" },
  "comment": {
    "id": "0192a3b4-2222-7000-8000-000000000004",
    "body": "Done — I split the second section in two.",
    "author": { "name": "Anna Berg", "wonkyUserId": "0191f0e2-…", "isModerator": false }
  }
}
```

`body` is Markdown (bold, italic, code and links).

## 5. Download the images

Asset URLs need your API key:

```bash
curl -H "Authorization: Bearer $WONKY_API_KEY" -o build-times.png \
  https://wonky.work/api/pub/v1/assets/ast_0192a3b4-1111-7000-8000-000000000002
```

Download them right after you receive the webhook and host them yourself. An asset stays
available while the image exists in Wonky, but the contributor can delete it later. Only images
that were part of one of your submissions can be downloaded.

## 6. Moderate

### 6.1 In Wonky

When a story is submitted for the first time, each moderator gets **comment access** to the
document. They can read it, leave comments and suggest edits; they can't change the text
directly. The access ends when the story is withdrawn, declined or disconnected. Stories you have
published keep it, so you can review updates the same way. The contributor (or a co-author) can
also remove a moderator's access in the document's *Share* dialog; it comes back with the next
submit. A moderator who creates their Wonky account later gets access with the next submit or
status change.

Moderators don't get an email when they receive access. Link to `documentUrl` from your review
queue (*Open in Wonky*).

### 6.2 Messages back to the contributor

Your status calls and messages (§7.4, §7.5) appear in the document in one comment thread under
your publication's name, and every editor of the document is notified. When someone replies in
that thread, you receive `comment.created`. Comments elsewhere in the document stay in Wonky, but
your moderators can read them there.

### 6.3 Status flow

```
 draft ──Submit──▶ inReview ──you──▶ changesRequested ──Resubmit──▶ inReview
                     │                                   
                     ├──you──▶ declined     (final for this submission)
                     └──you──▶ published ──Submit update──▶ inReview
 inReview / changesRequested ──contributor withdraws──▶ withdrawn ──Submit──▶ inReview
```

Wonky sets `inReview` itself when you accept a `submission.submitted` webhook. You set the rest:

| From | You may set |
|------|-------------|
| `inReview` | `inReview`, `changesRequested`, `declined`, `published` |
| `changesRequested` | `inReview`, `changesRequested`, `declined`, `published` |
| `published` | `published` (for example to change the post URL) |
| `draft`, `declined`, `withdrawn` | nothing |

## 7. API reference

Base URL: `https://wonky.work/api/pub/v1/`

- **Authentication**: `Authorization: Bearer wpk_…` on every request. A key only reaches its own
  publication's submissions.
- **Bodies**: JSON, at most 1 MB.
- **Rate limit**: 120 requests per minute per key. Over it you get `429` with a `retry-after`
  header in seconds.
- **Errors**: a status code and `{ "error": "<code>", "message": "<text for people>" }`.

| Status | `error` | Meaning |
|--------|---------|---------|
| 400 | `invalidArgument` | A field is missing or wrong; `message` says which |
| 401 | `unauthorized` | No key, a malformed key, or a key that was rotated or deleted |
| 404 | `notFound` | No such submission or asset for this publication |
| 409 | `invalidTransition` | The status change isn't allowed from the current status (§6.3) |
| 410 | `gone` | The submission was withdrawn or disconnected |
| 413 | `tooLarge` | The body is larger than 1 MB |
| 429 | `rateLimited` | Too many requests |

### 7.1 List submissions

`GET submissions?status=inReview&after=<cursor>&limit=50`

`status` is optional (`draft`, `inReview`, `changesRequested`, `declined`, `published`,
`withdrawn`); `limit` is 1–100 (default 50). The newest change comes first. Pass the answer's
`next` as `after` to get the next page; `next` is `null` on the last page.

```json
{
  "submissions": [
    {
      "id": "sub_…", "ref": "cfp-2026", "status": "inReview",
      "documentUrl": "https://wonky.work/write/d/…",
      "title": "How we sped up our CI three times",
      "sequence": 2, "revision": 418,
      "submittedAt": "2026-10-20T09:14:03Z", "updatedAt": "2026-10-20T09:14:03Z",
      "publicUrl": null
    }
  ],
  "next": null
}
```

Use it to catch up after downtime. It isn't needed in normal operation.

### 7.2 Get a submission

`GET submissions/{id}` returns one entry as in the list, plus `fields`.

### 7.3 Get a submitted version

`GET submissions/{id}/content?sequence=2`

Returns the `submission.submitted` body of that submit (without `webhook-*` headers). Without
`sequence`, the latest submit. Use it when you missed a webhook.

### 7.4 Set the status

`POST submissions/{id}/status`

```json
{
  "status": "changesRequested",
  "message": "Thanks! Could you add a short intro and shorten the second section?"
}
```

| Field | |
|-------|--|
| `status` | `inReview`, `changesRequested`, `declined` or `published` (§6.3) |
| `message` | Optional Markdown, up to 10,000 characters. Shown to the contributor in the document |
| `publicUrl` | Required with `published`: the `https://` URL of the post. The contributor gets a *View post* link |

Answers with the submission as in §7.2.

```bash
curl -X POST https://wonky.work/api/pub/v1/submissions/sub_…/status \
  -H "Authorization: Bearer $WONKY_API_KEY" -H "content-type: application/json" \
  -d '{"status":"published","publicUrl":"https://blog.example.com/posts/faster-ci","message":"Live now 🎉"}'
```

### 7.5 Send a message

`POST submissions/{id}/messages` with `{ "body": "Markdown, up to 10,000 characters" }` posts a
message without changing the status, for example "Thanks, we'll look at it this week." Answers
`{ "ok": true }`.

### 7.6 Block a user

`POST blocks` with `{ "wonkyUserId": "0191f0e2-…" }` stops that Wonky account from starting or
submitting stories for your publication. `DELETE blocks/{wonkyUserId}` lifts the block. Both
answer `{ "ok": true }`.

### 7.7 Download an asset

`GET assets/{assetId}` returns the image bytes with its content type (§5).

## 8. Rotate secrets

- **Signing secret**: *Rotate signing secret* shows the new secret once. For the next 24 hours
  every webhook carries two signatures, one per secret, so you can deploy the new secret without
  missing deliveries.
- **API key**: *Rotate API key* shows a new key once, and the old key stops working at once.

## 9. Test your setup

1. Choose **Send test** on the publication page. Your receiver gets a `publication.ping` and the
   page shows your server's answer.
2. Open your contributor link with a second Wonky account, write a few lines, and press
   **Submit**. Check your queue, then call the status API with `changesRequested` and a message,
   and watch it appear in the document.
3. **Deliveries** lists the last 50 webhooks with your server's status code and any error, and
   can resend one.

## 10. Checklist

- [ ] Publication created; signing secret and API key stored server-side.
- [ ] `/.well-known/wonky-publications.json` served and **Verify** passed.
- [ ] *Write for us* link on the blog.
- [ ] Webhook receiver: raw body kept, signature and timestamp checked, `webhook-id` deduplicated,
      queue entry updated by `submission.id`, older `sequence` ignored, `2xx` within 10 seconds.
- [ ] Images downloaded with the API key and hosted by you.
- [ ] Moderation tool links to `documentUrl` and calls the status API for *Request changes*,
      *Decline* and *Publish* (with the post URL).
- [ ] Moderators' emails added to the publication.

## 11. Troubleshooting

| Problem | What to check |
|---------|---------------|
| *Send test* says the address is blocked | The webhook host must resolve to a public address; `localhost`, private networks and non-443 ports are refused. Use a public tunnel while you develop |
| Every delivery fails with a 3xx status | Wonky doesn't follow redirects. Use the final URL (watch for `http`→`https` and trailing-slash redirects) |
| Signatures never match | Sign the **raw** body: frameworks that parse JSON first and serialize it again change the bytes. Decode the secret from base64 after removing `whsec_` |
| Valid signatures are rejected as too old | Your server's clock is off; sync it (NTP) |
| `401 unauthorized` from the API | The key was rotated, or the header isn't exactly `Authorization: Bearer wpk_…` |
| `409 invalidTransition` | The submission isn't in a status you can change (§6.3), for example because the contributor withdrew it |
| Contributors see "not verified" | Serve `/.well-known/wonky-publications.json` on the site URL's host and choose **Verify** again |
