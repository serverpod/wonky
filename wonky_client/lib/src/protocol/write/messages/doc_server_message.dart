/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:wonky_client/src/protocol/protocol.dart' as _i8pkqg1o;
import '../../platform/common/access_role.dart' as _iv7g6vuy;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../platform/presence/participant.dart' as _iekwkhcm;
import '../../protocol.dart' as _iototaiw;
import '../models/doc_reject_code.dart' as _i9a4p9z2;
import '../models/document_meta_view.dart' as _i7zr8tvm;
import '../models/document_op_kind.dart' as _idnphvog;
import '../models/document_op_view.dart' as _ix78fzvl;
part 'doc_ack.dart';
part 'doc_hash_result.dart';
part 'doc_init.dart';
part 'doc_meta_changed.dart';
part 'doc_op_rejected.dart';
part 'doc_participant_joined.dart';
part 'doc_participant_left.dart';
part 'doc_pong.dart';
part 'doc_remote_cursor.dart';
part 'doc_remote_op.dart';
part 'doc_role_changed.dart';

/// Server → client messages of `document.connect` (Write 03 §1.2).
sealed class DocServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DocServerMessage();

  /// Returns a shallow copy of this [DocServerMessage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DocServerMessage copyWith();
}

class _Undefined {}
