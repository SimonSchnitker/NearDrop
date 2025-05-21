import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class PulsingCirclesLoader extends StatefulWidget {
    final Color? color1;
    final Color? color2;
    final Color? color3;
    final Duration duration;

    const PulsingCirclesLoader({
        super.key,
        this.color1, // Standardmäßig Theme.of(context).colorScheme.primary
        this.color2, // Standardmäßig Theme.of(context).colorScheme.primary
        this.color3, // Standardmäßig Theme.of(context).colorScheme.primary
        this.duration = const Duration(milliseconds: 4500), // Noch langsamere Animation
    });

    @override
    State<PulsingCirclesLoader> createState() => _PulsingCirclesLoaderState();
}

class _PulsingCirclesLoaderState extends State<PulsingCirclesLoader>
    with SingleTickerProviderStateMixin {
    late AnimationController _controller;

    // Gemeinsame Tweens für die Animationslogik aller Kreise
    late Tween<double> _scaleTween;
    late TweenSequence<double> _opacityTweenSequence;

    static const int _numberOfCircles = 3;

    @override
    void initState() {
        super.initState();

        _controller = AnimationController(
            vsync: this,
            duration: widget.duration,
        )..repeat();

        _scaleTween = Tween<double>(begin: 0.1, end: Platform.isAndroid || Platform.isIOS ? 1.0 : 0.75);

        _opacityTweenSequence = TweenSequence<double>([
            // Schnelles Einfaden (z.B. erste 10% der Animationszeit des jeweiligen Kreises)
            TweenSequenceItem(
                tween: Tween<double>(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeIn)), // Schnell rein
                weight: 10.0, // Nimmt 10% der Zeit in Anspruch
            ),
            // Langsames Ausfaden (z.B. restliche 90% der Animationszeit des jeweiligen Kreises)
            TweenSequenceItem(
                tween: Tween<double>(begin: 1.0, end: 0.0)
                    .chain(CurveTween(curve: Curves.easeOut)), // Langsam raus
                weight: 90.0, // Nimmt 90% der Zeit in Anspruch
            ),
        ]);
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    Widget _buildCircle(
        BuildContext context,
        double progress,
        Color color,
        double maxSize,
        ) {
        if (maxSize <= 0) return const SizedBox.shrink();

        // Stelle sicher, dass der Fortschritt immer im Bereich [0, 1] liegt für die Tweens
        final double normalizedProgress = progress.clamp(0.0, 1.0);

        final double currentScale = _scaleTween.transform(normalizedProgress);
        final double currentOpacity = _opacityTweenSequence.transform(normalizedProgress);

        return Opacity(
            opacity: currentOpacity.clamp(0.0, 1.0), // Zusätzliche Sicherheit
            child: Transform.scale(
                scale: currentScale.clamp(0.0, 1.0), // Zusätzliche Sicherheit
                child: Container(
                    width: maxSize,
                    height: maxSize,
                    decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                    ),
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        final ThemeData theme = Theme.of(context);
        // Standardfarben aus dem Theme holen, falls nicht explizit gesetzt
        final Color effectiveColor1 = widget.color1 ?? theme.colorScheme.primary;
        final Color effectiveColor2 = widget.color2 ?? theme.colorScheme.primary;
        final Color effectiveColor3 = widget.color3 ?? theme.colorScheme.primary;

        return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
                // Aktueller Fortschritt des Hauptcontrollers (0.0 bis 1.0)
                final double controllerValue = _controller.value;
                final double interCircleDelay = 1.0 / _numberOfCircles;

                // Fortschrittswerte für jeden Kreis berechnen, gleichmäßig versetzt
                final List<double> progresses = List.generate(_numberOfCircles, (index) {
                    return (controllerValue - (index * interCircleDelay) + 1.0) % 1.0;
                });

                final List<Color> colors = [effectiveColor1, effectiveColor2, effectiveColor3];

                return LayoutBuilder(
                    builder: (context, constraints) {
                        final double maxSize = math.min(constraints.maxWidth, constraints.maxHeight);

                        if (maxSize.isInfinite || maxSize.isNaN || maxSize <= 0) {
                            return const SizedBox.shrink();
                        }

                        return Stack(
                            alignment: Alignment.center,
                            children: List.generate(_numberOfCircles, (index) {
                                return _buildCircle(
                                    context,
                                    progresses[index],
                                    colors[index],
                                    maxSize,
                                );
                            }),
                        );
                    },
                );
            },
        );
    }
}