import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
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

  /// Field → error, shown after the first Continue tap.
  Map<String, String> _errors = const {};
  bool _submitted = false;

  List<TextEditingController> get _controllers => [
        _nameController,
        _surnameController,
        _ageController,
        _weightController,
        _heightController,
      ];

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  /// Fills in what's already known: a profile restored from the account,
  /// or one typed earlier on this device.
  Future<void> _prefill() async {
    final profile = await ref.read(profileRepositoryProvider).getProfile();
    if (profile == null || !mounted) return;
    if (_controllers.any((c) => c.text.isNotEmpty)) return;
    _nameController.text = profile.name;
    _surnameController.text = profile.surname;
    _ageController.text = profile.age;
    _weightController.text = profile.weight;
    _heightController.text = profile.height;
  }

  UserProfile _currentProfile() => UserProfile(
        name: _nameController.text,
        surname: _surnameController.text,
        age: _ageController.text,
        weight: _weightController.text,
        height: _heightController.text,
      );

  Future<void> _continue() async {
    final errors = ProfileValidator.validate(_currentProfile());
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.isNotEmpty) return;

    final profile = ProfileValidator.normalize(_currentProfile());
    await ref.read(profileProvider.notifier).saveProfile(profile);
    // Uploaded in the background; retried later if offline.
    unawaited(ref.read(accountServiceProvider)?.profileChanged());
    if (mounted) context.go(AppRouter.chat);
  }

  void _revalidate() {
    if (!_submitted) return;
    setState(() => _errors = ProfileValidator.validate(_currentProfile()));
  }

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
                field: 'name',
              ),

              const SizedBox(height: 16),

              // Surname Input
              _buildInputField(
                controller: _surnameController,
                label: 'Surname',
                field: 'surname',
              ),

              const SizedBox(height: 16),

              // Age Input
              _buildInputField(
                controller: _ageController,
                label: 'Age',
                field: 'age',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Weight Input
              _buildInputField(
                controller: _weightController,
                label: 'Weight, kg',
                field: 'weight',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 16),

              // Height Input
              _buildInputField(
                controller: _heightController,
                label: 'Height, cm',
                field: 'height',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _continue,
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
    required String field,
    TextInputType? keyboardType,
  }) {
    return TextField(
      key: Key('profile-$field'),
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      textInputAction: TextInputAction.next,
      onChanged: (_) => _revalidate(),
      decoration: InputDecoration(
        hintText: label,
        errorText: _errors[field],
        errorMaxLines: 2,
        hintStyle: TextStyle(
          color: AppPalette.of(context).textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }
}
