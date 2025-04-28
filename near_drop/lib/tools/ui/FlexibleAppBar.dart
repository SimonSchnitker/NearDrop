import 'package:flutter/material.dart';

Widget FlexibleAppBar({required String title, Widget? leading, List<Widget>? actions}) {
    return SliverAppBar.large(
        flexibleSpace: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
                var currentHeight = constraints.biggest.height;

                double collapsedHeight = 64 + MediaQuery.of(context).padding.top;
                double expandedHeight = 180 + MediaQuery.of(context).padding.top;
                double collapsedLeftPadding = 72;
                double expandedLeftPadding = 16;

                // Padding-Lerp berechnen
                var padding = collapsedLeftPadding + (currentHeight - collapsedHeight) * (expandedLeftPadding - collapsedLeftPadding) / (expandedHeight - collapsedHeight);
                if (padding < 0) padding = 0;

                return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: padding, bottom: 16),
                    expandedTitleScale: 1.9,
                    title: Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                        ),
                    ),
                );
            },
        ),
        expandedHeight: 180,
        leading: leading,
        actions: actions,
    );
}