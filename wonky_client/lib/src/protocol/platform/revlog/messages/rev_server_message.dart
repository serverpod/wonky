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
import 'dart:typed_data' as _idt;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:wonky_client/src/protocol/protocol.dart' as _i8pkqg1o;
import '../../../protocol.dart' as _i26f4ubs;
import '../../common/access_role.dart' as _iyf5alod;
import '../models/rev_op_view.dart' as _irs0bkik;
import '../models/rev_reject_code.dart' as _ibphbk3y;
part 'rev_ack.dart';
part 'rev_init.dart';
part 'rev_pong.dart';
part 'rev_rejected.dart';
part 'rev_remote_op.dart';
part 'rev_resync.dart';
part 'rev_role_changed.dart';

/// Server → client messages of `<app>Doc.connect` (RevLog spec 04 §2.2).
sealed class RevServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RevServerMessage();

  /// Returns a shallow copy of this [RevServerMessage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  RevServerMessage copyWith();
}

class _Undefined {}
