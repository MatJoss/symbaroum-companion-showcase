import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firebase_auth_service.dart';
import '../config/theme.dart';
import '../widgets/background_setter.dart';
import 'role_selection_screen.dart';

/// Écran de connexion Firebase
class FirebaseLoginScreen extends ConsumerStatefulWidget {
  const FirebaseLoginScreen({super.key});

  @override
  ConsumerState<FirebaseLoginScreen> createState() => _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends ConsumerState<FirebaseLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUpMode = false;
  
  FirebaseAuthService get _authService => FirebaseAuthService.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle Google Sign-In with forced account selection
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      // First sign out from Google to force account picker
      await GoogleSignIn().signOut();
      
      // Then sign in with Google
      await _authService.signInWithGoogle();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.signOut();
      await GoogleSignIn().signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Déconnexion réussie'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAuth() async {
    // Validation
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    if (_isSignUpMode) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Les mots de passe ne correspondent pas');
        return;
      }
      if (_passwordController.text.length < 6) {
        _showError('Le mot de passe doit contenir au moins 6 caractères');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authService = FirebaseAuthService.instance;
      
      if (_isSignUpMode) {
        await authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // If email verification is required, show an informative (non-error) message
        if (e is EmailVerificationRequired) {
          // If we were in sign-up mode, keep the password so the user
          // can reuse it when they return to login; if it was a login
          // attempt, clear the sensitive fields.
          final wasSignUp = _isSignUpMode;
          setState(() {
            _isSignUpMode = false;
            if (!wasSignUp) {
              _passwordController.clear();
              _confirmPasswordController.clear();
            }
          });

          // Show an interactive dialog allowing the user to resend verification
          // or to ask the app to re-check verification status.
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setStateDialog) {
                  bool doingResend = false;
                  bool doingCheck = false;

                  Future<void> resend() async {
                    print('🟢🟢🟢 resend() VÉRIFICATION APPELÉE 🟢🟢🟢');
                    setStateDialog(() => doingResend = true);
                    
                    try {
                      print('🔵 Appel sendVerificationEmail - DÉBUT');
                      print('🔵 Timestamp: ${DateTime.now()}');
                      
                      final stopwatch = Stopwatch()..start();
                      final ok = await _authService.sendVerificationEmail();
                      stopwatch.stop();
                      
                      print('✅ sendVerificationEmail terminé en ${stopwatch.elapsedMilliseconds}ms');
                      print('✅ Résultat ok: $ok');
                      print('✅ Timestamp: ${DateTime.now()}');
                      
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email de vérification renvoyé (${stopwatch.elapsedMilliseconds}ms)'),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Email de vérification demandé. Si vous ne le recevez pas, vérifiez vos spams.'),
                            backgroundColor: Colors.blue.shade700,
                          ),
                        );
                      }
                    } catch (err) {
                      print('❌ ERREUR: $err');
                      print('❌ Type: ${err.runtimeType}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors du renvoi: $err'),
                          backgroundColor: Colors.orange.shade700,
                        ),
                      );
                    } finally {
                      print('🔵 Finally resend()');
                      setStateDialog(() => doingResend = false);
                    }
                  }

                  Future<void> checkNow() async {
                    setStateDialog(() => doingCheck = true);
                    try {
                      bool ok = false;

                      // If no user is currently signed in, try to sign in using the
                      // email+password fields (this helps when the user signed up and
                      // was signed out). Only do this when both fields are present.
                      if (_authService.currentUser == null && _emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty) {
                        ok = await _authService.signInForVerificationCheck(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                        );
                      } else {
                        ok = await _authService.checkAndSyncEmailVerification();
                      }

                      if (ok) {
                        Navigator.of(context).pop();
                        // proceed to app
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                          );
                        }
                        return;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Email non vérifié. Vérifiez votre boîte et cliquez sur le lien.'),
                            backgroundColor: Colors.orange.shade700,
                          ),
                        );
                      }
                    } catch (err) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la vérification: $err'),
                          backgroundColor: Colors.red.shade900,
                        ),
                      );
                    } finally {
                      setStateDialog(() => doingCheck = false);
                    }
                  }

                  return AlertDialog(
                    title: const Text('Vérification email requise'),
                    content: Text(e.message),
                    actions: [
                      TextButton(
                            onPressed: doingResend
                                ? null
                                : () async {
                                    await resend();
                                  },
                            child: doingResend
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Renvoyer le mail'),
                      ),
                      ElevatedButton(
                            onPressed: doingCheck ? null : () => checkNow(),
                        child: doingCheck ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("J'ai vérifié — vérifier maintenant"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        } else {
          // If the error corresponds to a wrong password, offer a password reset
          final msg = e is AuthException ? e.message : e.toString();
          final lower = msg.toLowerCase();
          final isWrongPassword = lower.contains('mot de passe incorrect') || lower.contains('wrong-password') || lower.contains('incorrect');

          if (isWrongPassword) {
            // Show the password test/reset dialog
            await _showPasswordResetOrTestDialog();
          } else {
            _showError(e.toString());
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade900,
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _confirmPasswordController.clear();
    });
  }

  /// Show a dialog that allows the user to test a password or request a reset email
  Future<void> _showPasswordResetOrTestDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          final attemptController = TextEditingController();
          bool doingTest = false;
          bool doingReset = false;
          String? inlineError;

                  Future<void> testPassword() async {
                    setStateDialog(() {
                      doingTest = true;
                      inlineError = null;
                    });

                    try {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        setStateDialog(() => inlineError = 'Veuillez saisir l\'email');
                        return;
                      }
                      final attemptPassword = attemptController.text;
                      if (attemptPassword.isEmpty) {
                        setStateDialog(() => inlineError = 'Veuillez saisir le mot de passe');
                        return;
                      }

                      // Debug: indicate that a connection attempt starts (password length only)
                      debugPrint('Password dialog: attempting sign in for $email (pwd len ${attemptPassword.length})');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Tentative de connexion...'),
                          backgroundColor: Colors.blue.shade700,
                          duration: const Duration(seconds: 1),
                        ),
                      );

                      // Try signing in with provided credentials. Handle verification and wrong password.
                      try {
                        final user = await _authService.signInWithEmailAndPassword(
                          email: email,
                          password: attemptPassword,
                        );

                        debugPrint('Password dialog: sign in successful for ${user.uid}');

                        // Successful sign in -> navigate into the app
                        if (mounted) {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                          );
                        }
                      } on EmailVerificationRequired catch (ev) {
                        debugPrint('Password dialog: email verification required');
                        // Show verification info
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ev.message),
                            backgroundColor: Colors.blue.shade700,
                          ),
                        );
                      } on AuthException catch (ae) {
                        debugPrint('Password dialog: auth exception - ${ae.message}');
                        setStateDialog(() => inlineError = ae.message);
                        // Also show a non-intrusive snackbar for visibility
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ae.message),
                            backgroundColor: Colors.orange.shade700,
                          ),
                        );
                      } catch (err) {
                        debugPrint('Password dialog: unexpected error - $err');
                        setStateDialog(() => inlineError = err.toString());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $err'),
                            backgroundColor: Colors.orange.shade700,
                          ),
                        );
                      }
                    } finally {
                      setStateDialog(() => doingTest = false);
                    }
                  }

          Future<void> sendReset() async {
            print('🟢🟢🟢 sendReset() APPELÉE 🟢🟢🟢');
            setStateDialog(() => doingReset = true);
            
            try {
              final email = _emailController.text.trim();
              print('🔵 Email: $email');
              
              if (email.isEmpty) {
                print('❌ Email vide');
                setStateDialog(() => inlineError = 'Veuillez saisir votre email');
                return;
              }
              
              print('🔵 Appel sendPasswordResetEmail - DÉBUT');
              print('🔵 Timestamp: ${DateTime.now()}');
              
              final stopwatch = Stopwatch()..start();
              await _authService.sendPasswordResetEmail(email);
              stopwatch.stop();
              
              print('✅ Email envoyé en ${stopwatch.elapsedMilliseconds}ms');
              print('✅ Timestamp: ${DateTime.now()}');
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email de réinitialisation envoyé à $email (${stopwatch.elapsedMilliseconds}ms)'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            } catch (err) {
              print('❌ ERREUR: $err');
              print('❌ Type: ${err.runtimeType}');
              setStateDialog(() => inlineError = 'Erreur lors de l\'envoi: $err');
            } finally {
              print('🔵 Finally');
              setStateDialog(() => doingReset = false);
            }
          }

          return AlertDialog(
            title: const Text('Mot de passe incorrect'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Le mot de passe ne correspond pas. Vous pouvez réessayer ici ou demander un email de réinitialisation pour ${_emailController.text.trim()}.'),
                const SizedBox(height: 12),
                TextField(
                  controller: attemptController,
                  autofocus: true,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Saisir votre mot de passe',
                    hintText: '',
                    errorText: inlineError,
                  ),
                  onSubmitted: (_) => testPassword(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: doingTest
                    ? null
                    : () async {
                        debugPrint('Se connecter (dialog) pressed for ${_emailController.text.trim()}');
                        await testPassword();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: SymbaroumTheme.gold,
                  foregroundColor: SymbaroumTheme.darkBrown,
                ),
                child: doingTest
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Se connecter'),
              ),
              ElevatedButton(
                onPressed: doingReset ? null : () => sendReset(),
                child: doingReset ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Envoyer l\'email de réinitialisation'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundSetter(
      asset: 'assets/images/backgrounds/welcome_bg_free.png',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTitle(),
                const SizedBox(height: 64),
                _buildLoginCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildTitle() {
    return Column(
      children: [
        // Ligne décorative
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecorativeLine(),
            const SizedBox(width: 16),
            Icon(Icons.auto_awesome, color: SymbaroumTheme.gold.withValues(alpha: 0.8), size: 24),
            const SizedBox(width: 16),
            _buildDecorativeLine(),
          ],
        ),
        const SizedBox(height: 16),

        // Titre SYMBAROUM
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'SYMBAROUM',
            style: GoogleFonts.cinzel(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
              letterSpacing: 6,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(2, 2), blurRadius: 4),
                Shadow(color: SymbaroumTheme.gold.withValues(alpha: 0.3), offset: const Offset(0, 0), blurRadius: 10),
              ],
            ),
          ),
        ),

        // Sous-titre COMPANION
        Text(
          'COMPANION',
          style: GoogleFonts.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: SymbaroumTheme.parchment.withValues(alpha: 0.9),
            letterSpacing: 12,
          ),
        ),

        const SizedBox(height: 16),

        // Ligne décorative
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDecorativeLine(),
            const SizedBox(width: 16),
            Icon(Icons.auto_awesome, color: SymbaroumTheme.gold.withValues(alpha: 0.8), size: 24),
            const SizedBox(width: 16),
            _buildDecorativeLine(),
          ],
        ),
      ],
    );
  }

  Widget _buildDecorativeLine() {
    return Container(
      width: 60,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            SymbaroumTheme.gold.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35), // Vraie transparence
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SymbaroumTheme.gold.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Titre
          Text(
            _isSignUpMode ? 'CRÉER UN COMPTE' : 'CONNEXION',
            style: GoogleFonts.cinzel(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SymbaroumTheme.gold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 32),

          // Email
          TextField(
            controller: _emailController,
            style: TextStyle(color: SymbaroumTheme.parchment),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold, width: 2),
              ),
              prefixIcon: Icon(Icons.email, color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Password
          TextField(
            controller: _passwordController,
            style: TextStyle(color: SymbaroumTheme.parchment),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              labelStyle: TextStyle(color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: SymbaroumTheme.gold, width: 2),
              ),
              prefixIcon: Icon(Icons.lock, color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
            ),
            obscureText: true,
          ),
          // (Suppression du lien "mot de passe oublié" pour alléger l'écran)
          
          // Confirmation mot de passe (seulement en mode signup)
          if (_isSignUpMode) ...{
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              style: TextStyle(color: SymbaroumTheme.parchment),
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                labelStyle: TextStyle(color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: SymbaroumTheme.gold, width: 2),
                ),
                prefixIcon: Icon(Icons.lock_outline, color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
              ),
              obscureText: true,
            ),
          },
          const SizedBox(height: 32),

          // Bouton connexion/inscription
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: SymbaroumTheme.gold,
                foregroundColor: SymbaroumTheme.darkBrown,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 8,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isSignUpMode ? 'CRÉER UN COMPTE' : 'SE CONNECTER',
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Lien pour changer de mode
          TextButton(
            onPressed: _toggleMode,
            child: Text(
              _isSignUpMode 
                  ? 'Déjà un compte ? Se connecter' 
                  : 'Pas de compte ? S\'inscrire',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                color: SymbaroumTheme.gold.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
          ),
          
          // Séparateur "OU" et Google Sign-In (uniquement en mode connexion)
          if (!_isSignUpMode) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: SymbaroumTheme.gold.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OU',
                    style: GoogleFonts.cinzel(
                      color: SymbaroumTheme.gold.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: SymbaroumTheme.gold.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 16),

            // Bouton Google Sign-In
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: SymbaroumTheme.gold.withValues(alpha: 0.5), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
                icon: Icon(Icons.login, color: SymbaroumTheme.parchment),
                label: Text(
                  'GOOGLE',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SymbaroumTheme.parchment,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bouton de déconnexion Google
            TextButton.icon(
              onPressed: _isLoading ? null : _handleLogout,
              icon: Icon(Icons.logout, size: 16, color: SymbaroumTheme.gold.withValues(alpha: 0.7)),
              label: Text(
                'Changer de compte Google',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  color: SymbaroumTheme.gold.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
