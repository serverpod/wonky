# Contributing to Wonky Work

Wonky Work is built in the open, and most of it is built together with AI coding agents. The
easiest way to help is to pick a **task** from
[Bugs & improvements](https://wonky.work/improvements/tasks) ("Up for grabs"), claim it, and let
your agent build it with the task's prompt.

## How it works

1. Users report bugs and suggest improvements on the in-app board and vote on them.
2. The Serverpod team selects what gets built and turns it into **tasks**. A task is one
   improvement, or a bundle of related small bugs, and comes with a reviewed prompt for a coding
   agent.
3. You **claim** a task on its page. The claim lasts 48 hours and gives you a **claim code**.
4. You build it, usually by pasting the prompt into your coding agent, then review and test the
   result yourself.
5. You open a pull request that names the task and your claim code. Bots check that the PR
   belongs to a claimed task and review it against the task's acceptance criteria.
6. When the PR is merged, the task is done. When it is deployed, everyone who voted for it gets a
   notification.

Pull requests that are not linked to a claimed task are closed after 7 days. If you have an idea,
post it on the board first, where others can vote on it.

## 1. Prerequisites

Follow the [Serverpod installation guide](https://docs.serverpod.dev/installation) to install
Flutter, Dart and what Serverpod needs on your machine. You also need:

- **Flutter** 3.47.5 (stable) or newer. The version CI uses is pinned in
  `.github/workflows/tests.yml`.
- **An AI coding agent.** [Claude Code](https://claude.com/claude-code) is recommended; any agent
  that reads `AGENTS.md` and can use MCP servers works.
- Git and a GitHub account.

## 2. Install the Serverpod CLI

```bash
dart install serverpod_cli 4.1.0-rc.1
```

This installs the CLI, or updates an existing install to the version Wonky Work
needs (the version is `VERSION` in `.github/workflows/tests.yml`). `dart install` puts the
executable in Dart's install directory; add it to your `PATH` if `serverpod` is not found.

## 3. Fork the repository

Fork [serverpod/wonky](https://github.com/serverpod/wonky) on GitHub (**Fork** at the top of the
page). The fork is your own copy: you push your changes to it and open the pull request from it.

## 4. Clone the repository

Clone your fork (replace `<you>` with your GitHub username) and get the packages:

```bash
git clone https://github.com/<you>/wonky.git
cd wonky
flutter pub get
```

## 5. Configure the server

```bash
cd wonky_server
cp config/passwords.example.yaml config/passwords.yaml
```

Its values are development defaults that work as they are (they are not secrets; never reuse them
elsewhere). AI keys are optional: without them, the in-app assistant asks each user for their own
key, and the board skips its AI checks.

## 6. Run Wonky Work

```bash
serverpod start
```

Run it in `wonky_server`. It starts the development database, the server, applies migrations, watches for changes and hot
reloads. The apps are started on demand from its UI, or by your agent through the `serverpod` MCP
server. The repository configures it, together with the `dart` MCP server and the Flutter and
Serverpod skills, for Claude Code (`.mcp.json`, `.claude/`), Codex (`.codex/`, `.agents/`), Cursor
(`.cursor/`) and Antigravity (`.agents/`).
The apps run at http://localhost:8082/drive/ (and `/write/`, `/sheets/`, `/slides/`) once built,
or on their own dev ports when started from `serverpod start`.

Sign up with any email: in development the verification code is printed in the server log.

## 7. Build the task

1. On the task page, press **Claim this task**. Note your claim code (for example `7Q4F-K2M9`).
2. Create a branch in your fork.
3. Copy the task's prompt (**Copy prompt**) and give it to your agent. The prompt points the agent
   at `AGENTS.md` and the specs, which are the source of truth.
4. Review what the agent did, run the app, and check the acceptance criteria yourself.
5. Run the checklist from `AGENTS.md`: `dart analyze`, `dart format`, and the tests of the
   packages you changed.

You can **release** a claim at any time if you can't finish. Two active claims per person at a
time.

## 8. Open the pull request

Open it against `main`. The description must contain exactly one of each line:

```
Wonky-Task: T-12
Wonky-Claim: 7Q4F-K2M9
```

Add a short summary of how each acceptance criterion is met (the PR template has the sections).

- **One task per PR.** A task can bundle several bugs; it is still one PR.
- The check **Wonky task** verifies the task and the claim code. Once it passes, your claim no
  longer expires while the PR is open.
- The check **Wonky task review** posts an AI review against the acceptance criteria. It is
  advisory; maintainers make the call.
- The normal CI (analyze, format, tests) must pass.

## 9. Sign the CLA and follow up

If you haven't signed the Serverpod Contributor License Agreement (CLA) yet, sign it on GitHub:
the CLA Assistant bot comments on your pull request, and you reply with the line from
[License and CLA](#license-and-cla). You sign it once.

Then check back once your pull request has been reviewed: fix the issues the review points out
and push to the same branch, which updates the pull request.

## License and CLA

Wonky Work is licensed under the [BSD 3-Clause License](LICENSE). Before your first pull request
can be merged, you sign the [Serverpod Contributor License Agreement](CLA.md), the same one the
[Serverpod](https://github.com/serverpod/serverpod) project uses. The CLA Assistant bot comments
on your pull request; reply with:

```
I have read the CLA Document and I hereby sign the CLA
```

You sign once: the signature covers your later pull requests, here and in other Serverpod projects.

## Security issues

Never report a vulnerability on the board or in a PR. Email **security@serverpod.dev** instead;
see [SECURITY.md](SECURITY.md).
