import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visionai/providers/language_provider.dart';
import 'package:visionai/utils/app_localizations.dart';

/// A base screen widget that provides localization support.
/// Use this as a base for all screens to ensure localization is available.
class BaseScreen extends StatelessWidget {
  final Widget Function(BuildContext context, Map<String, String> localizedStrings) builder;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  
  const BaseScreen({
    Key? key,
    required this.builder,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final localizedStrings = AppLocalizations.getLocalizedStrings(context);
        
        return Scaffold(
          appBar: appBar,
          backgroundColor: backgroundColor,
          bottomNavigationBar: bottomNavigationBar,
          drawer: drawer,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: builder(context, localizedStrings),
        );
      },
    );
  }
} 