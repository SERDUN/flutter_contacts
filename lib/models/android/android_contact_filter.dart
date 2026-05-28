/// Composable filter expression for [FlutterContacts.getAll] on Android.
///
/// Lets callers express boolean combinations of contact-level predicates
/// against `ContactsContract`. Two leaf predicates are supported today:
///
/// - [AndroidContactFilter.hasDataMimetype] — passes if the contact has at
///   least one row in `ContactsContract.Data` whose `MIMETYPE` is in the
///   given set.
/// - [AndroidContactFilter.hasAccountType] — passes if the contact has at
///   least one raw contact whose `ACCOUNT_TYPE` is in the given set.
///
/// Combine with [AndroidContactFilter.and] / [AndroidContactFilter.or]:
///
/// ```dart
/// final filter = AndroidContactFilter.or([
///   AndroidContactFilter.hasDataMimetype({'vnd.android.cursor.item/phone_v2'}),
///   AndroidContactFilter.hasAccountType({'com.google'}),
/// ]);
/// final contacts = await FlutterContacts.getAll(androidFilter: filter);
/// ```
///
/// Ignored on iOS / macOS — Android-only concept. The `android` prefix in
/// the type and parameter name makes the platform scope explicit, so
/// callers do not need to gate on `Platform.isAndroid`.
class AndroidContactFilter {
  /// Internal discriminator for [toJson] / native parsing.
  final _AndroidFilterKind _kind;
  final dynamic _value;

  const AndroidContactFilter._(this._kind, this._value);

  /// Passes if the contact has at least one data row with a mimetype in
  /// [mimetypes].
  factory AndroidContactFilter.hasDataMimetype(Set<String> mimetypes) =>
      AndroidContactFilter._(_AndroidFilterKind.hasDataMimetype, mimetypes);

  /// Passes if the contact has at least one raw contact whose
  /// `ACCOUNT_TYPE` is in [accountTypes] (e.g. `com.google`).
  factory AndroidContactFilter.hasAccountType(Set<String> accountTypes) =>
      AndroidContactFilter._(_AndroidFilterKind.hasAccountType, accountTypes);

  /// Passes if **all** [children] pass. Empty [children] passes vacuously.
  factory AndroidContactFilter.and(List<AndroidContactFilter> children) =>
      AndroidContactFilter._(
        _AndroidFilterKind.and,
        List<AndroidContactFilter>.unmodifiable(children),
      );

  /// Passes if **at least one** of [children] passes. Empty [children] fails.
  factory AndroidContactFilter.or(List<AndroidContactFilter> children) =>
      AndroidContactFilter._(
        _AndroidFilterKind.or,
        List<AndroidContactFilter>.unmodifiable(children),
      );

  Map<String, dynamic> toJson() => switch (_kind) {
    _AndroidFilterKind.hasDataMimetype => {
      'type': 'hasDataMimetype',
      'mimetypes': (_value as Set<String>).toList(),
    },
    _AndroidFilterKind.hasAccountType => {
      'type': 'hasAccountType',
      'accountTypes': (_value as Set<String>).toList(),
    },
    _AndroidFilterKind.and => {
      'type': 'and',
      'children': (_value as List<AndroidContactFilter>)
          .map((f) => f.toJson())
          .toList(),
    },
    _AndroidFilterKind.or => {
      'type': 'or',
      'children': (_value as List<AndroidContactFilter>)
          .map((f) => f.toJson())
          .toList(),
    },
  };
}

enum _AndroidFilterKind { hasDataMimetype, hasAccountType, and, or }
