import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/hey_button.dart';
import '../../widgets/hey_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordReset(_emailController.text);

    if (success && mounted) {
      setState(() => _isSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            authProvider.clearError();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: _isSuccess
              ? _buildSuccessView(isDark)
              : _buildFormView(isDark, authProvider),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark, AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your registered email address and we'll send you instructions to reset your password.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Error Banner
          if (authProvider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: HeyTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                border: Border.all(
                  color: HeyTheme.errorRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: HeyTheme.errorRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      authProvider.errorMessage!,
                      style: const TextStyle(
                        color: HeyTheme.errorRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: HeyTheme.errorRed),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => authProvider.clearError(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          HeyTextField(
            controller: _emailController,
            label: 'Registered Email',
            hint: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 28),

          HeyButton(
            text: 'Send Reset Link',
            isLoading: authProvider.isLoading,
            onPressed: _handleReset,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HeyTheme.onlineGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 48,
              color: HeyTheme.onlineGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Check Your Email',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "We have sent password reset instructions to ${_emailController.text.trim()}. Please check your inbox and spam folder.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          HeyButton(
            text: 'Back to Sign In',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
