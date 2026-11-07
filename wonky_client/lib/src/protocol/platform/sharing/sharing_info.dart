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
import '../../platform/drive/drive_item_kind.dart' as _i26ubj99;
import '../../platform/sharing/access_request_view.dart' as _itmxnxi6;
import '../../platform/sharing/general_access.dart' as _ijt0as3o;
import '../../platform/sharing/item_sharing_settings.dart' as _iz7k30fg;
import '../../platform/sharing/org_access_view.dart' as _ir3h02o5;
import '../../platform/sharing/ownership_transfer_view.dart' as _irnzbqjz;
import '../../platform/sharing/permission_view.dart' as _im2pznpj;
import '../../platform/sharing/share_link_view.dart' as _impi727v;
import '../../platform/users/user_summary.dart' as _itg9e9ms;

/// Everything the share dialog shows (`sharing.getSharing`).
abstract class SharingInfo
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  SharingInfo._({
    required this.itemUuid,
    required this.itemName,
    required this.itemKind,
    required this.owner,
    required this.myRole,
    required this.canShare,
    required this.permissions,
    this.link,
    this.organization,
    this.orgAccess,
    this.inheritedOrgAccess,
    required this.generalAccess,
    required this.settings,
    required this.pendingRequests,
    this.pendingTransfer,
  });

  factory SharingInfo({
    required _isc.UuidValue itemUuid,
    required String itemName,
    required _i26ubj99.DriveItemKind itemKind,
    required _itg9e9ms.UserSummary owner,
    required _iv7g6vuy.AccessRole myRole,
    required bool canShare,
    required List<_im2pznpj.PermissionView> permissions,
    _impi727v.ShareLinkView? link,
    String? organization,
    _ir3h02o5.OrgAccessView? orgAccess,
    _ir3h02o5.OrgAccessView? inheritedOrgAccess,
    required _ijt0as3o.GeneralAccess generalAccess,
    required _iz7k30fg.ItemSharingSettings settings,
    required List<_itmxnxi6.AccessRequestView> pendingRequests,
    _irnzbqjz.OwnershipTransferView? pendingTransfer,
  }) = _SharingInfoImpl;

  factory SharingInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return SharingInfo(
      itemUuid: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['itemUuid'],
      ),
      itemName: jsonSerialization['itemName'] as String,
      itemKind: _i26ubj99.DriveItemKind.fromJson(
        (jsonSerialization['itemKind'] as String),
      ),
      owner: _i8pkqg1o.Protocol().deserialize<_itg9e9ms.UserSummary>(
        jsonSerialization['owner'],
      ),
      myRole: _iv7g6vuy.AccessRole.fromJson(
        (jsonSerialization['myRole'] as String),
      ),
      canShare: _isc.BoolJsonExtension.fromJson(jsonSerialization['canShare']),
      permissions: _i8pkqg1o.Protocol()
          .deserialize<List<_im2pznpj.PermissionView>>(
            jsonSerialization['permissions'],
          ),
      link: jsonSerialization['link'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<_impi727v.ShareLinkView>(
              jsonSerialization['link'],
            ),
      organization: jsonSerialization['organization'] as String?,
      orgAccess: jsonSerialization['orgAccess'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<_ir3h02o5.OrgAccessView>(
              jsonSerialization['orgAccess'],
            ),
      inheritedOrgAccess: jsonSerialization['inheritedOrgAccess'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<_ir3h02o5.OrgAccessView>(
              jsonSerialization['inheritedOrgAccess'],
            ),
      generalAccess: _ijt0as3o.GeneralAccess.fromJson(
        (jsonSerialization['generalAccess'] as String),
      ),
      settings: _i8pkqg1o.Protocol().deserialize<_iz7k30fg.ItemSharingSettings>(
        jsonSerialization['settings'],
      ),
      pendingRequests: _i8pkqg1o.Protocol()
          .deserialize<List<_itmxnxi6.AccessRequestView>>(
            jsonSerialization['pendingRequests'],
          ),
      pendingTransfer: jsonSerialization['pendingTransfer'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<_irnzbqjz.OwnershipTransferView>(
              jsonSerialization['pendingTransfer'],
            ),
    );
  }

  _isc.UuidValue itemUuid;

  String itemName;

  _i26ubj99.DriveItemKind itemKind;

  _itg9e9ms.UserSummary owner;

  _iv7g6vuy.AccessRole myRole;

  /// Whether the caller may add people and change roles.
  bool canShare;

  List<_im2pznpj.PermissionView> permissions;

  /// Null when the caller may not see the link (viewers/commenters).
  _impi727v.ShareLinkView? link;

  /// (Organizations) The caller's organization (its first domain), null
  /// without one; the dialog offers "Anyone at <domain>" only with it or
  /// an existing organization grant (specs/06 §2.3).
  String? organization;

  /// The organization grant set on this item, if any.
  _ir3h02o5.OrgAccessView? orgAccess;

  /// The highest organization grant inherited from a folder, if any.
  _ir3h02o5.OrgAccessView? inheritedOrgAccess;

  /// Restricted, organization (orgAccess) or link (link.role).
  _ijt0as3o.GeneralAccess generalAccess;

  _iz7k30fg.ItemSharingSettings settings;

  /// Only for callers who can share.
  List<_itmxnxi6.AccessRequestView> pendingRequests;

  _irnzbqjz.OwnershipTransferView? pendingTransfer;

  /// Returns a shallow copy of this [SharingInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  SharingInfo copyWith({
    _isc.UuidValue? itemUuid,
    String? itemName,
    _i26ubj99.DriveItemKind? itemKind,
    _itg9e9ms.UserSummary? owner,
    _iv7g6vuy.AccessRole? myRole,
    bool? canShare,
    List<_im2pznpj.PermissionView>? permissions,
    _impi727v.ShareLinkView? link = const _UndefinedSharingInfo$link(),
    String? organization,
    _ir3h02o5.OrgAccessView? orgAccess =
        const _UndefinedSharingInfo$orgAccess(),
    _ir3h02o5.OrgAccessView? inheritedOrgAccess =
        const _UndefinedSharingInfo$orgAccess(),
    _ijt0as3o.GeneralAccess? generalAccess,
    _iz7k30fg.ItemSharingSettings? settings,
    List<_itmxnxi6.AccessRequestView>? pendingRequests,
    _irnzbqjz.OwnershipTransferView? pendingTransfer =
        const _UndefinedSharingInfo$pendingTransfer(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SharingInfo',
      'itemUuid': itemUuid.toJson(),
      'itemName': itemName,
      'itemKind': itemKind.toJson(),
      'owner': owner.toJson(),
      'myRole': myRole.toJson(),
      'canShare': canShare,
      'permissions': permissions.toJson(valueToJson: (v) => v.toJson()),
      if (link != null) 'link': link?.toJson(),
      if (organization != null) 'organization': organization,
      if (orgAccess != null) 'orgAccess': orgAccess?.toJson(),
      if (inheritedOrgAccess != null)
        'inheritedOrgAccess': inheritedOrgAccess?.toJson(),
      'generalAccess': generalAccess.toJson(),
      'settings': settings.toJson(),
      'pendingRequests': pendingRequests.toJson(valueToJson: (v) => v.toJson()),
      if (pendingTransfer != null) 'pendingTransfer': pendingTransfer?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SharingInfo',
      'itemUuid': itemUuid.toJson(),
      'itemName': itemName,
      'itemKind': itemKind.toJson(),
      'owner': owner.toJsonForProtocol(),
      'myRole': myRole.toJson(),
      'canShare': canShare,
      'permissions': permissions.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (link != null) 'link': link?.toJsonForProtocol(),
      if (organization != null) 'organization': organization,
      if (orgAccess != null) 'orgAccess': orgAccess?.toJsonForProtocol(),
      if (inheritedOrgAccess != null)
        'inheritedOrgAccess': inheritedOrgAccess?.toJsonForProtocol(),
      'generalAccess': generalAccess.toJson(),
      'settings': settings.toJsonForProtocol(),
      'pendingRequests': pendingRequests.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (pendingTransfer != null)
        'pendingTransfer': pendingTransfer?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSharingInfo$link extends _isc.UndefinedSentinel
    implements _impi727v.ShareLinkView {
  const _UndefinedSharingInfo$link();
}

class _UndefinedSharingInfo$orgAccess extends _isc.UndefinedSentinel
    implements _ir3h02o5.OrgAccessView {
  const _UndefinedSharingInfo$orgAccess();
}

class _UndefinedSharingInfo$pendingTransfer extends _isc.UndefinedSentinel
    implements _irnzbqjz.OwnershipTransferView {
  const _UndefinedSharingInfo$pendingTransfer();
}

class _SharingInfoImpl extends SharingInfo {
  _SharingInfoImpl({
    required _isc.UuidValue itemUuid,
    required String itemName,
    required _i26ubj99.DriveItemKind itemKind,
    required _itg9e9ms.UserSummary owner,
    required _iv7g6vuy.AccessRole myRole,
    required bool canShare,
    required List<_im2pznpj.PermissionView> permissions,
    _impi727v.ShareLinkView? link,
    String? organization,
    _ir3h02o5.OrgAccessView? orgAccess,
    _ir3h02o5.OrgAccessView? inheritedOrgAccess,
    required _ijt0as3o.GeneralAccess generalAccess,
    required _iz7k30fg.ItemSharingSettings settings,
    required List<_itmxnxi6.AccessRequestView> pendingRequests,
    _irnzbqjz.OwnershipTransferView? pendingTransfer,
  }) : super._(
         itemUuid: itemUuid,
         itemName: itemName,
         itemKind: itemKind,
         owner: owner,
         myRole: myRole,
         canShare: canShare,
         permissions: permissions,
         link: link,
         organization: organization,
         orgAccess: orgAccess,
         inheritedOrgAccess: inheritedOrgAccess,
         generalAccess: generalAccess,
         settings: settings,
         pendingRequests: pendingRequests,
         pendingTransfer: pendingTransfer,
       );

  /// Returns a shallow copy of this [SharingInfo]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  SharingInfo copyWith({
    _isc.UuidValue? itemUuid,
    String? itemName,
    _i26ubj99.DriveItemKind? itemKind,
    _itg9e9ms.UserSummary? owner,
    _iv7g6vuy.AccessRole? myRole,
    bool? canShare,
    List<_im2pznpj.PermissionView>? permissions,
    _impi727v.ShareLinkView? link = const _UndefinedSharingInfo$link(),
    Object? organization = _Undefined,
    _ir3h02o5.OrgAccessView? orgAccess =
        const _UndefinedSharingInfo$orgAccess(),
    _ir3h02o5.OrgAccessView? inheritedOrgAccess =
        const _UndefinedSharingInfo$orgAccess(),
    _ijt0as3o.GeneralAccess? generalAccess,
    _iz7k30fg.ItemSharingSettings? settings,
    List<_itmxnxi6.AccessRequestView>? pendingRequests,
    _irnzbqjz.OwnershipTransferView? pendingTransfer =
        const _UndefinedSharingInfo$pendingTransfer(),
  }) {
    return SharingInfo(
      itemUuid: itemUuid ?? this.itemUuid,
      itemName: itemName ?? this.itemName,
      itemKind: itemKind ?? this.itemKind,
      owner: owner ?? this.owner.copyWith(),
      myRole: myRole ?? this.myRole,
      canShare: canShare ?? this.canShare,
      permissions:
          permissions ?? this.permissions.map((e0) => e0.copyWith()).toList(),
      link: link is _isc.UndefinedSentinel ? this.link?.copyWith() : link,
      organization: organization is String? ? organization : this.organization,
      orgAccess: orgAccess is _isc.UndefinedSentinel
          ? this.orgAccess?.copyWith()
          : orgAccess,
      inheritedOrgAccess: inheritedOrgAccess is _isc.UndefinedSentinel
          ? this.inheritedOrgAccess?.copyWith()
          : inheritedOrgAccess,
      generalAccess: generalAccess ?? this.generalAccess,
      settings: settings ?? this.settings.copyWith(),
      pendingRequests:
          pendingRequests ??
          this.pendingRequests.map((e0) => e0.copyWith()).toList(),
      pendingTransfer: pendingTransfer is _isc.UndefinedSentinel
          ? this.pendingTransfer?.copyWith()
          : pendingTransfer,
    );
  }
}
