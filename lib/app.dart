import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/router/app_router.dart';
import 'core/theme/finishx_theme.dart';

class FinishXApp extends ConsumerWidget {
  const FinishXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FinishX — One Journey. Full Focus.',
      debugShowCheckedModeBanner: false,
      theme: FinishXTheme.lightTheme,
      routerConfig: router,
    );
  }
}
