import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../../l10n/wonky_app_localizations.dart';
import '../../shell/dialogs.dart';
import '../../shell/page_frame.dart';
import '../../shell/shell_services.dart';
import '../board_hub.dart';
import 'board_trail.dart';
import 'board_widgets.dart';

/// The repository the board's PRs go to (`BoardMe.repository`).
String boardRepository(ShellServices s) =>
    BoardHub.of(s).me.value?.repository ?? 'serverpod/wonky';

/// The Serverpod CLI version of `CONTRIBUTING.md` step 2 (the `VERSION` in
/// `.github/workflows/tests.yml`).
const boardServerpodCliVersion = '4.1.0-beta.3';

/// Serverpod's installation guide (Flutter, Dart and the Serverpod CLI):
/// the first setup step of `CONTRIBUTING.md` (specs/16 §10.3).
const boardServerpodInstallUrl = 'https://docs.serverpod.dev/installation';

/// The line that signs the Serverpod CLA in a reply to the CLA Assistant
/// bot (`CONTRIBUTING.md`, *License and CLA*).
const boardClaSignLine =
    'I have read the CLA Document and I hereby sign the CLA';

/// The setup commands of `CONTRIBUTING.md` after the tools are installed
/// (specs/16 §10.3), one per copy button: install (or update) the CLI,
/// clone your fork of [repository] and get the packages, configure the
/// server, run it. Forking has no command: it is done on GitHub. Serverpod starts the development database itself, so
/// there is no Docker step.
List<String> boardSetupCommands(String repository) {
  final name = repository.split('/').last;
  return [
    'dart install serverpod_cli $boardServerpodCliVersion',
    'git clone https://github.com/<you>/$name.git',
    'cd $name && flutter pub get',
    'cd wonky_server',
    'cp config/passwords.example.yaml config/passwords.yaml',
    'serverpod start',
  ];
}

/// *Install Flutter, Dart and the Serverpod CLI: Serverpod installation
/// guide* — the first setup step, a link to [boardServerpodInstallUrl]
/// through the external-link confirmation.
class BoardInstallGuideLink extends StatelessWidget {
  const BoardInstallGuideLink({
    super.key,
    required this.services,
    required this.linkKey,
  });

  final ShellServices services;
  final String linkKey;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        Text(l.boardInstallTools, style: theme.textTheme.small),
        BoardTextLink(
          key: ValueKey<String>(linkKey),
          label: l.boardInstallGuide,
          external: true,
          onTap: () => confirmExternalLink(
            context,
            services,
            url: boardServerpodInstallUrl,
          ),
        ),
      ],
    );
  }
}

/// `/improvements/contribute` (specs/16 §10.3): the short version of
/// `CONTRIBUTING.md` (steps 1–9) as app strings, so it works without
/// GitHub, with copy buttons and a link to the full guide.
class BoardContributePage extends StatefulWidget {
  const BoardContributePage({super.key, required this.services});

  final ShellServices services;

  @override
  State<BoardContributePage> createState() => _BoardContributePageState();
}

class _BoardContributePageState extends State<BoardContributePage> {
  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    BoardHub.of(s).me.addListener(_onMe);
    unawaited(BoardHub.of(s).loadMe());
  }

  @override
  void dispose() {
    BoardHub.of(s).me.removeListener(_onMe);
    super.dispose();
  }

  void _onMe() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final repo = boardRepository(s);
    final cmds = boardSetupCommands(repo);
    final security =
        BoardHub.of(s).me.value?.securityContact ?? 'security@serverpod.dev';
    Widget step(
      int n,
      String title,
      String text, [
      List<Widget> more = const [],
    ]) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.muted,
              shape: BoxShape.circle,
            ),
            child: Text('$n', style: theme.textTheme.small),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.p.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(text, style: theme.textTheme.muted),
                ...more,
              ],
            ),
          ),
        ],
      ),
    );
    return BoardFrame(
      services: s,
      trail: const BoardTrail(contribute: true),
      child: ShellPageBody(
        key: const ValueKey<String>('board.contribute'),
        children: [
          Text(l.boardContributeIntro, style: theme.textTheme.p),
          const SizedBox(height: 20),
          step(1, l.boardContribStep1Title, l.boardContribStep1, [
            BoardInstallGuideLink(
              services: s,
              linkKey: 'board.contribute.installGuide',
            ),
          ]),
          step(2, l.boardContribStep2Title, l.boardContribStep2, [
            BoardCopyLine(text: cmds[0], copyKey: 'board.contribute.copy.0'),
          ]),
          step(3, l.boardContribStep3Title, l.boardContribStep3, [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BoardTextLink(
                key: const ValueKey<String>('board.contribute.fork'),
                label: l.boardContribForkLink,
                external: true,
                onTap: () => confirmExternalLink(
                  context,
                  s,
                  url: 'https://github.com/$repo/fork',
                ),
              ),
            ),
          ]),
          step(4, l.boardContribStep4Title, l.boardContribStep4, [
            for (final i in const [1, 2])
              BoardCopyLine(text: cmds[i], copyKey: 'board.contribute.copy.$i'),
          ]),
          step(5, l.boardContribStep5Title, l.boardContribStep5, [
            for (final i in const [3, 4])
              BoardCopyLine(text: cmds[i], copyKey: 'board.contribute.copy.$i'),
          ]),
          step(6, l.boardContribStep6Title, l.boardContribStep6, [
            BoardCopyLine(text: cmds[5], copyKey: 'board.contribute.copy.5'),
          ]),
          step(7, l.boardContribStep7Title, l.boardContribStep7, [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ShadButton.outline(
                key: const ValueKey<String>('board.contribute.tasks'),
                size: ShadButtonSize.sm,
                onPressed: () => boardOpenList(s, BoardTab.tasks),
                child: Text(l.boardTabTasks),
              ),
            ),
          ]),
          step(8, l.boardContribStep8Title, l.boardContribStep8, [
            const BoardCopyLine(
              text: 'Wonky-Task: T-12\nWonky-Claim: XXXX-XXXX',
              copyKey: 'board.contribute.copy.prLines',
            ),
          ]),
          step(9, l.boardContribStep9Title, l.boardContribStep9, [
            const BoardCopyLine(
              text: boardClaSignLine,
              copyKey: 'board.contribute.copy.cla',
            ),
          ]),
          Text(l.boardContribLicense, style: theme.textTheme.muted),
          const SizedBox(height: 8),
          Text(l.boardContribSecurity(security), style: theme.textTheme.muted),
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ShadButton(
              key: const ValueKey<String>('board.contribute.guide'),
              leading: const Icon(LucideIcons.bookOpen, size: 16),
              onPressed: () => confirmExternalLink(
                context,
                s,
                url: 'https://github.com/$repo/blob/main/CONTRIBUTING.md',
              ),
              child: Text(l.boardContributeGuide),
            ),
          ),
        ],
      ),
    );
  }
}
