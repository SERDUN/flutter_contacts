import '../../utils/json_helpers.dart';
import '../accounts/account.dart';

/// Information about a raw contact with its identifiers and account.
///
/// One Contact can have multiple RawContacts from different sources (Google, WhatsApp, etc.).
class RawContact {
  /// Raw contact ID. Unstable, local-only. Use when modifying data.
  final String? rawContactId;

  /// Source ID. Stable server UUID. Use for sync matching.
  final String? sourceId;

  /// Account this raw contact belongs to.
  final Account? account;

  /// Data mimetypes present for this raw contact (Android only).
  ///
  /// Lists the `ContactsContract.Data.MIMETYPE` values that exist for this raw contact —
  /// e.g. `vnd.android.cursor.item/phone_v2`, `vnd.android.cursor.item/email_v2`, plus
  /// any source-specific entries written by messaging apps (e.g. WhatsApp / Viber).
  /// Empty on iOS / macOS.
  ///
  /// Populated only when [ContactProperty.identifiers] is requested.
  final List<String> dataMimetypes;

  const RawContact({
    this.rawContactId,
    this.sourceId,
    this.account,
    this.dataMimetypes = const [],
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    JsonHelpers.encode(json, 'rawContactId', rawContactId);
    JsonHelpers.encode(json, 'sourceId', sourceId);
    JsonHelpers.encode(json, 'account', account, (a) => a.toJson());
    if (dataMimetypes.isNotEmpty) json['dataMimetypes'] = dataMimetypes;
    return json;
  }

  static RawContact? fromJson(Map? json) {
    if (json == null) return null;
    final accountJson = json['account'];
    final account = accountJson != null
        ? Account.fromJson(accountJson as Map)
        : null;
    final rawContactId = JsonHelpers.decode<String>(json['rawContactId']);
    final sourceId = JsonHelpers.decode<String>(json['sourceId']);
    final dataMimetypes =
        (json['dataMimetypes'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const [];
    if (rawContactId == null &&
        sourceId == null &&
        account == null &&
        dataMimetypes.isEmpty) {
      return null;
    }
    return RawContact(
      rawContactId: rawContactId,
      sourceId: sourceId,
      account: account,
      dataMimetypes: dataMimetypes,
    );
  }

  @override
  String toString() => JsonHelpers.formatToString('RawContact', {
    'rawContactId': rawContactId,
    'sourceId': sourceId,
    'account': account,
    'dataMimetypes': dataMimetypes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawContact &&
          rawContactId == other.rawContactId &&
          sourceId == other.sourceId &&
          account == other.account &&
          _listEquals(dataMimetypes, other.dataMimetypes));

  @override
  int get hashCode => Object.hash(
    rawContactId,
    sourceId,
    account,
    Object.hashAll(dataMimetypes),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
