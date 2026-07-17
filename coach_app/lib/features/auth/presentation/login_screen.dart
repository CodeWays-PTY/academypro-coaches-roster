import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import '../../dashboard/presentation/dashboard_screen.dart'; // We will build this next

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _resendTimerSeconds = 30;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimerSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendTimerSeconds--;
        });
      }
    });
  }

  void _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final success = await ref.read(authProvider.notifier).sendOtp(email);
      if (success) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully to email.')),
        );
      }
    }
  }

  void _handleVerifyOtp() async {
    final otp = _otpController.text;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP code.')),
      );
      return;
    }
    
    final success = await ref.read(authProvider.notifier).verifyOtp(otp);
    if (success) {
      // Upon successful authentication, route to DashboardCommandCenter
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticating = authState.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // uSPORT Branding Logo section
              const Icon(
                Icons.sports_rugby,
                size: 64.0,
                color: Color(0xFF2563EB), // Electric Blue
              ),
              const SizedBox(height: 16.0),
              const Text(
                'uSPORT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A), // Slate 900
                  letterSpacing: -1.0,
                ),
              ),
              const Text(
                'COACH COMMAND CENTER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B), // Slate 500
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40.0),

              // Form Container Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authState.status == AuthStatus.unauthenticated || authState.status == AuthStatus.error) ...[
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Enter your registered email address to request a one-time login code.',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'e.g. coach.ross@overkruin.co.za',
                              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email address';
                              }
                              // Simple email regex validation
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24.0),
                          if (authState.errorMessage != null) ...[
                            Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13.0),
                            ),
                            const SizedBox(height: 12.0),
                          ],
                          ElevatedButton(
                            onPressed: isAuthenticating ? null : _handleSendOtp,
                            child: isAuthenticating
                                ? const SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                                  )
                                : const Text('Send Login Code'),
                          ),
                        ] else if (authState.status == AuthStatus.otpSent) ...[
                          const Text(
                            'Verify Code',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'We sent a 6-digit login code to:\n${authState.email}',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8.0,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'One-Time Code',
                              hintText: '******',
                              counterText: '',
                              prefixIcon: Icon(Icons.lock_open_outlined, color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          if (authState.errorMessage != null) ...[
                            Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13.0),
                            ),
                            const SizedBox(height: 12.0),
                          ],
                          ElevatedButton(
                            onPressed: isAuthenticating ? null : _handleVerifyOtp,
                            child: isAuthenticating
                                ? const SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                                  )
                                : const Text('Verify & Sign In'),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  ref.read(authProvider.notifier).logout();
                                },
                                child: const Text('Back to Login'),
                              ),
                              TextButton(
                                onPressed: _resendTimerSeconds > 0
                                    ? null
                                    : () {
                                        ref.read(authProvider.notifier).sendOtp(authState.email!);
                                        _startResendTimer();
                                      },
                                child: Text(_resendTimerSeconds > 0
                                    ? 'Resend in ${_resendTimerSeconds}s'
                                    : 'Resend Code'),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
