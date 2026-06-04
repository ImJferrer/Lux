import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lux_app/services/notification_service.dart';
import 'package:lux_app/models/onboarding_step.dart';
import 'package:lux_app/screens/chat_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final List<OnboardingStep> steps;
  int cursor = 0;
  double opacity = 0.0;
  Timer? timer;
  bool audioInitialized = false;
  late final AudioPlayer player;
  String luxName = 'LUX';
  String userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    initAudio();
    initSteps();
    start();
    NotificationService.initialize();
  }

  Future<void> initAudio() async {
    try {
      player = AudioPlayer();
      await player.setAsset('assets/audio/relaxing.mp3');
      await player.setLoopMode(LoopMode.all);
      await player.setVolume(0.7);
      audioInitialized = true;
      await player.play();
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      audioInitialized = false;
    }
  }

  void initSteps() {
    steps = OnboardingStep.getInitialSteps(
      setLuxCustomName: setLuxCustomName,
      appendAndContinue: appendAndContinue,
      askUserName: askUserName,
    );
  }

  void start() {
    Future.delayed(const Duration(milliseconds: 600), showCurrent);
  }

  void showCurrent() {
    final current = steps[cursor];

    if (current.kind == StepKind.whitePause) {
      setState(() => opacity = 0.0);
      timer = Timer(current.delay ?? const Duration(seconds: 2), next);
      return;
    }

    if (current.kind == StepKind.continueFlow) {
      next();
      return;
    }

    if (current.kind == StepKind.end) {
      navigateToChat();
      return;
    }

    setState(() => opacity = 1.0);

    if (current.kind == StepKind.phrase ||
        current.kind == StepKind.phraseWithSub) {
      final total = current.delay ?? const Duration(seconds: 3);
      timer = Timer(total, () {
        setState(() => opacity = 0.0);
        timer = Timer(const Duration(milliseconds: 800), next);
      });
    }
  }

  void next() {
    if (cursor < steps.length - 1) {
      cursor++;
      showCurrent();
    } else {
      navigateToChat();
    }
  }

  void navigateToChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(luxName: luxName, userName: userName),
      ),
    );
  }

  void appendAndContinue(String text) {
    setState(() {
      steps.insert(cursor + 1, OnboardingStep.phrase(text));
    });
    next();
  }

  void setLuxCustomName() {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Escribe un nuevo nombre para mí'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nuevo nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              luxName = controller.text.trim().isEmpty
                  ? 'LUX'
                  : controller.text.trim();
              Navigator.pop(ctx, luxName);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    ).then(
      (value) => appendAndContinue(
        value != null
            ? 'Entiendo, a partir de ahora me llamaré "$value".'
            : 'Entiendo, seguiré siendo LUX.',
      ),
    );
  }

  void askUserName(OnboardingStep step) {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(step.question ?? ''),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Solo llámame Usuario'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    ).then((value) {
      userName = value?.isNotEmpty == true ? value! : 'Usuario';
      appendAndContinue(
        userName == 'Usuario'
            ? 'Entiendo, no quieres dar tu nombre.'
            : 'Entiendo, entonces te llamas "$userName".',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[cursor];
    final glow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: step.kind == StepKind.whitePause
          ? Colors.white
          : Theme.of(context).colorScheme.background,
      body: Center(
        child: step.kind == StepKind.phraseWithSub
            ? PhraseWithSubWidget(
                main: step.text ?? '',
                sub: step.sub ?? '',
                showSubAfter: step.delayBeforeSub ?? const Duration(seconds: 2),
                opacity: opacity,
                glow: glow,
              )
            : AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: opacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (step.kind == StepKind.choice)
                        ChoiceWidget(
                          text: step.text ?? '',
                          onYes: step.onYes ?? next,
                          onNo: step.onNo ?? next,
                          glow: glow,
                        )
                      else if (step.kind == StepKind.inputName)
                        InputPrompt(
                          question: step.question ?? '',
                          onPrompt: () => askUserName(step),
                          glow: glow,
                        )
                      else if (step.kind == StepKind.phrase)
                        Text(
                          step.text ?? '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: glow,
                                shadows: [
                                  Shadow(
                                    blurRadius: 18,
                                    color: glow.withOpacity(0.7),
                                  ),
                                  Shadow(
                                    blurRadius: 32,
                                    color: glow.withOpacity(0.4),
                                  ),
                                ],
                              ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    player.dispose();
    super.dispose();
  }
}
