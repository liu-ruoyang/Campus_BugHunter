import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile/profile_cubit.dart';
import '../bloc/profile/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final usernameController = TextEditingController();
  final ageController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();

  String gender = 'prefer_not_to_say';
  bool _hydrated = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadProfile(),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.message != current.message,
        listener: (context, state) {
          if (state.status == ProfileStatus.loaded && !_hydrated) {
            usernameController.text = state.username;
            ageController.text = state.age.toString();
            addressController.text = state.address;
            emailController.text = state.email;
            _hydrated = true;
            setState(() {
              gender = state.gender;
            });
          }

          if (state.message != null) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Message'),
                content: Text(state.message!),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ProfileStatus.saving;

          return Scaffold(
            backgroundColor: const Color(0xFF020617),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white),
              ),
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  inputField('Username', usernameController),
                  genderDropdown(),
                  inputField('Age', ageController, type: TextInputType.number),
                  inputField('Address', addressController),
                  inputField('Email', emailController, enabled: false),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<ProfileCubit>().saveProfile(
                              username: usernameController.text,
                              gender: gender,
                              age: ageController.text,
                              address: addressController.text,
                              email: emailController.text,
                            ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    TextInputType? type,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget genderDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<String>(
        value: gender,
        dropdownColor: const Color(0xFF111827),
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
          DropdownMenuItem(
            value: 'prefer_not_to_say',
            child: Text('Prefer not to say'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            gender = value!;
          });
        },
      ),
    );
  }
}
