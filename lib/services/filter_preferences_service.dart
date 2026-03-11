import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _kPrefix = 'filter_';
const String _kInterestedIn = '${_kPrefix}interested_in';
const String _kNeighbourhood = '${_kPrefix}neighbourhood';
const String _kMaxDistance = '${_kPrefix}max_distance';
const String _kAgeMin = '${_kPrefix}age_min';
const String _kAgeMax = '${_kPrefix}age_max';
const String _kEthnicity = '${_kPrefix}ethnicity';
const String _kReligion = '${_kPrefix}religion';
const String _kRelationshipType = '${_kPrefix}relationship_type';
const String _kHeight = '${_kPrefix}height';
const String _kDatingIntentions = '${_kPrefix}dating_intentions';
const String _kChildren = '${_kPrefix}children';
const String _kFamilyPlans = '${_kPrefix}family_plans';
const String _kDrugs = '${_kPrefix}drugs';
const String _kSmoking = '${_kPrefix}smoking';
const String _kMarijuana = '${_kPrefix}marijuana';
const String _kDrinking = '${_kPrefix}drinking';
const String _kPolitics = '${_kPrefix}politics';
const String _kEducationLevel = '${_kPrefix}education_level';

const List<String> _filterStorageKeys = [
  _kInterestedIn, _kNeighbourhood, _kMaxDistance, _kAgeMin, _kAgeMax,
  _kEthnicity, _kReligion, _kRelationshipType, _kHeight, _kDatingIntentions,
  _kChildren, _kFamilyPlans, _kDrugs, _kSmoking, _kMarijuana, _kDrinking,
  _kPolitics, _kEducationLevel,
];

/// تفضيلات الفلتر للمواعيد. تُحفظ محلياً ومزامنتها مع Supabase (user_profile_fields) عند تسجيل الدخول.
class FilterPreferencesService {
  FilterPreferencesService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _tableName = 'user_profile_fields';

  Future<Map<String, String?>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, String?>{
      'interestedIn': prefs.getString(_kInterestedIn),
      'neighbourhood': prefs.getString(_kNeighbourhood),
      'maxDistance': prefs.getString(_kMaxDistance),
      'ageMin': prefs.getString(_kAgeMin),
      'ageMax': prefs.getString(_kAgeMax),
      'ethnicity': prefs.getString(_kEthnicity),
      'religion': prefs.getString(_kReligion),
      'relationshipType': prefs.getString(_kRelationshipType),
      'height': prefs.getString(_kHeight),
      'datingIntentions': prefs.getString(_kDatingIntentions),
      'children': prefs.getString(_kChildren),
      'familyPlans': prefs.getString(_kFamilyPlans),
      'drugs': prefs.getString(_kDrugs),
      'smoking': prefs.getString(_kSmoking),
      'marijuana': prefs.getString(_kMarijuana),
      'drinking': prefs.getString(_kDrinking),
      'politics': prefs.getString(_kPolitics),
      'educationLevel': prefs.getString(_kEducationLevel),
    };
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final res = await _client
            .from(_tableName)
            .select('field_key, value')
            .eq('user_id', userId)
            .inFilter('field_key', _filterStorageKeys);
        final list = res as List;
        for (final row in list) {
          final key = row['field_key'] as String?;
          final value = row['value'] as String?;
          if (key == null) continue;
          final displayKey = _storageKeyToDisplayKey(key);
          if (displayKey != null && value != null && value.isNotEmpty) {
            result[displayKey] = value;
          }
        }
      } catch (_) {
        // الاعتماد على القيم المحلية عند فشل السيرفر
      }
    }
    return result;
  }

  String? _storageKeyToDisplayKey(String storageKey) {
    switch (storageKey) {
      case _kInterestedIn: return 'interestedIn';
      case _kNeighbourhood: return 'neighbourhood';
      case _kMaxDistance: return 'maxDistance';
      case _kAgeMin: return 'ageMin';
      case _kAgeMax: return 'ageMax';
      case _kEthnicity: return 'ethnicity';
      case _kReligion: return 'religion';
      case _kRelationshipType: return 'relationshipType';
      case _kHeight: return 'height';
      case _kDatingIntentions: return 'datingIntentions';
      case _kChildren: return 'children';
      case _kFamilyPlans: return 'familyPlans';
      case _kDrugs: return 'drugs';
      case _kSmoking: return 'smoking';
      case _kMarijuana: return 'marijuana';
      case _kDrinking: return 'drinking';
      case _kPolitics: return 'politics';
      case _kEducationLevel: return 'educationLevel';
      default: return null;
    }
  }

  Future<void> save(String key, String? value) async {
    final storageKey = _keyToStorage(key);
    if (storageKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(storageKey);
    } else {
      await prefs.setString(storageKey, value);
    }
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _client.from(_tableName).upsert({
          'user_id': userId,
          'field_key': storageKey,
          'value': value?.trim() ?? '',
          'visibility': 'hidden',
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,field_key');
      } catch (_) {
        // المحلي محفوظ؛ المزامنة تُعاد لاحقاً عند التحميل
      }
    }
  }

  String? _keyToStorage(String key) {
    switch (key) {
      case 'interestedIn': return _kInterestedIn;
      case 'neighbourhood': return _kNeighbourhood;
      case 'maxDistance': return _kMaxDistance;
      case 'ageMin': return _kAgeMin;
      case 'ageMax': return _kAgeMax;
      case 'ethnicity': return _kEthnicity;
      case 'religion': return _kReligion;
      case 'relationshipType': return _kRelationshipType;
      case 'height': return _kHeight;
      case 'datingIntentions': return _kDatingIntentions;
      case 'children': return _kChildren;
      case 'familyPlans': return _kFamilyPlans;
      case 'drugs': return _kDrugs;
      case 'smoking': return _kSmoking;
      case 'marijuana': return _kMarijuana;
      case 'drinking': return _kDrinking;
      case 'politics': return _kPolitics;
      case 'educationLevel': return _kEducationLevel;
      default: return null;
    }
  }
}
