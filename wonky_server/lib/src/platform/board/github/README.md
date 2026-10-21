# Bugs & improvements: the GitHub App

The server side of [specs/16 §13](../../../../../../specs/16-bugs-and-improvements.md#13-github-integration):
a GitHub App whose webhooks reach the Wonky server. It gates pull requests on a claimed task
(check **Wonky task**), reviews them against the task (check **Wonky task review**, advisory),
and moves tasks to done and shipped. The integration is off until `wonky: board: github:
enabled` is true.

| File | What |
|------|------|
| `github_webhook.dart` | Signature check, delivery dedupe, the compact payload stored for the handler, `receive` (the route's logic) |
| `../../../web/routes/github_webhook_route.dart` | `POST /api/github/webhook` (Relic route on the web server) |
| `board_github.dart` | Handler of stored deliveries (dispatch, retries), API access, scheduling hooks, the sweep part |
| `board_github_future_call.dart` | `BoardGithubFutureCall.handle(deliveryId)` and `.review(prNumber, headSha)` |
| `github_client.dart` | `GithubApi` (the calls used) and `GithubClient` (REST, installation token cache, rate limits) |
| `github_app_auth.dart` | The RS256 App JWT |
| `github_gate.dart` | Parsing the PR lines, the gate table of §13.4, the bot comment, the label, auto-close |
| `github_review.dart` | Debounce, daily limit, budget postponement, the review comment and check, the stored result |
| `github_review_facts.dart` | Facts computed in code and the filtered, truncated diff |
| `github_review_ai.dart` | `PrReviewer` and its Gemini implementation (tool `report_review`, feature `pr_review` in the board AI ledger) |
| `github_lifecycle.dart` | Merged → done, closed → released, reopened, deploy → shipped |

Tests: `wonky_server/test/integration/platform/board/github/` and `test/unit/board/github/` (fake GitHub API, recorded payload fixtures in
`fixtures/`, a fake reviewer, and the Gemini reviewer on `FakeAiModelClient`).

## Setting up the App (once, by an owner of the `serverpod` organization)

1. **Create the App**: GitHub → `serverpod` organization → *Settings* → *Developer settings* →
   *GitHub Apps* → *New GitHub App*.
   - Name: *Wonky Work bot*. Homepage: `https://wonky.work/improvements`.
   - **Webhook**: active. URL: **`https://wonky.work/api/github/webhook`**.
     The route is on the Serverpod **web server**, which serves `https://wonky.work`
     (`WonkyConfig.webOrigin`). `https://api.wonky.work` is the API server (RPC endpoints
     only) and does not serve web routes. To check after deploying:
     `curl -i -X POST https://wonky.work/api/github/webhook` answers `202` while the integration
     is disabled and `401` (no signature) once it is enabled.
   - **Webhook secret**: a long random string (`openssl rand -hex 32`); keep it for step 3.
   - SSL verification: enabled.
   - **Repository permissions**: *Checks*: read and write. *Pull requests*: read and write
     (comments, labels, closing). *Contents*: read-only (diffs, compare). *Metadata*: read-only
     (mandatory). PR comments and labels go through the issues API, which accepts *Pull
     requests: write* for pull requests, so *Issues* is not needed.
   - **Organization permissions**: *Members*: read-only (the maintainer exemption calls
     `GET /orgs/serverpod/members/{login}`, which answers `204`/`404` with the installation
     token only with this permission).
   - **Subscribe to events**: *Pull request*, *Check run*, *Workflow run*.
   - Where can it be installed: *Only on this account*.
2. **Install it** on the `serverpod` organization with *Only select repositories* →
   `serverpod/wonky`. Note the **App ID** (App settings → *General*), and generate a
   **private key** (*Private keys* → *Generate a private key*; a `.pem` file downloads).
3. **Secrets** (Serverpod Cloud passwords; never in `config/*.yaml` or the repository):

   ```bash
   cd wonky_server
   scloud password set githubAppPrivateKey --from-file ~/Downloads/wonky-work-bot.*.private-key.pem
   scloud password set githubWebhookSecret '<the webhook secret from step 1>'
   ```

   The key may also be pasted as one line with `\n` escapes; the server turns them back into
   line breaks. Locally, put both into `config/passwords.yaml` under `development:` (only to try
   it against a test repository; the App can only reach a public URL, e.g. through a tunnel).
4. **Config** (the environment of the Cloud deployment, since Serverpod Cloud does not upload
   `config/*.yaml`; locally `wonky: board: github:` in `config/development.yaml`):

   ```yaml
   wonky:
     board:
       repository: serverpod/wonky
       github:
         enabled: true
         appId: 123456          # the App ID from step 2
         maintainerOrg: serverpod
         autoCloseDays: 7
         reviewBlocking: false
         reviewsPerPrPerDay: 10
         maxDiffTokens: 400000
         deployWorkflow: deploy.yml
   ```

   Environment equivalents: `WONKY_BOARD_GITHUB_ENABLED=true`, `WONKY_BOARD_GITHUB_APP_ID=123456`
   (and `WONKY_BOARD_GITHUB_<KEY>` for the others). The review also needs the board AI's
   Gemini key (`internalGeminiApiKey`, specs/16 §6.1); without it the review check says
   *Review unavailable*.
5. **Label**: create the label `wonky-task-missing` in the repository (GitHub creates it on
   first use otherwise, without a color or description).
6. **Branch protection** on `main` (*Settings* → *Branches* or a ruleset): *Require status
   checks to pass* → add **`Wonky task`** (source: the *Wonky Work bot* App). It appears in the
   list after the App has reported it once, so open a test PR first. Do **not** require
   *Wonky task review*: it is advisory (G5) and its conclusion is `neutral`.
7. **Check**: open a PR without the lines → the check fails, the bot comments and labels
   it; add `Wonky-Task: T-<n>` and `Wonky-Claim: <code>` of a claimed task → the check passes,
   the comment becomes a one-line confirmation and the task page shows the PR. In the App's
   *Advanced* tab, recent deliveries should show `202` responses.

Rotating the private key: generate a new one, `scloud password set githubAppPrivateKey …`,
redeploy, then delete the old key in the App settings. Rotating the webhook secret: set the new
secret in the App settings and with `scloud password set githubWebhookSecret` at about the same
time (deliveries in between fail with `401` and can be redelivered from the App's *Advanced*
tab).

## How it behaves

- **Webhook**: HMAC-SHA256 over the raw body with `githubWebhookSecret`, compared in constant
  time (`401` otherwise; also `401` while the secret is unset). Duplicate `X-GitHub-Delivery`
  ids are dropped. The route stores only the fields the handler needs (`board_github_delivery.
  payload`, cleared once handled) and answers `202`; `BoardGithubFutureCall.handle` does the
  work, retried twice (1 and 2 minutes later) on errors. Deliveries are purged after 7 days
  by the sweep. While `enabled` is false, every delivery is answered `202` and ignored.
- **Gate** (§13.4): `pull_request` `opened`, `edited`, `reopened`, `synchronize`,
  `ready_for_review`, and *Re-run* of the check (`check_run` `rerequested`; for fork PRs GitHub
  sends no PR number, so the PR is found by its head SHA). The lines are parsed
  case-insensitively, ignoring Markdown (bold, code, quotes, list markers, links) and HTML
  comments (the PR template's hints); a claim code may omit the hyphen, and `O`, `I`, `L` read
  as `0`, `1`, `1`. Exactly one line of each is required (two task lines fail even if equal).
  A task linked to *this* PR by an admin without a claim passes without a code. Draft tasks
  read as *not found*. Every run creates a new check run on the head SHA (the latest one per
  name counts for branch protection). One comment per PR (`<!-- wonky-task-gate -->`, found by
  the stored id or by the marker on bot comments) is updated in place; maintainers get no
  comment unless one exists already. The PR handling of one PR is serialized across instances
  with an advisory lock.
- **Linking**: task → `inReview` with `prNumber`, `pullRequestUrl`, `prAuthorLogin`; the claim
  stops expiring; the login is stored on the claimant's `BoardUserProfile.githubLogin`;
  activity row `prLinked` (body: the PR URL); the claimant gets `boardClaim` (*Your pull request
  #345 is linked to T-12 …*).
- **Auto-close**: the sweep closes open PRs whose gate has failed continuously for
  `autoCloseDays` (from `gateFirstFailedAt`, reset by a passing run and by reopening) with a
  closing comment.
- **Review** (§13.5): scheduled 2 minutes after the gate passes (also maintainer PRs that link a
  task) or a new head commit arrives (`reviewPendingSha`/`reviewDueAt` on the PR row; one future
  call per PR under `board.github.review.<n>`, the superseded one cancelled; a run whose SHA is
  no longer pending or no longer the head does nothing). Draft PRs are not reviewed until they
  are ready. At most `reviewsPerPrPerDay` Gemini calls per PR per UTC day; over the limit or
  over today's Gemini budget the check says *Review postponed …* and the sweep runs it after
  midnight UTC. A failed AI call is retried after 30 minutes. The comment
  (`<!-- wonky-task-review -->`) and the check output escape model text (no HTML, no
  @-mentions, no forged markers). Blocking mode (`reviewBlocking`) fails the check on a
  `notMet` criterion or on unrelated changes over 200 changed lines; otherwise `neutral`.
  The server never checks out, builds or runs PR code: it reads files and the diff through the
  API.
- **Stored result** (`board_pull_request.lastReviewJson`, served as `BoardTaskView.reviewJson`):

  ```json
  {"version": 1, "taskNumber": 12, "sha": "…", "reviewedAt": "2026-10-15T12:00:00.000Z",
   "criteria": [{"criterion": "…", "verdict": "met|partly|notMet|cantTell",
                 "evidence": [{"path": "…", "lines": "10-40"}], "note": "…"}],
   "unrelatedChanges": [{"path": "…", "note": "…"}],
   "tests": {"verdict": "added|missing|notNeeded", "note": "…"},
   "specs": {"verdict": "updated|missing|notNeeded", "note": "…"},
   "risks": [{"kind": "security|dataLoss|migration|dependency|workflow", "path": "…", "note": "…"}],
   "summary": "…", "model": "…",
   "facts": {"files": [{"path", "status", "additions", "deletions"}], "additions": 0, "deletions": 0,
             "testsChanged": true, "specsChanged": false, "pubspecs": [], "dependencyLines": [],
             "migrationsAdded": [], "workflowFiles": [], "sensitiveFiles": []},
   "truncatedFiles": [], "excludedFiles": 0}
  ```
- **Lifecycle** (§13.6): merged → task and posts `done`, `mergeCommitSha`, activity row `done`
  (body: the PR URL), voters get *Built: …*; closed unmerged → task `published`, claim, code
  and PR fields cleared, activity row `prClosed`, the claimant gets *Your PR was closed; T-12
  is open again*; reopened → the gate re-runs (the old code is gone, so the contributor claims
  again). A successful `workflow_run` of `.github/workflows/<deployWorkflow>` ships every
  `done` task with a merge SHA whose compare `merge…deployed head` is `ahead` or `identical`
  (activity row `shipped`, voters get *Shipped: … is now live on wonky.work*).
- **Secrets**: the private key and installation tokens are never logged; `GithubApiException`
  carries only the method, path, status and GitHub's `message`.
