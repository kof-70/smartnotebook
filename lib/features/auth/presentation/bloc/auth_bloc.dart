import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/data/models/profile_model.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/get_current_user.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInWithGoogleRequested extends AuthEvent {}

class AuthSignInWithAppleRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final AuthState authState;

  const AuthStateChanged(this.authState);

  @override
  List<Object?> get props => [authState];
}

// States
abstract class AuthBlocState extends Equatable {
  const AuthBlocState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthBlocState {}

class AuthLoading extends AuthBlocState {}

class AuthAuthenticated extends AuthBlocState {
  final ProfileModel profile;

  const AuthAuthenticated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class AuthUnauthenticated extends AuthBlocState {}

class AuthError extends AuthBlocState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;

  AuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
  })  : _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _getCurrentUser();
    
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (profile) {
        if (profile != null) {
          emit(AuthAuthenticated(profile));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _signInWithGoogle();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (profile) => emit(AuthAuthenticated(profile)),
    );
  }

  Future<void> _onSignInWithAppleRequested(
    AuthSignInWithAppleRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _signInWithApple();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (profile) => emit(AuthAuthenticated(profile)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _signOut();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthBlocState> emit,
  ) {
    if (event.authState.session != null) {
      add(AuthCheckRequested());
    } else {
      emit(AuthUnauthenticated());
    }
  }
}