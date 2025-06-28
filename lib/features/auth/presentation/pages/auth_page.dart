import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../bloc/auth_bloc.dart';
import '../../../../core/constants/app_constants.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: BlocListener<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacing24),
            child: Column(
              children: [
                const Spacer(),
                
                // App Logo and Title
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacing24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacing32),
                
                Text(
                  'Smart Notebook',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacing16),
                
                Text(
                  'Your AI-powered personal notebook\nwith privacy at its core',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Sign in buttons
                BlocBuilder<AuthBloc, AuthBlocState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    
                    return Column(
                      children: [
                        // Google Sign In
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : () {
                              context.read<AuthBloc>().add(AuthSignInWithGoogleRequested());
                            },
                            icon: isLoading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Image.asset(
                                    'assets/icons/google.png',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.login,
                                        size: 20,
                                        color: theme.colorScheme.onPrimary,
                                      );
                                    },
                                  ),
                            label: Text(
                              isLoading ? 'Signing in...' : 'Continue with Google',
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppConstants.spacing16),
                        
                        // Apple Sign In (iOS only)
                        if (Platform.isIOS) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : () {
                                context.read<AuthBloc>().add(AuthSignInWithAppleRequested());
                              },
                              icon: isLoading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.apple,
                                      size: 20,
                                      color: theme.colorScheme.onSurface,
                                    ),
                              label: Text(
                                isLoading ? 'Signing in...' : 'Continue with Apple',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
                                foregroundColor: theme.colorScheme.onSurface,
                                side: BorderSide(color: theme.colorScheme.outline),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AppConstants.spacing24),
                        ],
                      ],
                    );
                  },
                ),
                
                // Privacy notice
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy. Your data is encrypted and stored securely.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.spacing32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}