import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final inputPath = parsed['input'];
  final format = (parsed['format'] ?? 'raw').trim().toLowerCase();

  if (inputPath == null) {
    stderr.writeln(
      'Usage: dart run tool/release_alert_message.dart --input <file> [--format raw|slack|discord|teams]',
    );
    exitCode = 64;
    return;
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Release alert bundle not found: $inputPath');
    exitCode = 66;
    return;
  }

  final decoded = jsonDecode(await inputFile.readAsString());
  if (decoded is! Map) {
    stderr.writeln('Release alert bundle must be a JSON object');
    exitCode = 65;
    return;
  }

  final bundle = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
  switch (format) {
    case 'raw':
      stdout.write(jsonEncode(bundle));
      return;
    case 'slack':
      stdout.write(jsonEncode(_buildSlackPayload(bundle)));
      return;
    case 'discord':
      stdout.write(jsonEncode(_buildDiscordPayload(bundle)));
      return;
    case 'teams':
      stdout.write(jsonEncode(_buildTeamsPayload(bundle)));
      return;
    default:
      stderr.writeln('Unknown format: $format');
      exitCode = 64;
  }
}

Map<String, dynamic> _buildSlackPayload(Map<String, dynamic> bundle) {
  final summary = _asMap(bundle['summary']);
  final topSignals = _asList(bundle['topSignals']);
  final nextActions = _asList(bundle['nextActions']);
  final severity = (summary['severity'] ?? 'unknown').toString();
  final headline = (summary['headline'] ?? 'Release alert').toString();

  final lines = <String>[
    '*$headline*',
    'Severity: `${severity.toUpperCase()}`',
    ...topSignals.take(3).map(_signalLine),
    ...nextActions.take(3).map((action) => 'Action: ${action.toString()}'),
  ];

  return <String, dynamic>{
    'text': headline,
    'blocks': <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'section',
        'text': <String, dynamic>{
          'type': 'mrkdwn',
          'text': lines.join('\n'),
        },
      },
    ],
    'metadata': bundle,
  };
}

Map<String, dynamic> _buildDiscordPayload(Map<String, dynamic> bundle) {
  final summary = _asMap(bundle['summary']);
  final topSignals = _asList(bundle['topSignals']);
  final nextActions = _asList(bundle['nextActions']);
  final severity = (summary['severity'] ?? 'unknown').toString();
  final headline = (summary['headline'] ?? 'Release alert').toString();

  return <String, dynamic>{
    'content': '**$headline**',
    'embeds': <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Release Gate Alert',
        'description': [
          'Severity: ${severity.toUpperCase()}',
          ...topSignals.take(3).map(_signalLine),
          ...nextActions.take(3).map((action) => 'Action: ${action.toString()}'),
        ].join('\n'),
        'color': _discordColorForSeverity(severity),
      },
    ],
    'metadata': bundle,
  };
}

Map<String, dynamic> _buildTeamsPayload(Map<String, dynamic> bundle) {
  final summary = _asMap(bundle['summary']);
  final topSignals = _asList(bundle['topSignals']);
  final nextActions = _asList(bundle['nextActions']);
  final severity = (summary['severity'] ?? 'unknown').toString();
  final headline = (summary['headline'] ?? 'Release alert').toString();

  return <String, dynamic>{
    'type': 'message',
    'attachments': <Map<String, dynamic>>[
      <String, dynamic>{
        'contentType': 'application/vnd.microsoft.card.adaptive',
        'content': <String, dynamic>{
          r'$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
          'type': 'AdaptiveCard',
          'version': '1.4',
          'body': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'TextBlock',
              'size': 'Medium',
              'weight': 'Bolder',
              'text': headline,
              'wrap': true,
            },
            <String, dynamic>{
              'type': 'TextBlock',
              'spacing': 'Small',
              'text': 'Severity: ${severity.toUpperCase()}',
              'wrap': true,
            },
            for (final signal in topSignals.take(3))
              <String, dynamic>{
                'type': 'TextBlock',
                'spacing': 'Small',
                'text': _signalLine(signal),
                'wrap': true,
              },
            for (final action in nextActions.take(3))
              <String, dynamic>{
                'type': 'TextBlock',
                'spacing': 'Small',
                'text': 'Action: ${action.toString()}',
                'wrap': true,
              },
          ],
        },
      },
    ],
    'metadata': bundle,
  };
}

String _signalLine(dynamic rawSignal) {
  final signal = _asMap(rawSignal);
  final type = (signal['type'] ?? '').toString();
  if (type == 'smoke') {
    return 'Smoke ${signal['scenario']}: failure=${signal['hasFailure']} blocking=${signal['telemetryBlockingCount']} invariants=${signal['invariantCount']}';
  }
  if (type == 'telemetry') {
    return 'Telemetry ${signal['surface']}: ${signal['code']} (${signal['severity']})';
  }
  return signal.toString();
}

int _discordColorForSeverity(String severity) {
  switch (severity) {
    case 'blocking':
      return 0xE53935;
    case 'warning':
      return 0xFB8C00;
    default:
      return 0x43A047;
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final parsed = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final current = args[i];
    if (!current.startsWith('--')) continue;
    final key = current.substring(2);
    final next = i + 1 < args.length ? args[i + 1] : null;
    if (next == null || next.startsWith('--')) continue;
    parsed[key] = next;
    i += 1;
  }
  return parsed;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}
