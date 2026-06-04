import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lux_app/models/chat_message.dart';
import 'package:lux_app/services/auth_services.dart';
import 'package:lux_app/widgets/chat/chat_bubble.dart';
import 'package:lux_app/widgets/chat/message_input.dart';
import 'package:lux_app/widgets/chat/typing_indicator.dart';
import 'package:lux_app/services/memory_manager.dart';
import 'package:lux_app/services/notification_service.dart';
import 'package:lux_app/utils/api_service.dart';
import 'package:lux_app/services/personality_manager.dart';

class ChatScreen extends StatefulWidget {
  final String luxName;
  final String userName;

  const ChatScreen({required this.luxName, required this.userName, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _hasGreeted = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  static const String _apiKey = 'AIzaSyD_A-WUjY-4H4qoKfDwSnULua0yH1hbDVk';
  List<String> _pendingResponse = [];
  bool _isExpectingQuestion = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _checkForFollowUps();
    MemoryManager.scheduleMemoryNotifications();
  }

  void _addWelcomeMessage() {
    final welcomeText = widget.luxName == 'LUX'
        ? 'Hola ${widget.userName}, soy LUX. Ya nos conocemos un poco, ¿verdad? Cuéntame, ¿en qué puedo ayudarte hoy?'
        : 'Hola ${widget.userName}, soy ${widget.luxName}. Ya nos conocemos un poco, ¿verdad? Cuéntame, ¿en qué puedo ayudarte hoy?';

    setState(() {
      _messages.add(
        ChatMessage(
          text: welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _checkForFollowUps() async {
    await Future.delayed(const Duration(seconds: 3));

    final memories = await MemoryManager.getMemoriesForFollowUp();
    if (memories.isNotEmpty && _messages.length < 10) {
      final memory = memories.first;

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Oye ${widget.userName}, estoy recordando algo que mencionaste antes. '
                '${memory['followUpQuestion']}',
            isUser: false,
            timestamp: DateTime.now(),
            isMemoryFollowUp: true,
            memoryKey: memory['key'],
          ),
        );
      });

      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    if (lastMessage != null &&
        lastMessage.isMemoryFollowUp &&
        lastMessage.memoryKey != null) {
      await MemoryManager.markAsFollowedUp(lastMessage.memoryKey!);

      if (userMessage.contains(
        RegExp(r'\b(sigue|aún|todavía|problema)\b', caseSensitive: false),
      )) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  'Entiendo que la situación continúa. '
                  '¿Quieres que te ayude con alguna estrategia para manejar esto?',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
        return;
      }
    }

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    _handleImportantTopics(userMessage);
    await _updatePersonalityFromUser(userMessage);
    if (!_hasGreeted) _hasGreeted = true;

    try {
      final response = await callGeminiAPI(
        apiKey: _apiKey,
        userName: widget.userName,
        luxName: widget.luxName,
        message: userMessage,
        hasGreeted: _hasGreeted,
      );
      _processResponse(response);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Lo siento, tuve un problema técnico. ¿Puedes intentar de nuevo?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _updatePersonalityFromUser(String text) async {
    final msg = text.toLowerCase();

    if (msg.contains('gracias') || msg.contains('👍')) {
      await PersonalityManager.add('friendliness', 0.05);
    }
    if (msg.contains('por favor') || msg.contains('usted')) {
      await PersonalityManager.add('formality', 0.05);
    }
    if (msg.contains('😂') || msg.contains('chiste')) {
      await PersonalityManager.add('humor', 0.05);
    }
    if (msg.contains(RegExp(r'api|código|flutter|error'))) {
      await PersonalityManager.add('knowledge', 0.05);
    }
    if (msg.contains(RegExp(r'enojad[oa]|molest[oa]|mal'))) {
      await PersonalityManager.add('friendliness', -0.05);
    }
  }

  void _handleImportantTopics(String userMessage) async {
    final problemKeywords = [
      'jefe',
      'trabajo',
      'problema',
      'estres',
      'molesto',
      'preocupado',
    ];
    final hasProblem = problemKeywords.any(
      (word) => userMessage.toLowerCase().contains(word),
    );

    if (hasProblem) {
      final summary = await _generateMemorySummary(userMessage);
      final memoryKey = 'memory_${DateTime.now().millisecondsSinceEpoch}';

      await MemoryManager.saveMemory(memoryKey, {
        'topic': 'Situación personal',
        'summary': summary,
        'followUpQuestion':
            'Sobre lo que hablamos antes, ¿cómo evolucionó esa situación?',
        'followedUp': false,
      });

      final notificationDays = 2 + (memoryKey.hashCode % 3);

      await NotificationService.scheduleNotification(
        id: memoryKey.hashCode,
        title: 'Recordatorio de ${widget.luxName}',
        body: 'Sobre lo que hablamos... ¿cómo evolucionó esa situación?',
        delay: Duration(days: notificationDays),
        payload: json.encode({
          'type': 'memory_followup',
          'memory_key': memoryKey,
        }),
      );
    }
  }

  Future<String> _generateMemorySummary(String message) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

    final body = {
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Resume en 1 frase el problema principal mencionado en este mensaje: "$message". '
                  'Usa máximo 15 palabras manteniendo el contexto clave.',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'topP': 0.7,
        'topK': 30,
        'maxOutputTokens': 100,
      },
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'X-goog-api-key': _apiKey},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    return 'Problema mencionado por el usuario';
  }

  void _processResponse(String response) {
    final raw = response.split(RegExp(r'(?<=[.!?])\s+'));

    final phrases = raw.where((s) => s.trim().isNotEmpty).toList();

    setState(() {
      _isTyping = true;
      _pendingResponse = phrases;
      _processNextPhrase();
    });
  }

  void _processNextPhrase() {
    if (_pendingResponse.isEmpty) {
      setState(() => _isTyping = false);
      _checkForFollowUps();
      return;
    }

    final phrase = _pendingResponse.removeAt(0);
    setState(() {
      _messages.add(
        ChatMessage(text: phrase, isUser: false, timestamp: DateTime.now()),
      );
    });

    _scrollToBottom();

    Future.delayed(Duration(milliseconds: 500 + (phrase.length * 30)), () {
      if (mounted) _processNextPhrase();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // MÉTODO CORREGIDO: Debe estar dentro de la clase _ChatScreenState
  void _openAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AuthSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.luxName),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: glow),
            icon: const Icon(Icons.login_outlined, size: 18),
            label: const Text('Iniciar sesión'),
            onPressed: _openAuthSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return TypingIndicator(glow: glow, luxName: widget.luxName);
                }
                return ChatBubble(
                  message: _messages[index],
                  glow: glow,
                  luxName: widget.luxName,
                );
              },
            ),
          ),
          MessageInput(
            controller: _controller,
            onSend: _sendMessage,
            isTyping: _isTyping,
            glow: glow,
            isExpectingQuestion: _isExpectingQuestion,
            onChanged: (text) {
              setState(() {
                _isExpectingQuestion = text.endsWith('?');
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _AuthSheet extends StatefulWidget {
  const _AuthSheet();

  @override
  _AuthSheetState createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  final _mail = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(_mail.text, _pass.text);
      } else {
        await AuthService.register(_mail.text, _pass.text);
      }
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sesión iniciada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión iniciada con Google')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, pad + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mail,
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: Text(_isLogin ? 'Entrar' : 'Registrar'),
          ),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin ? 'Crear cuenta' : 'Ya tengo cuenta'),
          ),
          const Divider(),
          OutlinedButton.icon(
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Entrar con Google'),
            onPressed: _loading ? null : _signInWithGoogle,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mail.dispose();
    _pass.dispose();
    super.dispose();
  }
}
