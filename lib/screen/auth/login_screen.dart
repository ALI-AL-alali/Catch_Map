import 'package:flutter/material.dart';
import 'package:map/screen/auth/widgets/login/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: const LoginForm());
  }
}
