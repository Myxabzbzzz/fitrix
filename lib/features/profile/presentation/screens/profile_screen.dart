import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
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
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // FITRIX Logo
              const FitrixLogo(fontSize: 36),

              const SizedBox(height: 40),

              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.tile,
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: palette.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Username
              Text(
                '@theboss',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
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
        hintStyle: TextStyle(
          color: AppPalette.of(context).textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }
}
