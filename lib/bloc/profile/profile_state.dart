// This state file defines all profile data displayed and edited in the profile screens.
// It keeps personal fields, wallet balance, loading status, and messages in one immutable object.
// ProfileStatus lists each phase of loading or saving profile data.
enum ProfileStatus { initial, loading, loaded, saving, success, failure }

// ProfileState stores the user's profile fields and the current async action status.
class ProfileState {
  final ProfileStatus status;
  final String username;
  final String email;
  final String gender;
  final int age;
  final String address;
  final double wallet;
  final String? message;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.username = 'Loading...',
    this.email = '',
    this.gender = 'prefer_not_to_say',
    this.age = 0,
    this.address = '',
    this.wallet = 0,
    this.message,
  });

  // copyWith creates a new profile state while preserving fields that were not supplied.
  ProfileState copyWith({
    ProfileStatus? status,
    String? username,
    String? email,
    String? gender,
    int? age,
    String? address,
    double? wallet,
    String? message,
    bool clearMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      username: username ?? this.username,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      address: address ?? this.address,
      wallet: wallet ?? this.wallet,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
