import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class LocalStorageService {
  static const String sessionsBoxName = 'sessions';
  static const String activitiesBoxName = 'activities';
  static const String metadataBoxName = 'metadata';
  static const String sessionsHistoryCompleteKey = 'sessionsHistoryComplete';
  static const String sourcesHistoryCompleteKey = 'sourcesHistoryComplete';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(sessionsBoxName);
    await Hive.openBox(activitiesBoxName);
    await Hive.openBox(metadataBoxName);
  }

  // Session operations
  List<Session> getSessions() {
    final box = Hive.box(sessionsBoxName);
    final sessions = box.values
        .map((item) => Session.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    sessions.sort((a, b) => b.createTime.compareTo(a.createTime));
    return sessions;
  }

  Future<void> saveSessions(List<Session> sessions) async {
    final box = Hive.box(sessionsBoxName);
    final Map<String, dynamic> data = {
      for (var s in sessions) s.id: s.toJson(),
    };
    await box.putAll(data);
  }

  Future<void> saveSession(Session session) async {
    final box = Hive.box(sessionsBoxName);
    await box.put(session.id, session.toJson());
  }

  bool isSessionsHistoryComplete() {
    return Hive.box(
          metadataBoxName,
        ).get(sessionsHistoryCompleteKey, defaultValue: false)
        as bool;
  }

  Future<void> setSessionsHistoryComplete(bool isComplete) async {
    await Hive.box(metadataBoxName).put(sessionsHistoryCompleteKey, isComplete);
  }

  bool isSourcesHistoryComplete() {
    return Hive.box(
          metadataBoxName,
        ).get(sourcesHistoryCompleteKey, defaultValue: false)
        as bool;
  }

  Future<void> setSourcesHistoryComplete(bool isComplete) async {
    await Hive.box(metadataBoxName).put(sourcesHistoryCompleteKey, isComplete);
  }

  // Activity operations
  List<Activity> getActivities(String sessionId) {
    final box = Hive.box(activitiesBoxName);
    final data = box.get(sessionId);
    if (data == null) return [];
    final activities = (data as List)
        .map((item) => Activity.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    activities.sort((a, b) => a.createTime.compareTo(b.createTime));
    return activities;
  }

  Future<void> saveActivities(
    String sessionId,
    List<Activity> activities,
  ) async {
    final box = Hive.box(activitiesBoxName);
    final merged = _mergeActivities(getActivities(sessionId), activities);
    await box.put(sessionId, merged.map((a) => a.toJson()).toList());
  }

  Future<void> clear() async {
    await Hive.box(sessionsBoxName).clear();
    await Hive.box(activitiesBoxName).clear();
    await Hive.box(metadataBoxName).clear();
  }

  List<Activity> _mergeActivities(
    List<Activity> existing,
    List<Activity> incoming,
  ) {
    final byId = <String, Activity>{
      for (final activity in existing) activity.id: activity,
    };

    for (final activity in incoming) {
      byId[activity.id] = activity;
    }

    final merged = byId.values.toList();
    merged.sort((a, b) => a.createTime.compareTo(b.createTime));
    return merged;
  }
}
