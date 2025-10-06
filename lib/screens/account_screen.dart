import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  final String languageCode;

  const AccountScreen({
    super.key,
    required this.languageCode,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _languageCode = 'tr';
  bool _isLoading = false;
  bool _isEditing = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.languageCode;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await ProfileService.getProfile();
      if (profile != null) {
        setState(() {
          _profile = profile;
          _fullNameController.text = profile.fullName ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _locationController.text = profile.location ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('error_occurred', _languageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('account', _languageCode)),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveProfile : _toggleEdit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),
                  _buildProfileForm(),
                  const SizedBox(height: 32),
                  _buildSignOutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _profile?.fullName ?? AppLocalizations.get('no_name', _languageCode),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.get('profile_info', _languageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('full_name', _languageCode),
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.get('name_required', _languageCode);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('age', _languageCode),
                  prefixIcon: const Icon(Icons.cake),
                  border: const OutlineInputBorder(),
                ),
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return AppLocalizations.get('age_invalid', _languageCode);
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.get('location', _languageCode),
                  prefixIcon: const Icon(Icons.location_on),
                  border: const OutlineInputBorder(),
                ),
                enabled: _isEditing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          AppLocalizations.get('sign_out', _languageCode),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = UserProfile(
        id: AuthService.getCurrentUser()!.id,
        email: AuthService.getCurrentUser()!.email!,
        fullName: _fullNameController.text.trim(),
        age: int.tryParse(_ageController.text),
        location: _locationController.text.trim(),
      );

      await ProfileService.updateProfile(profile);
      
      setState(() {
        _profile = profile;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('profile_updated', _languageCode)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.get('error_occurred', _languageCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.get('sign_out', _languageCode)),
        content: Text(AppLocalizations.get('sign_out_confirm', _languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.get('cancel', _languageCode)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.get('sign_out', _languageCode),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.get('error_occurred', _languageCode)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}