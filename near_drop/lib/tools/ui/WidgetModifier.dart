import 'package:flutter/material.dart';

extension WidgetModifier on Widget
{
    Widget paddingAll(double value)
    {
        return Padding(
            padding: EdgeInsets.all(value),
            child: this,
        );
    }

    Widget paddingOnly({double left = 0.0, double top = 0.0, double right = 0.0, double bottom = 0.0})
    {
        return Padding(
            padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
            child: this,
        );
    }

    Widget paddingSymmetric({double vertical = 0.0, double horizontal = 0.0})
    {
        return Padding(
            padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
            child: this,
        );
    }

    Widget safeArea()
    {
        return SafeArea(
            child: this,
        );
    }

    Widget align(Alignment alignment)
    {
        return Align(
            alignment: alignment,
            child: this,
        );
    }

    Widget expanded({int flex = 1})
    {
        return Expanded(
            flex: flex,
            child: this,
        );
    }

    Widget centered({Key? key, double? widthFactor, double? heightFactor})
    {
        return Center(
            key: key,
            widthFactor: widthFactor,
            heightFactor: heightFactor,
            child: this,
        );
    }

    Widget clickable({
        Key? key,
        void Function()? onTap,
        void Function()? onDoubleTap,
        void Function()? onLongPress,
        void Function(TapDownDetails)? onTapDown,
        void Function(TapUpDetails)? onTapUp,
        void Function()? onTapCancel,
        void Function()? onSecondaryTap,
        void Function(TapUpDetails)? onSecondaryTapUp,
        void Function(TapDownDetails)? onSecondaryTapDown,
        void Function()? onSecondaryTapCancel,
        void Function(bool)? onHighlightChanged,
        void Function(bool)? onHover,
        MouseCursor? mouseCursor,
        Color? focusColor,
        Color? hoverColor,
        Color? highlightColor,
        WidgetStateProperty<Color?>? overlayColor,
        Color? splashColor,
        InteractiveInkFeatureFactory? splashFactory,
        double? radius,
        BorderRadius? borderRadius,
        ShapeBorder? customBorder,
        bool enableFeedback = true,
        bool excludeFromSemantics = false,
        FocusNode? focusNode,
        bool canRequestFocus = true,
        void Function(bool)? onFocusChange,
        bool autofocus = false,
        WidgetStatesController? statesController,
        Duration? hoverDuration})
    {
        return InkWell(
            key: key,
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPress: onLongPress,
            onTapDown: onTapDown,
            onTapUp: onTapUp,
            onTapCancel: onTapCancel,
            onSecondaryTap: onSecondaryTap,
            onSecondaryTapUp: onSecondaryTapUp,
            onSecondaryTapDown: onSecondaryTapDown,
            onSecondaryTapCancel: onSecondaryTapCancel,
            onHighlightChanged: onHighlightChanged,
            onHover: onHover,
            mouseCursor: mouseCursor,
            focusColor: focusColor,
            hoverColor: hoverColor,
            highlightColor: highlightColor,
            overlayColor: overlayColor,
            splashColor: splashColor,
            splashFactory: splashFactory,
            radius: radius,
            borderRadius: borderRadius,
            customBorder: customBorder,
            enableFeedback: enableFeedback,
            excludeFromSemantics: excludeFromSemantics,
            focusNode: focusNode,
            canRequestFocus: canRequestFocus,
            onFocusChange: onFocusChange,
            autofocus: autofocus,
            statesController: statesController,
            hoverDuration: hoverDuration,
            child: this,
        );
    }
}