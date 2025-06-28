import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/zone_1_raw/presentation/bloc/note_bloc.dart';
import 'features/zone_1_raw/presentation/bloc/search_bloc.dart';
import 'features/zone_2_enhanced/presentation/bloc/ai_chat_bloc.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'shared/presentation/pages/main_page.dart';
import 'shared/presentation/themes/app_theme.dart';
import 'injection_container.dart' as di;

class SmartNotebookApp extends StatefulWidget {
  const SmartNotebookApp({super.key});

  @override
  State<SmartNotebookApp> createState() => _SmartNotebookAppState();
}

class _SmartNotebookAppState extends State<SmartNotebookApp> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>();
    
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _authBloc.add(AuthStateChanged(data));
    });
    
    // Check initial auth state
    _authBloc.add(AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _authBloc),
            BlocProvider(create: (_) => di.sl<NoteBloc>()),
            BlocProvider(create: (_) => di.sl<SearchBloc>()),
            BlocProvider(create: (_) => di.sl<AIChatBloc>()),
            BlocProvider(create: (_) => di.sl<SyncBloc>()),
          ],
          child: MaterialApp(
            title: 'Smart Notebook',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: BlocBuilder<AuthBloc, AuthBlocState>(
              builder: (context, state) {
                if (state is AuthLoading || state is AuthInitial) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (state is AuthAuthenticated) {
                  return const MainPage();
                }
                
                return const AuthPage();
              },
            ),
          ),
        );
      },
    );
  }
}