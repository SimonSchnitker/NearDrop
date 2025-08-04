import 'package:flutter/material.dart';
import 'package:near_drop/tools/ui/WidgetModifier.dart';

Future<void> showLoadingOverlay<T>(BuildContext context, Function() future) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
            return PopScope(
                canPop: false,
                child: CircularProgressIndicator(
                    strokeCap: StrokeCap.round,
                )
                .centered()
            );
        }
    );

    try
    {
        await future();
    }
    finally
    {
        Navigator.of(context).pop();
    }
}