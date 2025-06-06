import 'package:hyperchat_app/common_widget/round_button.dart';
import 'package:hyperchat_app/common_widget/round_textfield.dart';
import 'package:hyperchat_app/services/auth_service.dart';
import 'package:hyperchat_app/view/auth/login_view.dart';
import 'package:hyperchat_app/view/main_tab/main_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  bool isCheck = false;
  bool isLoading = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  String? _errorMessage;

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (!isCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        '${_firstNameController.text} ${_lastNameController.text}',
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainTabView()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainTabView()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'ERROR_ABORTED_BY_USER':
          message = 'Sign in was cancelled';
          break;
        case 'ERROR_NETWORK_REQUEST_FAILED':
          message = 'Network error occurred. Please check your connection.';
          break;
        default:
          message = 'Failed to sign in with Google: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during Google sign in')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Hey there,",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Create an Account",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: media.width * 0.2),
                    RoundTextField(
                      controller: _firstNameController,
                      hitText: "First Name",
                      icon: "assets/img/user_text.png",
                    ),
                    SizedBox(height: media.width * 0.04),
                    RoundTextField(
                      controller: _lastNameController,
                      hitText: "Last Name",
                      icon: "assets/img/user_text.png",
                    ),
                    SizedBox(height: media.width * 0.04),
                    RoundTextField(
                      controller: _emailController,
                      hitText: "Email",
                      icon: "assets/img/email.png",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: media.width * 0.04),
                    RoundTextField(
                      controller: _passwordController,
                      hitText: "Password",
                      icon: "assets/img/lock.png",
                      obscureText: true,
                      rigtIcon: TextButton(
                        onPressed: () {},
                        child: Container(
                          alignment: Alignment.center,
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            "assets/img/show_password.png",
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: media.width * 0.04),
                    RoundTextField(
                      controller: _confirmPasswordController,
                      hitText: "Confirm Password",
                      icon: "assets/img/lock.png",
                      obscureText: true,
                      rigtIcon: TextButton(
                        onPressed: () {},
                        child: Container(
                          alignment: Alignment.center,
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            "assets/img/show_password.png",
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isCheck = !isCheck;
                            });
                          },
                          icon: Icon(
                            isCheck ? Icons.check_circle : Icons.circle_outlined,
                            color: isCheck
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "By continuing you accept our Privacy Policy and Term of Use",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: media.width * 0.04),
                    RoundButton(
                      title: "Register",
                      onPressed: isLoading ? () {} : () => _register(),
                    ),
                    SizedBox(height: media.width * 0.04),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          "  Or  ",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: media.width * 0.04),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _signInWithGoogle,
                          child: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                width: 1,
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Image.asset(
                              "assets/img/google.png",
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginView(),
                              ),
                            );
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Theme.of(context).colorScheme.background.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
