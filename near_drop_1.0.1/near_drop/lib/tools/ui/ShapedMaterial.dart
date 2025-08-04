import 'package:flutter/material.dart';

enum ShapePosition
{
    start,
    middle,
    end,
    only
}

class ShapedMaterial extends StatelessWidget {
    final Widget child;
    final Color? color;
    final ShapePosition shapePosition;
    final Function()? onTap;


    const ShapedMaterial({
        super.key,
        this.color,
        this.onTap,
        required this.shapePosition,
        required this.child,
    });

    @override
    Widget build(BuildContext context) {
        final BorderRadius borderRadius;
        switch (shapePosition) {
            case ShapePosition.start:
                borderRadius = BorderRadius.vertical(
                    top: Radius.circular(24),
                    bottom: Radius.circular(4),
                );
                break;
            case ShapePosition.middle:
                borderRadius = BorderRadius.all(Radius.circular(4));
                break;
            case ShapePosition.end:
                borderRadius = BorderRadius.vertical(
                    top: Radius.circular(4),
                    bottom: Radius.circular(24),
                );
                break;
          case ShapePosition.only:
              borderRadius = BorderRadius.all(Radius.circular(24));
              break;
        }

        return Material(
            color: color ?? Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: borderRadius,
            child: InkWell(
                borderRadius: borderRadius,
                onTap: onTap,
                child: child,
            ),
        );
    }
}