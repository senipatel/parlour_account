import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/services/firebase/auth_service.dart';
import 'package:parlour_account/services/firebase/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();
  bool _initializedName = false;
  bool _savingName = false;
  bool _uploadingPhoto = false;
  bool _signingOut = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _savingName = true);
    try {
      await _profileService.saveName(_nameController.text);
      _message('Name saved.');
    } catch (error) {
      _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _choosePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image == null || !mounted) return;
      setState(() => _uploadingPhoto = true);
      final bytes = await image.readAsBytes();
      await _profileService.uploadAvatar(bytes: bytes, fileName: image.name);
      _message('Profile photo updated.');
    } catch (error) {
      _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await AuthService().signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      _message(_friendlyError(error));
      if (mounted) setState(() => _signingOut = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is ArgumentError || error is StateError) {
      return error.toString().replaceFirst('Invalid argument(s): ', '');
    }
    return 'Could not save the change. Check your connection and try again.';
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('You are signed out.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile and settings')),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _profileService.watchProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data ?? const <String, dynamic>{};
          if (!_initializedName && !snapshot.hasError) {
            _nameController.text =
                (profile['displayName'] as String?) ?? user.displayName ?? '';
            _initializedName = true;
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Could not load profile settings.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final photoUrl = (profile['photoUrl'] as String?) ?? user.photoURL;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.mist,
                      foregroundImage:
                          photoUrl == null ? null : NetworkImage(photoUrl),
                      child: photoUrl == null
                          ? const Icon(Icons.person,
                              size: 48, color: AppTheme.midnight)
                          : null,
                    ),
                    IconButton.filled(
                      tooltip: 'Change profile photo',
                      onPressed: _uploadingPhoto ? null : _choosePhoto,
                      icon: _uploadingPhoto
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(user.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 28),
              Text('Display name',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Your name',
                ),
                onSubmitted: (_) => _savingName ? null : _saveName(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _savingName ? null : _saveName,
                icon: _savingName
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save name'),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: _signingOut ? null : _signOut,
                icon: _signingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
