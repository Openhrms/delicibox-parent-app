import 'dart:convert';
import 'user_type.dart';

class AppUser {
  final String uid;              // mock uid = email
  final String email;
  final String displayName;
  final UserType userType;
  final bool profileComplete;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.userType,
    required this.profileComplete,
  });

  AppUser copyWith({
    String? displayName,
    UserType? userType,
    bool? profileComplete,
  }) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    userType: userType ?? this.userType,
    profileComplete: profileComplete ?? this.profileComplete,
  );

  Map<String,dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'userType': userType.name,
    'profileComplete': profileComplete,
  };

  static AppUser fromJson(Map<String,dynamic> j) => AppUser(
    uid: j['uid'],
    email: j['email'],
    displayName: j['displayName'] ?? '',
    userType: UserType.values.firstWhere((e)=>e.name == j['userType'], orElse: ()=>UserType.parent),
    profileComplete: j['profileComplete'] == true,
  );

  @override
  String toString() => jsonEncode(toJson());
}
