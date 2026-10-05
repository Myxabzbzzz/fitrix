import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // FITRIX Logo
              _buildLogo(),

              const SizedBox(height: 40),

              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBackground,
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://i.pravatar.cc/300',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.textSecondary,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Username
              const Text(
                '@theboss',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 40),

              // Name Input
              _buildInputField(
                controller: _nameController,
                label: 'Name',
              ),

              const SizedBox(height: 16),

              // Surname Input
              _buildInputField(
                controller: _surnameController,
                label: 'Surename',
              ),

              const SizedBox(height: 16),

              // Age Input
              _buildInputField(
                controller: _ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Weight Input
              _buildInputField(
                controller: _weightController,
                label: 'Weight',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Height Input
              _buildInputField(
                controller: _heightController,
                label: 'Height',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final profile = UserProfile(
                      name: _nameController.text,
                      surname: _surnameController.text,
                      age: _ageController.text,
                      weight: _weightController.text,
                      height: _heightController.text,
                    );
                    ref.read(profileProvider.notifier).saveProfile(profile);
                    context.go(AppRouter.chat);
                  },
                  child: const Text('Continue'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'FI',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
              letterSpacing: 2,
            ),
          ),
          TextSpan(
            text: 'TRIX',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }
}
