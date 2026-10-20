/// Test helpers for the shell and the apps (suite 15 §2, §5): in-memory
/// repositories and a [CommandTestHarness] that runs commands through the
/// real dispatcher and undo service. Never import from `lib/` code.
library;

// Typing into Markdown composers (`MarkdownComposer`, specs/16 §7.3).
export 'package:wonky_rich_editor/testing.dart'
    show
        enterMarkdown,
        richEditorStateOf,
        richTextCenter,
        selectRichText,
        typeMarkdown;

export 'src/assistant/fake_assistant_api.dart';
export 'src/testing/command_sweep.dart';
export 'src/testing/command_test_harness.dart';
export 'src/testing/fake_board_repository.dart';
export 'src/testing/fake_cross_app.dart';
export 'src/testing/fake_publication_repository.dart';
export 'src/testing/fake_storage.dart';
export 'src/testing/fake_repositories.dart'
    hide
        UnfakedCommentRepository,
        UnfakedFileRepository,
        UnfakedMetaRepository,
        UnfakedNotificationRepository,
        UnfakedPresenceRepository,
        UnfakedSharingRepository,
        UnfakedVersionRepository;
