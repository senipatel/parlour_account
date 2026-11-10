import 'dart:convert';
import 'dart:io';

const _seedTag = 'parlour_demo_seed_v1';

Future<void> main(List<String> arguments) async {
  final apply = arguments.contains('--apply');
  final cleanup = arguments.contains('--cleanup');
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'];
  final apiKey = Platform.environment['FIREBASE_WEB_API_KEY'];
  final email = Platform.environment['FIREBASE_SEED_EMAIL'];
  final password = Platform.environment['FIREBASE_SEED_PASSWORD'];
  final confirmIndex = arguments.indexOf('--confirm-project');
  final confirmedProject = confirmIndex < 0 || confirmIndex + 1 >= arguments.length
      ? null
      : arguments[confirmIndex + 1];

  if (!apply) {
    stdout.writeln('Dry run: no Firebase data was changed.');
    stdout
        .writeln('The seeder will create 30 daily entries and 3 bill entries.');
    stdout.writeln(
      'Use --apply --confirm-project <project-id> with the FIREBASE_* '
      'environment variables set.',
    );
    stdout.writeln(
      'Use --apply --cleanup --confirm-project <project-id> to remove '
      'only records tagged by this script.',
    );
    return;
  }
  if (projectId == null ||
      apiKey == null ||
      email == null ||
      password == null) {
    stderr.writeln(
      'Set FIREBASE_PROJECT_ID, FIREBASE_WEB_API_KEY, '
      'FIREBASE_SEED_EMAIL, and FIREBASE_SEED_PASSWORD first.',
    );
    exitCode = 2;
    return;
  }
  if (confirmedProject != projectId) {
    stderr.writeln(
      'Pass --confirm-project with the exact FIREBASE_PROJECT_ID to continue.',
    );
    exitCode = 2;
    return;
  }

  try {
    final token = await _signIn(apiKey, email, password);
    if (cleanup) {
      final deleted = await _removeSeededRecords(
        projectId: projectId,
        apiKey: apiKey,
        token: token.idToken,
        uid: token.uid,
      );
      stdout.writeln('Removed $deleted demo record(s) from ${token.email}.');
      return;
    }

    final writes = _buildWrites(projectId, token.uid);
    await _commit(
      projectId: projectId,
      apiKey: apiKey,
      token: token.idToken,
      writes: writes,
    );
    stdout.writeln(
      'Wrote ${writes.length} demo record(s) for ${token.email} '
      'in Firebase project $projectId.',
    );
  } catch (error) {
    stderr.writeln('Demo data operation failed: $error');
    exitCode = 1;
  }
}

class _AuthToken {
  const _AuthToken({
    required this.idToken,
    required this.uid,
    required this.email,
  });

  final String idToken;
  final String uid;
  final String email;
}

Future<_AuthToken> _signIn(String apiKey, String email, String password) async {
  final client = HttpClient();
  try {
    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:signInWithPassword',
      {'key': apiKey},
    );
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }));
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Firebase sign-in failed (${response.statusCode}): $body');
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    return _AuthToken(
      idToken: data['idToken'] as String,
      uid: data['localId'] as String,
      email: data['email'] as String? ?? email,
    );
  } finally {
    client.close(force: true);
  }
}

