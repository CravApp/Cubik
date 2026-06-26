// lib/features/auth/presentation/screens/login_screen.dart
//
// Pantalla de login con el logo real de Kubik.
// Usa los dos colores del logo de forma coherente:
//   • Botón principal  → kubikBlue  (#6164B1)
//   • Botón secundario → borde kubikBlue, texto kubikBlue
//   • "Registrarse"    → kubikCoral (#EF665C)
//   • Logo container   → degradado coral → azul

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading   = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.06),

                // ── Logo oficial centrado ─────────────────────────
                Center(
                  child: Column(
                    children: [
                      // Contenedor con degradado coral→azul del logo
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.kubikCoral, AppTheme.kubikBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.kubikBlue.withValues(alpha: 0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/kubik_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Nombre de la app con los dos colores del logo
                      RichText(
                        text: const TextSpan(
                          text: 'Kubik',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kubikBlue,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        'Organiza tu día con inteligencia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .fade(duration: 400.ms),

                SizedBox(height: size.height * 0.05),

                // ── Saludo ────────────────────────────────────────
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kubikDark,
                    fontFamily: 'Poppins',
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 4),
                Text(
                  'Inicia sesión para gestionar tus tareas',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontFamily: 'Poppins',
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 28),

                // ── Campo Email ──────────────────────────────────
                _FieldLabel('Correo electrónico'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'tu@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.kubikBlue,
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // ── Campo Contraseña ──────────────────────────────
                _FieldLabel('Contraseña'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: AppTheme.kubikBlue,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 8),

                // ── Olvidé mi contraseña ──────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: AppTheme.kubikCoral,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Botón Iniciar Sesión (kubikBlue) ─────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kubikBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                // Divisor "o"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o', style: TextStyle(
                        color: Colors.grey.shade400, fontFamily: 'Poppins', fontSize: 12,
                      )),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ],
                ).animate().fadeIn(delay: 550.ms),

                const SizedBox(height: 12),

                // ── Botón Continuar sin cuenta ───────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.kubikBlue,
                      side: const BorderSide(color: AppTheme.kubikBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text(
                      'Continuar sin cuenta',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 28),

                // ── ¿No tienes cuenta? Regístrate ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta?  ',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                          color: AppTheme.kubikCoral,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                SizedBox(height: size.height * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.kubikDark,
        fontFamily: 'Poppins',
      ),
    );
  }
}
