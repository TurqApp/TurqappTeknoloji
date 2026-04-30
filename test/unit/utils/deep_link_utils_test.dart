import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Utils/deep_link_utils.dart';

void main() {
  group('parseDeepLinkUri', () {
    test('parses approved web hosts with path type and id', () {
      final parsed = parseDeepLinkUri(
        Uri.parse('https://turqapp.com/p/post-123'),
      );

      expect(parsed?.type, 'post');
      expect(parsed?.id, 'post-123');
    });

    test('keeps accepted web aliases mapped through one parser', () {
      final cases = <String, (String, String)>{
        'https://www.turqapp.com/s/story_1': ('story', 'story_1'),
        'https://go.turqapp.com/u/user-1': ('user', 'user-1'),
        'https://turqapp.com/profile/user_2': ('user', 'user_2'),
        'https://turqapp.com/i/question:abc': ('edu', 'question:abc'),
        'https://turqapp.com/e/job:abc': ('edu', 'job:abc'),
        'https://turqapp.com/education/scholarship:abc': (
          'edu',
          'scholarship:abc',
        ),
        'https://turqapp.com/product/market_1': ('market', 'market_1'),
      };

      for (final entry in cases.entries) {
        final parsed = parseDeepLinkUri(Uri.parse(entry.key));

        expect(parsed?.type, entry.value.$1, reason: entry.key);
        expect(parsed?.id, entry.value.$2, reason: entry.key);
      }
    });

    test('parses approved go and typo domains without changing aliases', () {
      final goParsed = parseDeepLinkUri(
        Uri.parse('https://go.turqapp.com/profile/user_1'),
      );
      final typoParsed = parseDeepLinkUri(
        Uri.parse('https://www.turqqapp.com/m/item-1'),
      );

      expect(goParsed?.type, 'user');
      expect(goParsed?.id, 'user_1');
      expect(typoParsed?.type, 'market');
      expect(typoParsed?.id, 'item-1');
    });

    test('keeps all approved web host entries and casing stable', () {
      final cases = <String, (String, String)>{
        'HTTPS://TURQAPP.COM/P/Post_1': ('post', 'Post_1'),
        'https://www.turqapp.com/story/story-2?utm=ignored': (
          'story',
          'story-2',
        ),
        'https://go.turqqapp.com/profile/user-3#bio': ('user', 'user-3'),
        'https://turqqapp.com/market/item_4': ('market', 'item_4'),
      };

      for (final entry in cases.entries) {
        final parsed = parseDeepLinkUri(Uri.parse(entry.key));

        expect(parsed?.type, entry.value.$1, reason: entry.key);
        expect(parsed?.id, entry.value.$2, reason: entry.key);
      }
    });

    test('parses custom scheme host and path forms', () {
      final hostForm = parseDeepLinkUri(
        Uri.parse('turqapp://story/story-1'),
      );
      final pathForm = parseDeepLinkUri(
        Uri.parse('turqapp:///edu/question:abc'),
      );

      expect(hostForm?.type, 'story');
      expect(hostForm?.id, 'story-1');
      expect(pathForm?.type, 'edu');
      expect(pathForm?.id, 'question:abc');
    });

    test('parses custom scheme aliases without web host checks', () {
      final cases = <String, (String, String)>{
        'turqapp://p/post_1': ('post', 'post_1'),
        'turqapp://u/user_1': ('user', 'user_1'),
        'turqapp://profile/user_2': ('user', 'user_2'),
        'turqapp://m/market_1': ('market', 'market_1'),
        'turqapp:///education/practiceexam:abc': (
          'edu',
          'practiceexam:abc',
        ),
      };

      for (final entry in cases.entries) {
        final parsed = parseDeepLinkUri(Uri.parse(entry.key));

        expect(parsed?.type, entry.value.$1, reason: entry.key);
        expect(parsed?.id, entry.value.$2, reason: entry.key);
      }
    });

    test('keeps custom scheme query and fragment outside route identity', () {
      final cases = <String, (String, String)>{
        'turqapp://POST/post-1?source=push': ('post', 'post-1'),
        'turqapp://profile/user-2#posts': ('user', 'user-2'),
        'turqapp:///education/job:abc?tab=jobs': ('edu', 'job:abc'),
      };

      for (final entry in cases.entries) {
        final parsed = parseDeepLinkUri(Uri.parse(entry.key));

        expect(parsed?.type, entry.value.$1, reason: entry.key);
        expect(parsed?.id, entry.value.$2, reason: entry.key);
      }
    });

    test('keeps route identity stable when links carry path tails', () {
      final cases = <String, (String, String)>{
        'https://turqapp.com/post/post-1/comments/7?utm=ignored': (
          'post',
          'post-1',
        ),
        'https://go.turqapp.com/profile/user_1/posts': ('user', 'user_1'),
        'turqapp://profile/user-2/followers': ('user', 'user-2'),
        'turqapp:///market/item_3/details': ('market', 'item_3'),
      };

      for (final entry in cases.entries) {
        final parsed = parseDeepLinkUri(Uri.parse(entry.key));

        expect(parsed?.type, entry.value.$1, reason: entry.key);
        expect(parsed?.id, entry.value.$2, reason: entry.key);
      }
    });

    test('normalizes id punctuation and rejects invalid entries', () {
      final parsed = parseDeepLinkUri(
        Uri.parse('https://turqapp.com/post/%23post-1!'),
      );

      expect(parsed?.type, 'post');
      expect(parsed?.id, 'post-1');
      expect(
        parseDeepLinkUri(Uri.parse('https://example.com/p/post-1')),
        isNull,
      );
      expect(
        parseDeepLinkUri(Uri.parse('https://turqapp.com/unknown/id')),
        isNull,
      );
      expect(parseDeepLinkUri(Uri.parse('https://turqapp.com/p/!!!')), isNull);
    });

    test('rejects unsupported schemes hosts and incomplete routes', () {
      final rejected = <String>[
        'ftp://turqapp.com/p/post-1',
        'https://evil.turqapp.com/p/post-1',
        'https://turqapp.com/p',
        'https://turqapp.com//post-1',
        'turqapp://unknown/id',
        'turqapp://post',
      ];

      for (final uri in rejected) {
        expect(parseDeepLinkUri(Uri.parse(uri)), isNull, reason: uri);
      }
    });
  });

  group('educationDeepLinkTabIndexFor', () {
    test('keeps existing education entity tab mapping centralized', () {
      expect(educationDeepLinkTabIndexFor('scholarship:abc'), 0);
      expect(educationDeepLinkTabIndexFor('question:abc'), 1);
      expect(educationDeepLinkTabIndexFor('question-abc'), 1);
      expect(educationDeepLinkTabIndexFor('practiceexam:abc'), 2);
      expect(educationDeepLinkTabIndexFor('pastquestion:abc'), 3);
      expect(educationDeepLinkTabIndexFor('answerkey:abc'), 4);
      expect(educationDeepLinkTabIndexFor('tutoring:abc'), 5);
      expect(educationDeepLinkTabIndexFor('job:abc'), 6);
      expect(educationDeepLinkTabIndexFor('unknown'), 0);
    });
  });

  group('shouldOpenEducationDeepLinkDirectly', () {
    test('keeps direct education short-link bypass rules centralized', () {
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'question-abc'),
        ),
        isTrue,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'scholarship-abc'),
        ),
        isTrue,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'practiceexam-abc'),
        ),
        isTrue,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'pastquestion-abc'),
        ),
        isTrue,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'answerkey-abc'),
        ),
        isTrue,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'tutoring-abc'),
        ),
        isTrue,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'job-abc'),
        ),
        isTrue,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'edu', id: 'question:abc'),
        ),
        isFalse,
      );
      expect(
        shouldOpenEducationDeepLinkDirectly(
          const ParsedDeepLinkRoute(type: 'market', id: 'question-abc'),
        ),
        isFalse,
      );
    });
  });
}
