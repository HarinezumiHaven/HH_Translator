import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const JapaneseTranslatorApp());
}

class JapaneseTranslatorApp extends StatelessWidget {
  const JapaneseTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HH Translator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(244, 21, 20, 27),
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 23, 2, 83),
        ),
        fontFamily: 'AppFont',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Color.fromARGB(255, 45, 46, 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ),
      home: const TranslatorPage(),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController _controller = TextEditingController();
  String _result = 'Введiть текст для перекладу.';

  Future<String> translateText(String text, String from, String to) async {
    final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}');
    final response = await http.get(url);
    final json = jsonDecode(response.body);
    return json[0][0][0];
  }

  Future<String?> getWordExplanation(String word) async {
    final url =
        Uri.parse('https://jisho.org/api/v1/search/words?keyword=$word');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'].isNotEmpty) {
        final entry = data['data'][0];
        final reading = entry['japanese'][0]['reading'];
        final senses = entry['senses'];

        List<String> allDefs = [];
        for (var sense in senses) {
          final defs = sense['english_definitions'];
          allDefs.add(defs.join(', '));
        }

        final englishCombined = allDefs.join('; ');
        final ukrainian = await translateText(englishCombined, 'en', 'uk');

        return '[$reading] - $ukrainian';
      }
    }
    return null;
  }

  Future<void> processText(String inputText) async {
    if (inputText.trim().isEmpty) {
      setState(() => _result = 'Введiть текст для перекладу.');
      return;
    }

    try {
      final japanese = await translateText(inputText, 'auto', 'ja');
      final fullUkrainian = await translateText(japanese, 'ja', 'uk');
      final words = inputText
          .split(RegExp(r'\s+|。|、'))
          .where((w) => w.trim().isNotEmpty)
          .toList();

      final List<String> explanations = [];

      for (final word in words) {
        final japaneseWord = await translateText(word, 'uk', 'ja');
        final explanation = await getWordExplanation(japaneseWord);
        if (explanation != null) {
          explanations.add('$japaneseWord $explanation');
        }
      }

      setState(() {
        _result =
            '🇯🇵 Японською: $japanese\n🇺🇦 Українською: $fullUkrainian\n\n' +
                '───────────────\n\n' +
                (explanations.isNotEmpty
                    ? explanations.join('\n')
                    : 'Нічого не знайдено.');
      });
    } catch (e) {
      const tgChannel = "@harinezumi_devs";
      setState(() => _result =
          'Помилка: $e\nReport on Telegram: $tgChannel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HH Translator 🇺🇦🇯🇵',
          style: TextStyle(color: Color.fromARGB(248, 244, 248, 194)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Введiть текст...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => processText(_controller.text),
              child: const Text('Перекласти та проаналiзувати'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
