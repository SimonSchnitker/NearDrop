import 'package:flutter/material.dart';

class AnimatedFadeSwitcher extends StatelessWidget {
    /// Erstellt ein Widget, das einen sequenziellen Fade-Übergang zwischen
    /// einem alten und einem neuen Kind-Widget durchführt.
    /// Zuerst blendet das alte Kind aus, dann blendet das neue Kind ein.
    const AnimatedFadeSwitcher({
        super.key,
        required this.child,
        this.duration = const Duration(milliseconds: 300),
        this.curve = Curves.easeIn,
        this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
    });

    /// Das aktuelle Kind-Widget, das angezeigt werden soll.
    /// **Wichtig:** Das [child] sollte einen eindeutigen [Key] haben (z.B. ValueKey),
    /// damit der AnimatedSwitcher Änderungen korrekt erkennen kann.
    final Widget child;

    /// Die Dauer für jede einzelne Phase der Animation (Ausblenden oder Einblenden).
    /// Die Gesamtdauer der Animation im internen [AnimatedSwitcher] wird das Doppelte hiervon sein.
    final Duration duration;

    /// Die Animationskurve, die für das Ein- und Ausblenden während des Intervalls verwendet wird.
    final Curve curve;

    /// Eine Funktion, die bestimmt, wie das (möglicherweise) alte und neue Kind-Widget
    /// während der Transition im Widget-Baum angeordnet werden.
    /// Standard ist [AnimatedSwitcher.defaultLayoutBuilder].
    final AnimatedSwitcherLayoutBuilder layoutBuilder;

    @override
    Widget build(BuildContext context) {
        return AnimatedSwitcher(
            duration: Duration(milliseconds: duration.inMilliseconds * 2), // Gesamtdauer
            child: child, // Das Kind-Widget muss einen Key haben, um den Wechsel zu erkennen
            transitionBuilder: (Widget switcherChild, Animation<double> animation) {
                // Das eingehende Kind (switcherChild) soll in der zweiten Hälfte der Animation einfaden.
                // Das ausgehende Kind wird von AnimatedSwitcher mit der umgekehrten Animation behandelt.
                // Bei umgekehrter Animation bewirkt Interval(0.5, 1.0) ein Ausblenden in der ersten Hälfte.
                return FadeTransition(
                    opacity: CurvedAnimation(
                        parent: animation,
                        curve: Interval(0.5, 1.0, curve: this.curve),
                    ),
                    child: switcherChild,
                );
            },
            layoutBuilder: layoutBuilder,
        );
    }
}