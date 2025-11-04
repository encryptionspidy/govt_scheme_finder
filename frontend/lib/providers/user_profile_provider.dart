import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../data/local/hive_boxes.dart';
import '../data/models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider() {
    _restore();
  }

  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get isProfileComplete => _profile != null;
  bool get isLoading => _loading;

  Future<void> _restore() async {
    _loading = true;
    notifyListeners();
    final Box box = Hive.box(HiveBoxes.profile);
    final Map<String, dynamic>? stored =
        (box.get('userProfile') as Map?)?.cast<String, dynamic>();
    if (stored != null) {
      _profile = UserProfile.fromMap(stored);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    _loading = true;
    notifyListeners();
    final Box box = Hive.box(HiveBoxes.profile);
    await box.put('userProfile', profile.toMap());
    _profile = profile;
    _loading = false;
    notifyListeners();
  }

  Future<void> resetProfile() async {
    final Box box = Hive.box(HiveBoxes.profile);
    await box.delete('userProfile');
    _profile = null;
    notifyListeners();
  }
}
