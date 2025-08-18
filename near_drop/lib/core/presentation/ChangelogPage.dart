import 'package:flutter/material.dart';
import 'package:near_drop/tools/ui/ShapedMaterial.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';

class ChangelogPage extends StatelessWidget
{
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Icon(
                        Icons.notifications_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                    ).align(Alignment.topLeft),
                    SizedBox(height: 40),
                    Text(
                        "Version 2.0.0 ist da!",
                        style: Theme.of(context).textTheme.displaySmall!.copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 24),
                    ShapedMaterial(
                        shapePosition: ShapePosition.start,
                        child: Row(
                            spacing: 16,
                            children: [
                                Text(
                                    "🚀",
                                    style: Theme.of(context).textTheme.displaySmall,
                                ),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Bis zu 8x schnellere Übertragung",
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                      SizedBox(height: 4),
                                      Text("Wir haben die Übertragungsgeschwindigkeit erheblich verbessert, damit deine Dateien noch schneller übertragen werden.",),
                                  ],
                                ).expanded(),
                            ],
                        ).paddingAll(16),
                    ),
                    SizedBox(height: 4),
                    ShapedMaterial(
                        shapePosition: ShapePosition.end,
                        child: Row(
                            spacing: 16,
                            children: [
                                Text(
                                    "📂",
                                    style: Theme.of(context).textTheme.displaySmall,
                                ),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text("Nur Android", style: TextStyle(color: Theme.of(context).colorScheme.primary).copyWith(fontWeight: FontWeight.w500),),
                                        SizedBox(height: 8),
                                        Text("Dateien vom Teilen-Menü senden",
                                            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                        SizedBox(height: 0),
                                        Text("Wähle bspw. in deiner Fotos-App teilen, um Dateien direkt an andere Geräte zu senden."),
                                    ],
                                ).expanded(),
                            ],
                        ).paddingAll(16),
                    ),
                    Spacer(),
                    FilledButton(
                        onPressed: () async {

                        },
                        child: Text("Schließen"),
                    ).sized(height: 60),
                ],
            ).safeArea().paddingAll(16),
        );
    }
}