List<Map<String, dynamic>> _buildWrites(String projectId, String uid) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final writes = <Map<String, dynamic>>[];

  for (var offset = 29; offset >= 0; offset--) {
    final date = today.subtract(Duration(days: offset));
    final key = _dateKey(date);
    final dayIndex = date.day;
    final daily = <String, dynamic>{
      'incomeCash': 42000 + (dayIndex % 5) * 11500,
      'incomeOnline': 18000 + (dayIndex % 4) * 9000,
      'expenseCash': 6500 + (dayIndex % 3) * 2100,
      'expenseOnline': 4500 + (dayIndex % 4) * 1600,
      'description': 'Demo daily entry $key',
      'date': key,
      'timestamp': date,
      'demoSeedId': _seedTag,
    };
    writes.add(
        _write(projectId, uid, 'DailyDataEntry', 'demo_daily_$key', daily));
  }

  final paidDate = _dateKey(today);
  final partialDate = _dateKey(today.subtract(const Duration(days: 2)));
  final overdueDate = _dateKey(today.subtract(const Duration(days: 5)));
  final dueSoon = _dateKey(today.add(const Duration(days: 3)));
  final recentlyDue = _dateKey(today.subtract(const Duration(days: 2)));
  final bills = <(String, Map<String, dynamic>)>[
    (
      'demo_bill_paid',
      {
        'payee': 'Demo supplies · paid',
        'billAmountCash': 38000,
        'billAmountOnline': 12000,
        'paidAmountCash': 38000,
        'paidAmountOnline': 12000,
        'paymentStatus': 'paid',
        'date': paidDate,
        'dueDate': paidDate,
        'paidDate': paidDate,
        'description': 'Seeded sample bill',
        'demoSeedId': _seedTag,
      },
    ),
    (
      'demo_bill_partial',
      {
        'payee': 'Demo product order · part paid',
        'billAmountCash': 20000,
        'billAmountOnline': 65000,
        'paidAmountCash': 10000,
        'paidAmountOnline': 25000,
        'paymentStatus': 'partially_paid',
        'date': partialDate,
        'dueDate': dueSoon,
        'paidDate': partialDate,
        'description': 'Seeded sample bill',
        'demoSeedId': _seedTag,
      },
    ),
    (
      'demo_bill_due',
      {
        'payee': 'Demo equipment service · due',
        'billAmountCash': 54000,
        'billAmountOnline': 0,
        'paidAmountCash': 0,
        'paidAmountOnline': 0,
        'paymentStatus': 'unpaid',
        'date': overdueDate,
        'dueDate': recentlyDue,
        'paidDate': null,
        'description': 'Seeded sample bill',
        'demoSeedId': _seedTag,
      },
    ),
  ];
  for (final (id, data) in bills) {
    writes.add(_write(projectId, uid, 'BillPaymentEntry', id, data));
  }
  return writes;
}

Map<String, dynamic> _write(
  String projectId,
  String uid,
  String collection,
  String documentId,
  Map<String, dynamic> values,
) =>
    {
      'update': {
        'name': 'projects/$projectId/databases/(default)/documents/'
            'users/$uid/$collection/$documentId',
        'fields': {
          for (final entry in values.entries)
            entry.key: _firestoreValue(entry.value),
        },
      },
    };

Map<String, dynamic> _firestoreValue(Object? value) {
  if (value == null) return {'nullValue': null};
  if (value is int) return {'integerValue': value.toString()};
  if (value is bool) return {'booleanValue': value};
  if (value is DateTime) {
    return {'timestampValue': value.toUtc().toIso8601String()};
  }
  if (value is String) return {'stringValue': value};
  throw ArgumentError.value(value, 'value', 'Unsupported Firestore value');
}

Future<void> _commit({
  required String projectId,
  required String apiKey,
  required String token,
  required List<Map<String, dynamic>> writes,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents:commit',
      {'key': apiKey},
    );
    final request = await client.postUrl(uri);
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode({'writes': writes}));
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Firestore write failed (${response.statusCode}): $body');
    }
  } finally {
    client.close(force: true);
  }
}

Future<int> _removeSeededRecords({
  required String projectId,
  required String apiKey,
  required String token,
  required String uid,
}) async {
  final names = <String>[];
  for (final collection in ['DailyDataEntry', 'BillPaymentEntry']) {
    final client = HttpClient();
    try {
      final uri = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/'
            'users/$uid:runQuery',
        {'key': apiKey},
      );
      final request = await client.postUrl(uri);
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write(jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': collection},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'demoSeedId'},
              'op': 'EQUAL',
              'value': {'stringValue': _seedTag},
            },
          },
        },
      }));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
            'Firestore query failed (${response.statusCode}): $body');
      }
      for (final row in jsonDecode(body) as List<dynamic>) {
        final document = (row as Map<String, dynamic>)['document'];
        if (document is Map<String, dynamic> && document['name'] is String) {
          names.add(document['name'] as String);
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  if (names.isEmpty) return 0;
  final client = HttpClient();
  try {
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents:commit',
      {'key': apiKey},
    );
    final request = await client.postUrl(uri);
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode({
      'writes': [
        for (final name in names) {'delete': name}
      ],
    }));
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
          'Firestore cleanup failed (${response.statusCode}): $body');
    }
    return names.length;
  } finally {
    client.close(force: true);
  }
}

String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
