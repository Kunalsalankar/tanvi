import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_cubit.dart';
import 'bloc/auth_state.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  bool isEditing = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize empty controllers
    nameController = TextEditingController();
    ageController = TextEditingController();
    heightController = TextEditingController();
    weightController = TextEditingController();
  }

  void _initializeControllers(AuthState authState) {
    if (!_controllersInitialized) {
      // Use mock data if real data is not available
      nameController.text = authState.name ?? 'Raj Kumar';
      ageController.text = (authState.age?.toString() ?? '22');
      heightController.text = (authState.height?.toString() ?? '178');
      weightController.text = (authState.weight?.toString() ?? '75');
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Initialize controllers on first build
        _initializeControllers(state);
        
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'My Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
            actions: [
              if (!isEditing)
                IconButton(
                  onPressed: () => setState(() => isEditing = true),
                  icon: const Icon(Icons.edit),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      final age = int.tryParse(ageController.text);
                      final height = double.tryParse(heightController.text);
                      final weight = double.tryParse(weightController.text);

                      if (age == null || height == null || weight == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter valid information'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      context.read<AuthCubit>().updateUserData(
                            name: nameController.text.trim(),
                            age: age,
                            height: height,
                            weight: weight,
                          );

                      setState(() => isEditing = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.name ?? 'Raj Kumar',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Profile Details
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Name Field
                      _buildProfileField(
                        label: 'Full Name',
                        icon: Icons.person,
                        controller: nameController,
                        enabled: isEditing,
                      ),
                      const SizedBox(height: 16),
                      // Age Field
                      _buildProfileField(
                        label: 'Age',
                        icon: Icons.cake,
                        controller: ageController,
                        enabled: isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      // Height Field
                      _buildProfileField(
                        label: 'Height (cm)',
                        icon: Icons.height,
                        controller: heightController,
                        enabled: isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Weight Field
                      _buildProfileField(
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight,
                        controller: weightController,
                        enabled: isEditing,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // BMI Calculation
                      if (!isEditing) _buildBMICard(state),
                      const SizedBox(height: 32),
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<AuthCubit>().logout();
                            Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            );
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled ? Colors.blue.shade600 : Colors.grey.shade300,
          width: enabled ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.blue.shade700 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.black87),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.blue.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildBMICard(AuthState state) {
    final height = state.height ?? 178;
    final weight = state.weight ?? 75;

    if (height == 0 || weight == 0) {
      return const SizedBox.shrink();
    }

    final heightInMeters = height / 100;
    final bmi = weight / (heightInMeters * heightInMeters);
    final bmiCategory = _getBMICategory(bmi);
    final bmiColor = _getBMIColor(bmi);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bmiColor.withOpacity(0.2), bmiColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: bmiColor),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Mass Index (BMI)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: bmiColor,
                    ),
                  ),
                  Text(
                    bmiCategory,
                    style: TextStyle(
                      fontSize: 14,
                      color: bmiColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bmiColor.withOpacity(0.1),
                  border: Border.all(color: bmiColor, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite,
                    size: 40,
                    color: bmiColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
