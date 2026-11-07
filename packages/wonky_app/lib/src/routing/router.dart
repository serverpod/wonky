import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../auth/screens/auth_layout.dart' show safeAuthNext;
import '../board/pages/board_routes.dart';
import '../board/pages/board_trail.dart' show isBoardLocation;
import '../config/home_scope.dart';
import '../auth/screens/reset_password_screen.dart';
import '../auth/screens/sign_in_screen.dart';
import '../auth/screens/sign_up_screen.dart';
import '../auth/screens/verify_email_screen.dart';
import '../drive/drive_location.dart';
import '../drive/home_screen.dart';
import '../drive/template_gallery.dart';
import '../settings/settings_routes.dart';
import '../shell/shell_services.dart';
import '../versions/version_history_screen.dart';
import 'item_routes.dart';
import 'misc_pages.dart';

const _authPaths = {'/signin', '/signup', '/signup/verify', '/reset'};

/// The suite routes of 03 §2 plus the app's routes. Paths are relative to
/// the app's base href.
GoRouter buildShellRouter(ShellServices s) {
  final myFiles = s.config.homeNav.myFilesRoute;
  final prefix = s.config.itemPath('x').replaceFirst(RegExp(r'x$'), '');
  final base = prefix.endsWith('/')
      ? prefix.substring(0, prefix.length - 1)
      : prefix;
  Page<void> page(GoRouterState state, Widget child) =>
      NoTransitionPage<void>(key: state.pageKey, child: child);
  // Exactly `$base/<uuid>` (not `history`, `print`, …): the editor route
  // guests may open in apps that allow it (specs/06 §2.4).
  final guestEditor = RegExp('^${RegExp.escape(base)}/[^/]+\$');
  bool isGuestLocation(String path) =>
      s.config.allowsGuestViewing && guestEditor.hasMatch(path);

  return GoRouter(
    navigatorKey: s.navigatorKey,
    refreshListenable: s.auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final status = s.auth.status;
      final isAuth = _authPaths.contains(path);
      if (status == AuthStatus.sessionExpired) {
        return null; // dialog over the screen
      }
      if (status == AuthStatus.signedOut) {
        // Bugs & improvements is public (specs/16 §4.3); link-shared items
        // open view-only (specs/06 §2.4).
        if (isAuth || isBoardLocation(path) || isGuestLocation(path)) {
          return null;
        }
        final next = state.uri.toString();
        return next == '/'
            ? '/signin'
            : '/signin?next=${Uri.encodeQueryComponent(next)}';
      }
      if (isAuth) {
        return safeAuthNext(state.uri.queryParameters['next']) ?? '/';
      }
      if (path == '/settings') return '/settings/account';
      return null;
    },
    errorPageBuilder: (context, state) =>
        page(state, NotFoundPage(services: s)),
    routes: [
      GoRoute(
        path: '/signin',
        pageBuilder: (c, st) => page(st, SignInScreen(services: s)),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (c, st) => page(st, SignUpScreen(services: s)),
      ),
      GoRoute(
        path: '/signup/verify',
        pageBuilder: (c, st) => page(st, VerifyEmailScreen(services: s)),
      ),
      GoRoute(
        path: '/reset',
        pageBuilder: (c, st) => page(st, ResetPasswordScreen(services: s)),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (c, st) => page(
          st,
          DriveHomeScreen(services: s, location: const DriveLocation.home()),
        ),
      ),
      GoRoute(
        path: '/f/:folderUuid',
        pageBuilder: (c, st) => page(
          st,
          DriveHomeScreen(
            services: s,
            location: DriveLocation.folder(st.pathParameters['folderUuid']!),
          ),
        ),
      ),
      // v1 folder links (bookmarks, emails, MCP results) → `/f/:uuid`.
      GoRoute(
        path: '/drive/:folderUuid',
        redirect: (c, st) => '/f/${st.pathParameters['folderUuid']}',
      ),
      // The drive root: `/my-files` in app homes, `/my-drive` in Drive and
      // v1 homes; the other path redirects (suite 03 §2).
      for (final path in const ['/my-files', '/my-drive'])
        GoRoute(
          path: path,
          redirect: (c, st) =>
              path == myFiles ? null : _withQuery(myFiles, st.uri),
          pageBuilder: (c, st) => page(
            st,
            DriveHomeScreen(
              services: s,
              location: const DriveLocation.myDrive(),
            ),
          ),
        ),
      for (final (path, loc) in [
        ('/shared', const DriveLocation.shared()),
        ('/starred', const DriveLocation.starred()),
        ('/recent', const DriveLocation.recent()),
        ('/offline', const DriveLocation.offline()),
        ('/trash', const DriveLocation.trash()),
      ])
        GoRoute(
          path: path,
          pageBuilder: (c, st) =>
              page(st, DriveHomeScreen(services: s, location: loc)),
        ),
      GoRoute(
        path: '/search',
        pageBuilder: (c, st) => page(
          st,
          DriveHomeScreen(
            services: s,
            location: DriveLocation.search(st.uri.queryParameters['q'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/templates',
        pageBuilder: (c, st) => page(st, TemplateGalleryScreen(services: s)),
      ),
      if (s.config.newItemRoute case final handler?)
        GoRoute(
          path: '/new',
          pageBuilder: (c, st) => page(
            st,
            NewItemRoutePage(
              services: s,
              handler: handler,
              request: NewItemRequest.fromQuery(st.uri.queryParameters),
            ),
          ),
        ),
      if (s.config.importRoute case final handler?)
        GoRoute(
          path: '/import',
          pageBuilder: (c, st) => page(
            st,
            ImportRoutePage(
              services: s,
              handler: handler,
              request: ImportRouteRequest.fromQuery(st.uri.queryParameters),
            ),
          ),
        ),
      // Settings: app settings + Wonky Work settings (suite 04 §4).
      ...settingsRoutes(s, page),
      // Bugs & improvements (specs/16 §4.3).
      ...boardRoutes(s, page),
      GoRoute(
        path: '/invite/:token',
        pageBuilder: (c, st) => page(
          st,
          InvitePage(services: s, token: st.pathParameters['token']!),
        ),
      ),
      GoRoute(
        path: '/no-access',
        pageBuilder: (c, st) => page(
          st,
          NoAccessPage(services: s, itemUuid: st.uri.queryParameters['item']),
        ),
      ),
      GoRoute(
        path: '$base/:uuid',
        pageBuilder: (c, st) => page(
          st,
          // A fresh editor when the user signs in or out on the page (a
          // guest's view-only session becomes the signed-in one).
          KeyedSubtree(
            key: ValueKey<bool>(s.isGuest),
            child: s.config.buildEditor(c, st, st.pathParameters['uuid']!),
          ),
        ),
        routes: [
          if (s.config.versionRenderer != null)
            GoRoute(
              path: 'history',
              pageBuilder: (c, st) => page(
                st,
                VersionHistoryScreen(
                  services: s,
                  itemUuid: st.pathParameters['uuid']!,
                  initialVersionId: int.tryParse(
                    st.uri.queryParameters['version'] ?? '',
                  ),
                ),
              ),
            ),
          ...s.config.editorRoutes(s),
        ],
      ),
      ...s.config.routes(s),
    ],
  );
}

String _withQuery(String path, Uri uri) =>
    uri.hasQuery ? '$path?${uri.query}' : path;
