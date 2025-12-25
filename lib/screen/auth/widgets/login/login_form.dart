// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:map/core/helpers/app_routes.dart';
import 'package:map/core/helpers/validators.dart';
import 'package:map/screen/driver_screen.dart';
import 'package:map/screen/map_screen.dart';
import 'package:map/services/auth_api.dart';
import 'package:map/widgets/custom_input.dart';

import '../../../../core/helpers/socket_events.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final email = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> login() async {
    if (formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final user = await AuthApi.login(
          email.text.trim(),
          password.text.trim(),
        );

        if (user?.userType == "customer") {

          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          );
        } else if (user?.userType == "driver") {
          final SocketEvents socketEvents = SocketEvents();
          socketEvents.openSocketConnection('driver:online','online');
          // socketEvents.listenToLocationUpdates();
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DriverScreen(driverName: user!.name),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("البريد الإلكتروني أو كلمة المرور غير صحيحة"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Container(
              width: size.width < 400 ? size.width : 400,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "تسجيل الدخول",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 30),

                    CustomInput(
                      hint: "البريد الإلكتروني",
                      controller: email,
                      validator: Validators.email,
                      icon: const Icon(Icons.email, color: Colors.blue),
                    ),
                    SizedBox(height: 20),

                    CustomInput(
                      hint: "كلمة المرور",
                      controller: password,
                      validator: Validators.password,
                      icon: const Icon(Icons.lock, color: Colors.blue),
                      obscureText: true,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              "تسجيل الدخول",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
