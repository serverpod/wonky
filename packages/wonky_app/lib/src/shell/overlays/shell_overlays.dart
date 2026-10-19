import 'package:flutter/widgets.dart';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../bootstrap/platform.dart';

import '../../auth/auth_controller.dart';
import '../../auth/screens/session_expired_dialog.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../shell_services.dart';
import '../../board/report/board_report_services.dart';

/// Global overlays (suite 03 §4): offline banner, session-expired dialog,
/// version mismatch toast, MCP control pill and the error boundary.
class ShellOverlays extends StatefulWidget {
  const ShellOverlays({
    super.key,
    required this.services,
    required this.ready,
    required this.child,
  });

  final ShellServices services;
  final bool ready;
  final Widget child;

  @override
  State<ShellOverlays> createState() => _ShellOverlaysState();
}

class _ShellOverlaysState extends State<ShellOverlays> {
  ShellServices get s => widget.services;
  bool _expiredShown = false;
  bool _versionToastShown = false;

  @override
  void initState() {
    super.initState();
    s.auth.addListener(_onAuth);
    s.serverInfo.addListener(_onServerInfo);
    installErrorBoundary(s);
  }

  @override
  void dispose() {
    s.auth.removeListener(_onAuth);
    s.serverInfo.removeListener(_onServerInfo);
    super.dispose();
  }

  void _onAuth() {
    if (s.auth.status == AuthStatus.sessionExpired && !_expiredShown) {
      _expiredShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final c = s.navigatorContext;
        if (c == null) return;
        await showSessionExpiredDialog(c, s);
        _expiredShown = false;
      });
    }
  }

  void _onServerInfo() {
    final info = s.serverInfo.value;
    if (info == null || _versionToastShown) return;
    if (compareVersions(info.minClientVersion, clientVersion) > 0) {
      _versionToastShown = true;
      final l = s.l10n;
      s.toasts.show(
        l?.versionNewAvailable ?? 'A new version is available',
        actionLabel: l?.actionReload,
        onAction: s.crossApp.reload,
        duration: const Duration(minutes: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (!widget.ready) {
      return ColoredBox(
        color: theme.colorScheme.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              s.config.logo(size: 48),
              const SizedBox(height: 16),
              const ShadSpinner(),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        Column(
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([s.connectivity, s.auth]),
              builder: (context, _) =>
                  !s.connectivity.online && s.auth.isSignedIn
                  ? OfflineBanner(services: s)
                  : const SizedBox.shrink(),
            ),
            Expanded(child: widget.child),
          ],
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: ListenableBuilder(
            listenable: s.mcp,
            builder: (context, _) => s.mcp.controlling
                ? McpControlPill(services: s)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// The app version compared with `ProtocolInfo.minClientVersion`.
const clientVersion = String.fromEnvironment(
  'WONKY_VERSION',
  defaultValue: '3.0.0',
);

/// Compares dotted versions (`1.2.10` > `1.2.9`).
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.split(RegExp(r'[.+-]'))) int.tryParse(p) ?? 0,
  ];
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// "You're offline…" banner.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final fg = theme.colorScheme.offlineForeground;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey<String>('shell.offlineBanner'),
        width: double.infinity,
        color: theme.colorScheme.offline,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(LucideIcons.cloudOff, size: 16, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.offlineBanner,
                style: theme.textTheme.small.copyWith(
                  color: fg,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            // A ghost button tinted with the banner's own colors (the link
            // style's hover switched to the theme's link colors).
            ShadButton.ghost(
              key: const ValueKey<String>('shell.offlineBanner.retry'),
              size: ShadButtonSize.sm,
              height: 26,
              foregroundColor: fg,
              hoverForegroundColor: fg,
              pressedForegroundColor: fg,
              hoverBackgroundColor: fg.withValues(alpha: 0.12),
              pressedBackgroundColor: fg.withValues(alpha: 0.2),
              onPressed: services.connectivity.reconnect,
              child: Text(l.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// "🤖 Agent is controlling this window — Stop".
class McpControlPill extends StatelessWidget {
  const McpControlPill({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey<String>('shell.mcpPill'),
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.foreground,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bot,
              size: 16,
              color: theme.colorScheme.background,
            ),
            const SizedBox(width: 8),
            Text(
              l.mcpControlling,
              style: TextStyle(
                color: theme.colorScheme.background,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            ShadButton.secondary(
              size: ShadButtonSize.sm,
              onPressed: services.mcp.stop,
              child: Text(l.actionStop),
            ),
          ],
        ),
      ),
    );
  }
}

/// Installs the global error boundary: errors are reported to the server
/// log (`feedback.reportError`, private telemetry), remembered as the last
/// error for the report dialog (specs/16 §4.2.4) and failed widgets render
/// a recoverable "Something went wrong" card.
void installErrorBoundary(ShellServices s) {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    previous?.call(details);
    BoardReportServices.of(
      s,
    ).recordError(details.exceptionAsString(), details.stack);
    _report(s, details.exceptionAsString(), details.stack);
  };
  ErrorWidget.builder = (details) => ErrorCard(details: details, services: s);
}

DateTime? _lastReport;

void _report(ShellServices s, String error, StackTrace? stack) {
  final now = DateTime.now();
  if (_lastReport != null &&
      now.difference(_lastReport!) < const Duration(seconds: 5)) {
    return;
  }
  _lastReport = now;
  final client = s.client;
  if (client == null) return;
  unawaited(
    client.feedback
        .reportError(
          FeedbackSubmission(
            kind: FeedbackKind.errorReport,
            message: error.length > 4000 ? error.substring(0, 4000) : error,
            app: s.config.app.name,
            appVersion: clientVersion,
            platform: platformLabel,
            route: s.router.state.uri.toString(),
            stackTrace: stack?.toString(),
          ),
        )
        .catchError((Object _) {}),
  );
}

/// "Something went wrong" card with *Copy error details*, *Report this bug*
/// (the report dialog with kind Bug and this error attached, specs/16
/// §4.1) and *Reload*.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.details, required this.services});

  final FlutterErrorDetails details;
  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final l = Localizations.of<WonkyAppLocalizations>(
      context,
      WonkyAppLocalizations,
    );
    final theme = ShadTheme.maybeOf(context);
    if (theme == null || l == null) {
      return const ColoredBox(color: Color(0x22ff0000));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ShadCard(
          title: Text(l.errorBoundaryTitle),
          description: Text(l.errorBoundaryBody),
          footer: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton.outline(
                onPressed: () => Clipboard.setData(
                  ClipboardData(
                    text: '${details.exceptionAsString()}\n${details.stack}',
                  ),
                ),
                child: Text(l.errorCopyDetails),
              ),
              ShadButton.outline(
                key: const ValueKey<String>('error.reportBug'),
                onPressed: () {
                  BoardReportServices.of(
                    services,
                  ).recordError(details.exceptionAsString(), details.stack);
                  services.dispatcher.invoke(
                    'shell.board.report',
                    args: const {'kind': 'bug', 'includeError': true},
                    context: context,
                  );
                },
                child: Text(l.errorReportBug),
              ),
              ShadButton(
                onPressed: () {
                  final r = services.router;
                  r.go(r.state.uri.toString());
                },
                child: Text(l.actionReload),
              ),
            ],
          ),
          child: const SizedBox(height: 8),
        ),
      ),
    );
  }
}
