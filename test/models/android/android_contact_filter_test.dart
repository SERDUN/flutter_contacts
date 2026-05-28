import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts/models/android/android_contact_filter.dart';

void main() {
  group('AndroidContactFilter.toJson', () {
    test('hasDataMimetype serializes mimetypes as a list', () {
      final filter = AndroidContactFilter.hasDataMimetype(const {
        'vnd.android.cursor.item/phone_v2',
        'vnd.android.cursor.item/email_v2',
      });

      final json = filter.toJson();

      expect(json['type'], 'hasDataMimetype');
      expect((json['mimetypes'] as List).toSet(), {
        'vnd.android.cursor.item/phone_v2',
        'vnd.android.cursor.item/email_v2',
      });
    });

    test('hasAccountType serializes account types as a list', () {
      final filter = AndroidContactFilter.hasAccountType(const {'com.google'});

      expect(filter.toJson(), {
        'type': 'hasAccountType',
        'accountTypes': ['com.google'],
      });
    });

    test('or wraps children verbatim', () {
      final filter = AndroidContactFilter.or([
        AndroidContactFilter.hasDataMimetype(const {'a'}),
        AndroidContactFilter.hasAccountType(const {'b'}),
      ]);

      final json = filter.toJson();

      expect(json['type'], 'or');
      final children = json['children'] as List;
      expect(children, hasLength(2));
      expect(children[0], {
        'type': 'hasDataMimetype',
        'mimetypes': ['a'],
      });
      expect(children[1], {
        'type': 'hasAccountType',
        'accountTypes': ['b'],
      });
    });

    test('and wraps children verbatim', () {
      final filter = AndroidContactFilter.and([
        AndroidContactFilter.hasAccountType(const {'com.google'}),
        AndroidContactFilter.hasDataMimetype(const {
          'vnd.android.cursor.item/phone_v2',
        }),
      ]);

      expect(filter.toJson()['type'], 'and');
      expect((filter.toJson()['children'] as List), hasLength(2));
    });

    test('nested expressions serialize recursively', () {
      final filter = AndroidContactFilter.and([
        AndroidContactFilter.hasAccountType(const {'com.google'}),
        AndroidContactFilter.or([
          AndroidContactFilter.hasDataMimetype(const {
            'vnd.android.cursor.item/phone_v2',
          }),
          AndroidContactFilter.hasDataMimetype(const {
            'vnd.android.cursor.item/email_v2',
          }),
        ]),
      ]);

      final json = filter.toJson();
      final inner = (json['children'] as List)[1] as Map<String, dynamic>;
      expect(inner['type'], 'or');
      expect((inner['children'] as List), hasLength(2));
      expect(
        ((inner['children'] as List)[0] as Map)['type'],
        'hasDataMimetype',
      );
    });

    test('empty children lists serialize as empty', () {
      expect(AndroidContactFilter.and(const []).toJson(), {
        'type': 'and',
        'children': <Map>[],
      });
      expect(AndroidContactFilter.or(const []).toJson(), {
        'type': 'or',
        'children': <Map>[],
      });
    });
  });
}
