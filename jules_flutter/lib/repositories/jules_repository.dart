import '../core/api_client.dart';
import '../core/local_storage.dart';
import '../models/models.dart';

class JulesRepository {
  final ApiClient _apiClient;
  final LocalStorageService _local;

  JulesRepository(this._apiClient, this._local);

  Future<List<Session>> getSessions({bool forceRefresh = false}) async {
    return _local.getSessions();
  }

  Future<SessionsResponse> syncSessions({
    int pageSize = 100,
    String? pageToken,
  }) async {
    String url = '/sessions?pageSize=$pageSize';
    if (pageToken != null) url += '&pageToken=$pageToken';

    final response = await _apiClient.get(url);
    final sessionsResponse = SessionsResponse.fromJson(response);

    await _local.saveSessions(sessionsResponse.sessions);
    return sessionsResponse;
  }

  Future<List<Activity>> getSessionActivities(String sessionId) async {
    return _local.getActivities(sessionId);
  }

  Future<List<Activity>> syncSessionActivities(
    String sessionId, {
    int pageSize = 50,
    String? pageToken,
  }) async {
    String url = '/sessions/$sessionId/activities?pageSize=$pageSize';
    if (pageToken != null) url += '&pageToken=$pageToken';

    final response = await _apiClient.get(url);
    final List activitiesJson = response['activities'] ?? [];
    final activities = activitiesJson
        .map((json) => Activity.fromJson((json as Map).cast<String, dynamic>()))
        .toList();

    await _local.saveActivities(sessionId, activities);
    return _local.getActivities(sessionId);
  }

  Future<Session> createSession(
    String prompt,
    String title,
    String repo,
  ) async {
    final response = await _apiClient.post('/sessions', {
      'prompt': prompt,
      'title': title,
      'sourceContext': {
        'source': 'sources/$repo',
        'githubRepoContext': {'startingBranch': 'main'},
      },
    });
    final session = Session.fromJson(response);
    await _local.saveSession(session);
    return session;
  }

  Future<SourcesResponse> syncSources({
    int pageSize = 100,
    String? pageToken,
  }) async {
    String url = '/sources?pageSize=$pageSize';
    if (pageToken != null) url += '&pageToken=$pageToken';

    final response = await _apiClient.get(url);
    return SourcesResponse.fromJson(response);
  }

  Future<void> sendMessage(String sessionId, String prompt) async {
    await _apiClient.post('/sessions/$sessionId:sendMessage', {
      'prompt': prompt,
    });
  }

  Future<Session> getSession(String sessionId) async {
    final response = await _apiClient.get('/sessions/$sessionId');
    final session = Session.fromJson(response);
    await _local.saveSession(session);
    return session;
  }

  Future<void> approvePlan(String sessionId) async {
    await _apiClient.post('/sessions/$sessionId:approvePlan', {});
  }
}
