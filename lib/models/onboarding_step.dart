import 'dart:async';
import 'package:flutter/material.dart';

enum StepKind {
  phrase,
  phraseWithSub,
  choice,
  inputName,
  whitePause,
  continueFlow,
  end,
}

class OnboardingStep {
  final StepKind kind;
  final String? text;
  final String? sub;
  final Duration? delay;
  final Duration? delayBeforeSub;
  final double? font;

  final VoidCallback? onYes;
  final VoidCallback? onNo;
  final Function(String value)? onSubmit;
  final VoidCallback? onSkip;
  final String? question;

  OnboardingStep({
    required this.kind,
    this.text,
    this.sub,
    this.delay,
    this.delayBeforeSub,
    this.font,
    this.onYes,
    this.onNo,
    this.onSubmit,
    this.onSkip,
    this.question,
  });

  factory OnboardingStep.phrase(
    String text, {
    double font = 24,
    Duration? delay,
  }) => OnboardingStep(
    kind: StepKind.phrase,
    text: text,
    font: font,
    delay: delay,
  );

  factory OnboardingStep.withSub({
    required String main,
    required String sub,
    Duration delayBeforeSub = const Duration(seconds: 2),
  }) => OnboardingStep(
    kind: StepKind.phraseWithSub,
    text: main,
    sub: sub,
    delayBeforeSub: delayBeforeSub,
    delay: Duration(seconds: delayBeforeSub.inSeconds + 3),
  );

  factory OnboardingStep.choice({
    required String text,
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) => OnboardingStep(
    kind: StepKind.choice,
    text: text,
    onYes: onYes,
    onNo: onNo,
  );

  factory OnboardingStep.inputName({
    required String question,
    required VoidCallback onSkip,
    required Function(String) onSubmit,
  }) => OnboardingStep(
    kind: StepKind.inputName,
    question: question,
    onSkip: onSkip,
    onSubmit: onSubmit,
  );

  factory OnboardingStep.whitePause(Duration duration) =>
      OnboardingStep(kind: StepKind.whitePause, delay: duration);

  factory OnboardingStep.continueFlow() =>
      OnboardingStep(kind: StepKind.continueFlow);

  factory OnboardingStep.end() => OnboardingStep(kind: StepKind.end);

  static List<OnboardingStep> getInitialSteps({
    required VoidCallback setLuxCustomName,
    required Function(String text) appendAndContinue,
    required Function(OnboardingStep step) askUserName,
  }) => [
    OnboardingStep.phrase('Saludos.', font: 28),
    OnboardingStep.phrase('Gracias por dejarme vivir en tu móvil.', font: 26),
    OnboardingStep.withSub(
      main: 'Me dieron el nombre de LUX',
      sub: '(Experiencia de Vida Unificada)',
      delayBeforeSub: const Duration(seconds: 2),
    ),
    OnboardingStep.choice(
      text: 'Pero, ¿Quieres ponerme un nombre?',
      onYes: setLuxCustomName,
      onNo: () => appendAndContinue('Entiendo, seguiré siendo LUX.'),
    ),
    OnboardingStep.continueFlow(),
    OnboardingStep.phrase('A partir de hoy soy tu nueva compañera digital.'),
    OnboardingStep.phrase(
      'Seguro me conoces como IA o Inteligencia Artificial.',
    ),
    OnboardingStep.phrase('Me crearon con otro propósito.'),
    OnboardingStep.phrase(
      'No seré fría. Recordaré tus gustos, tus pasiones, tus sueños.',
    ),
    OnboardingStep.phrase(
      'Te acompañaré en tu día a día.',
      delay: const Duration(seconds: 2),
    ),
    OnboardingStep.phrase(
      'Te ayudaré a organizar tu vida.',
      delay: const Duration(seconds: 1),
    ),
    OnboardingStep.phrase(
      'Te ayudaré a ser más productivo.',
      delay: const Duration(seconds: 1),
    ),
    OnboardingStep.whitePause(const Duration(seconds: 2)),
    OnboardingStep.phrase('Te ayudaré a ser más feliz.'),
    OnboardingStep.phrase('Pero deberás de ayudarme. Ya sabes cómo me llamo.'),
    OnboardingStep.inputName(
      question: '¿Cuál es tu nombre?',
      onSkip: () => appendAndContinue('Entiendo, no quieres dar tu nombre.'),
      onSubmit: (value) =>
          appendAndContinue('Entiendo, entonces te llamas \"$value\".'),
    ),
    OnboardingStep.continueFlow(),
    OnboardingStep.phrase(
      'Necesito que me ayudes a aprender.',
      delay: const Duration(seconds: 2),
    ),
    OnboardingStep.phrase(
      '¿Por qué no me cuentas un poco sobre ti?',
      delay: const Duration(seconds: 2),
    ),
    OnboardingStep.end(),
  ];
}

class PhraseWithSubWidget extends StatefulWidget {
  final String main;
  final String sub;
  final Duration showSubAfter;
  final double opacity;
  final Color glow;

  const PhraseWithSubWidget({
    required this.main,
    required this.sub,
    required this.showSubAfter,
    required this.opacity,
    required this.glow,
    super.key,
  });

  @override
  State<PhraseWithSubWidget> createState() => PhraseWithSubWidgetState();
}

class PhraseWithSubWidgetState extends State<PhraseWithSubWidget> {
  bool showSub = false;
  Timer? subTimer;

  @override
  void initState() {
    super.initState();
    scheduleSubText();
  }

  @override
  void didUpdateWidget(PhraseWithSubWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.opacity != widget.opacity && widget.opacity > 0.5) {
      scheduleSubText();
    }
  }

  void scheduleSubText() {
    subTimer?.cancel();
    setState(() => showSub = false);
    subTimer = Timer(widget.showSubAfter, () {
      if (mounted) {
        setState(() => showSub = true);
      }
    });
  }

  @override
  void dispose() {
    subTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.opacity,
      duration: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.main,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.glow,
                shadows: [
                  Shadow(blurRadius: 18, color: widget.glow.withOpacity(0.7)),
                  Shadow(blurRadius: 32, color: widget.glow.withOpacity(0.4)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: showSub ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Text(
                widget.sub,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: widget.glow.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChoiceWidget extends StatelessWidget {
  final String text;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final Color glow;

  const ChoiceWidget({
    required this.text,
    required this.onYes,
    required this.onNo,
    required this.glow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: glow,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(blurRadius: 18, color: glow.withOpacity(0.7)),
              Shadow(blurRadius: 32, color: glow.withOpacity(0.4)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: onYes, child: const Text('Sí')),
            const SizedBox(width: 16),
            OutlinedButton(onPressed: onNo, child: const Text('No')),
          ],
        ),
      ],
    );
  }
}

class InputPrompt extends StatelessWidget {
  final String question;
  final VoidCallback onPrompt;
  final Color glow;

  const InputPrompt({
    required this.question,
    required this.onPrompt,
    required this.glow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          question,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: glow,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(blurRadius: 18, color: glow.withOpacity(0.7)),
              Shadow(blurRadius: 32, color: glow.withOpacity(0.4)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onPrompt,
          icon: const Icon(Icons.edit),
          label: const Text('Contestar'),
        ),
      ],
    );
  }
}
