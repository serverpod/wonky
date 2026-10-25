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

Install Flutter, Serverpod, and a frontier coding agent such as Codex, Claude Code, Antigravity,
or Cursor. The [Serverpod installation guide](https://docs.serverpod.dev/installation) covers
Flutter, Dart and what Serverpod needs on your machine. You also need:

- **Flutter** 3.47.5 (stable) or newer. The version CI uses is pinned in
  `.github/workflows/tests.yml`.
- **A frontier coding agent** that reads `AGENTS.md` and can use MCP servers.
- Git and a GitHub account.

## 2. Get the right version of Serverpod

Use Dart's install command to make sure that you are using the right version of Serverpod:

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

Clone your fork to your local machine (replace `<you>` with your GitHub username) and get the
code:

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

## 6. Pick a task

1. Claim a task under [Up for grabs](https://wonky.work/improvements/tasks): on the task page,
   press **Claim this task**. Note your claim code (for example `7Q4F-K2M9`).
2. Start your agent with the `wonky` folder (the repository root) as its working directory.
3. Copy the task's prompt (**Copy prompt**) and give it to your agent. The prompt points the agent
   at `AGENTS.md` and the specs, which are the source of truth. Let the agent do its job.
4. Review what the agent did, run the app, and check the acceptance criteria yourself.

You don't need to start the server yourself: the agent starts it, together with the development
database, through the `serverpod` MCP server, and starts the apps the same way. The repository
configures it, together with the `dart` MCP server and the Flutter and Serverpod skills, for
Claude Code (`.mcp.json`, `.claude/`), Codex (`.codex/`, `.agents/`), Cursor (`.cursor/`) and
Antigravity (`.agents/`). To watch it or start an app by hand, run `serverpod start` in
`wonky_server`; it attaches to the running server. Sign up with any email: in development the
verification code is printed in the server log.

You can **release** a claim at any time if you can't finish. Two active claims per person at a
time.

## 7. Open a pull request

Your agent will help you open a pull request towards
[serverpod/wonky](https://github.com/serverpod/wonky/pulls), from a branch in your fork against
`main`. Before it does, it runs the checklist from `AGENTS.md`: `dart analyze`, `dart format`, and
the tests of the packages you changed. The description must contain exactly one of each line:

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

## 8. Sign the CLA and follow up

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
