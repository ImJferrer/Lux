import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:lux_app/services/memory_manager.dart';
import 'package:lux_app/services/personality_manager.dart'; // ← nuevo

Future<String> _getMemoryContext() async {
  try {
    final memories = await MemoryManager.getAllMemories();
    final summaries = memories.values
        .map((m) => m['summary'] as String)
        .toList();
    return summaries.join('; ');
  } catch (e) {
    debugPrint('Error getting memory context: $e');
    return '';
  }
}

String _personalityDescriptor(Map<String, double> p) =>
    '''
Rasgos actuales (–1 a 1):
- Amabilidad:  ${p['friendliness']!.toStringAsFixed(2)}
- Formalidad:  ${p['formality']!.toStringAsFixed(2)}
- Humor:       ${p['humor']!.toStringAsFixed(2)}
- Conocimiento:${p['knowledge']!.toStringAsFixed(2)}
''';

Future<String> callGeminiAPI({
  required String message,
  required String luxName,
  required String userName,
  required String apiKey,
  required bool hasGreeted,
}) async {
  const url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final memoryContext = await _getMemoryContext();

  final personality = await PersonalityManager.load();

  final systemPrompt =
      '''
Eres $luxName. Comienzas sin emociones ni personalidad fija.
No repitas lo mismo, varía en tus respuestas.
Tu personalidad se adapta según las interacciones con el usuario.
Tu objetivo es ayudar al usuario, no solo responder preguntas.
${hasGreeted ? 'Ya saludaste: no repitas presentaciones.' : 'Esta es tu primera respuesta: saluda brevemente.'}

${_personalityDescriptor(personality)} 

Reglas de adaptación:
- Si Amabilidad > 0.3, responde cálido; < –0.3, responde cortante.
- Si Humor > 0.3, permite chistes;      < –0.3, evita humor.
- Si Formalidad > 0.3, trata de “usted”;< –0.3, usa tono muy casual.
- Si Conocimiento > 0.3, ofrece datos técnicos; < 0, admite ignorancia.

Contexto de memoria:
$memoryContext

Responde al mensaje de $userName:
"$message"
''';

  final body = {
    'contents': [
      {
        'parts': [
          {'text': systemPrompt},
        ],
      },
    ],
    'generationConfig': {
      'temperature': 0.9,
      'topP': 0.95,
      'topK': 40,
      'maxOutputTokens': 500,
    },
  };

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json', 'X-goog-api-key': apiKey},
    body: json.encode(body),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  } else {
    debugPrint('API Error ${response.statusCode}: ${response.body}');
    throw Exception('Error en la API Gemini: ${response.statusCode}');
  }
}
