import 'dart:convert';

import 'models.dart';

const String _prefix = 'GYMV1.';

class ChallengeResultPayload {
  final Challenge challenge;
  final String participantName;
  final double value;

  const ChallengeResultPayload({
    required this.challenge,
    required this.participantName,
    required this.value,
  });
}

Map<String, dynamic> _challengeFields(Challenge c) => {
      't': c.title,
      'm': c.metric.index,
      'e': c.exerciseName,
      's': c.startAt.millisecondsSinceEpoch,
      'd': c.endAt.millisecondsSinceEpoch,
    };

Challenge _challengeFromFields(Map<String, dynamic> f, String myName) =>
    Challenge(
      title: f['t'] as String,
      metric: ChallengeMetric.values[f['m'] as int],
      exerciseName: f['e'] as String?,
      startAt: DateTime.fromMillisecondsSinceEpoch(f['s'] as int),
      endAt: DateTime.fromMillisecondsSinceEpoch(f['d'] as int),
      myName: myName,
    );

String encodeInvite(Challenge c) {
  final json = jsonEncode({
    'k': 'invite',
    ..._challengeFields(c),
    'n': c.myName,
  });
  return _prefix + base64Url.encode(utf8.encode(json));
}

String encodeResult(Challenge c, double value) {
  final json = jsonEncode({
    'k': 'result',
    ..._challengeFields(c),
    'n': c.myName,
    'v': value,
  });
  return _prefix + base64Url.encode(utf8.encode(json));
}

Challenge? decodeInvite(String code) {
  final f = _decodeFields(code);
  if (f == null || f['k'] != 'invite') return null;
  return _challengeFromFields(f, f['n'] as String);
}

ChallengeResultPayload? decodeResult(String code) {
  final f = _decodeFields(code);
  if (f == null || f['k'] != 'result' || f['v'] == null) return null;
  final challenge = _challengeFromFields(f, '(creatore)');
  return ChallengeResultPayload(
    challenge: challenge,
    participantName: f['n'] as String,
    value: (f['v'] as num).toDouble(),
  );
}

Map<String, dynamic>? _decodeFields(String code) {
  final trimmed = code.trim();
  if (!trimmed.startsWith(_prefix)) return null;
  try {
    final json = utf8.decode(base64Url.decode(trimmed.substring(_prefix.length)));
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } on FormatException {
    return null;
  }
}
