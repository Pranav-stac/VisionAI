import 'package:flutter/material.dart';
import 'package:visionai/widgets/custom_text_field.dart';
import 'package:visionai/screens/home/home_screen.dart';
import 'package:visionai/services/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _selectedUserType = 'User';
  final List<String> _userTypes = ['User', 'Volunteer', 'Caregiver'];
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await _authService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (credential != null && credential.user != null) {
          // Save additional user info to Firebase Database
          final userId = credential.user!.uid;
          
          try {
            // Create user details map
            final userData = {
              'fullName': _nameController.text,
              'email': _emailController.text,
              'type': _selectedUserType,
              'createdAt': DateTime.now().toIso8601String(),
              'verified': false,
              'online': true,
              'last_seen': ServerValue.timestamp,
            };
            
            // Set user data in the database
            await FirebaseDatabase.instance
                .ref()
                .child('users/$userId')
                .set(userData);
            
            // Navigate to home screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } catch (dbError) {
            print('Database error: $dbError');
            _showErrorDialog('Failed to save user data: $dbError');
          }
        }
      } catch (e) {
        _showErrorDialog(e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      print('Register screen: Starting Google sign-up process');
      final credential = await _authService.signInWithGoogle();
      
      // Check if we're signed in regardless of credential return value
      if (_authService.currentUser != null) {
        print('Register screen: User is signed in, navigating to home');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (credential != null) {
        print('Register screen: Google sign-up successful, navigating to home');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        print('Register screen: Google sign-up cancelled by user');
      }
    } catch (e) {
      print('Register screen: Google sign-up error: $e');
      _showErrorDialog('Google Sign-Up Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _socialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800] 
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }

  Row _buildSocialSignUpButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _socialLoginButton(
          icon: Icons.g_mobiledata,
          color: Colors.red,
          onPressed: _signUpWithGoogle,
        ),
        _socialLoginButton(
          icon: Icons.facebook,
          color: Colors.blue,
          onPressed: () {
            _showErrorDialog('Facebook sign-up is not implemented yet');
          },
        ),
        _socialLoginButton(
          icon: Icons.apple,
          color: Colors.black,
          onPressed: () {
            _showErrorDialog('Apple sign-up is not implemented yet');
          },
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Join Vision AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account to access all features',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I am a:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _userTypes.length,
                          itemBuilder: (context, index) {
                            final userType = _userTypes[index];
                            final isSelected = userType == _selectedUserType;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedUserType = userType;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      userType,
                                      style: TextStyle(
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'Create a password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        hintText: 'Confirm your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      if (_selectedUserType == 'User')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accessibility Preferences',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'You can customize your accessibility preferences after registration in the settings menu.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_selectedUserType == 'Volunteer')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Volunteer Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'You will need to complete your volunteer profile after registration to start helping others.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'By signing up, you agree to our ',
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to terms and conditions
                            },
                            child: Text(
                              'Terms & Privacy Policy',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or sign up with',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSocialSignUpButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 