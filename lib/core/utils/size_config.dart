import 'package:flutter/widgets.dart';

class SizeConfig {
  const SizeConfig._(this._media);

  final MediaQueryData _media;

  factory SizeConfig.of(BuildContext context) =>
      SizeConfig._(MediaQuery.of(context));

  double get screenWidth => _media.size.width;
  double get screenHeight => _media.size.height;

  double widthPercent(double fraction) => screenWidth * fraction;
  double heightPercent(double fraction) => screenHeight * fraction;

  double safeWidthPercent(double fraction) {
    final safeWidth = screenWidth - _media.padding.horizontal;
    return safeWidth * fraction;
  }

  double safeHeightPercent(double fraction) {
    final safeHeight = screenHeight - _media.padding.vertical;
    return safeHeight * fraction;
  }
}
