import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/local_storage.dart';
import '../core/connectivity_service.dart';
import '../models/models.dart';
import '../repositories/jules_repository.dart';

class ChatProvider extends ChangeNotifier {
  LocalStorageService? _local;
  ConnectivityService? _connectivity;
  StreamSubscription? _connectivitySubscription;
  ApiClient? _apiClient;
  String? _apiKey;
  JulesRepository? _repository;
  Timer? _refreshTimer;
  Future<void>? _sessionsRefresh;
  Future<void>? _currentSessionRefresh;
  String? _currentSessionRefreshSessionId;
  Future<void>? _pollRefresh;
  Future<void>? _historyBackfill;
  Future<void>? _sourcesBackfill;
  int _currentSessionRefreshVersion = 0;
  int _consecutivePollFailures = 0;
  bool _hasUserSelectedView = false;

  List<Session> _sessions = [];
  List<Source> _sources = [];
  String? _historyBackfillToken;
  String? _sourcesBackfillToken;
  String _sidebarSearchQuery = '';
  Session? _currentSession;
  String? _draftRepo;
  bool _isSidebarOpen = true;
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isHistoryIndexing = false;
  bool _isSourcesIndexing = false;
  bool _isHistoryIndexComplete = false;
  bool _isSourcesIndexComplete = false;
  bool _hasSessionHeadSnapshot = false;
  bool _hasSourcesHeadSnapshot = false;
  String? _errorMessage;

  static const Duration _basePollInterval = Duration(seconds: 4);
  static const Duration _maxPollInterval = Duration(seconds: 30);
  static const Duration _backgroundBackfillDelay = Duration(milliseconds: 150);

  List<Session> get sessions => _sessions;
  List<Source> get sources => _sources;
  String get sidebarSearchQuery => _sidebarSearchQuery;
  bool get isSidebarSearching => _sidebarSearchQuery.trim().isNotEmpty;
  bool get hasMoreSessions => !_isHistoryIndexComplete;
  bool get hasMoreSources => !_isSourcesIndexComplete;
  bool get isHistoryIndexing => _isHistoryIndexing;
  bool get isSourcesIndexing => _isSourcesIndexing;
  bool get isHistoryIndexComplete => _isHistoryIndexComplete;
  List<Session> get visibleSessions {
    final query = _sidebarSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _sessions;

    return _sessions.where((session) {
      return [
        session.title,
        session.repo,
        session.state.name,
        session.prompt,
      ].whereType<String>().any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  List<String> get sortedRepoIds {
    // 1. Get all unique repo IDs from sources and sessions
    final allRepos = {
      ..._sources.map((s) => s.id),
      ..._sessions.map((s) => s.repo).whereType<String>(),
    }.toList();

    // 2. Sort by recency based on sessions
    final Map<String, DateTime> lastUsed = {};
    for (var s in _sessions) {
      if (s.repo != null) {
        final current = lastUsed[s.repo!];
        if (current == null || s.createTime.isAfter(current)) {
          lastUsed[s.repo!] = s.createTime;
        }
      }
    }

    allRepos.sort((a, b) {
      final timeA = lastUsed[a] ?? DateTime(1970);
      final timeB = lastUsed[b] ?? DateTime(1970);
      return timeB.compareTo(timeA); // Descending (most recent first)
    });

    return allRepos;
  }

  Session? get currentSession => _currentSession;
  String? get draftRepo => _draftRepo;
  bool get isSidebarOpen => _isSidebarOpen;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  bool get isNewThreadMode => _currentSession == null && _draftRepo != null;
  bool get isRepoSelectionMode => _currentSession == null && _draftRepo == null;

  void setDependencies(
    LocalStorageService local,
    ConnectivityService connectivity,
  ) {
    _local = local;
    if (_connectivity != connectivity) {
      _connectivitySubscription?.cancel();
      _connectivity = connectivity;
      _connectivitySubscription = _connectivity?.onConnectivityChanged.listen((
        isOnline,
      ) {
        if (isOnline) {
          debugPrint("Device back online, triggering sync...");
          refreshSessions();
        }
      });
    }
  }

  void updateClient(ApiClient client) {
    if (_apiKey == client.apiKey && _repository != null) {
      client.dispose();
      return;
    }

    _apiClient?.dispose();
    _apiClient = client;
    _apiKey = client.apiKey;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _sessionsRefresh = null;
    _currentSessionRefresh = null;
    _currentSessionRefreshSessionId = null;
    _pollRefresh = null;
    _historyBackfill = null;
    _sourcesBackfill = null;
    _historyBackfillToken = null;
    _sourcesBackfillToken = null;
    _hasSessionHeadSnapshot = false;
    _hasSourcesHeadSnapshot = false;
    _consecutivePollFailures = 0;
    _hasUserSelectedView = false;
    _isHistoryIndexing = false;
    _isSourcesIndexing = false;

    if (_local != null) {
      _isHistoryIndexComplete = _local!.isSessionsHistoryComplete();
      _isSourcesIndexComplete = _local!.isSourcesHistoryComplete();
      _repository = JulesRepository(client, _local!);
      _loadSessions();
      _loadSources();
    }
  }

  @override
  void dispose() {
    _apiClient?.dispose();
    _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSources() async {
    if (_repository == null) return;
    try {
      final response = await _repository!.syncSources();
      _sources = _mergeSources(_sources, response.sources);
      _hasSourcesHeadSnapshot = true;
      await _setSourcesBackfillState(response.nextPageToken);
      notifyListeners();
      unawaited(_ensureSourcesIndexed());
    } catch (e) {
      debugPrint("Failed to load sources: $e");
    }
  }

  Future<void> loadMoreSources() async {
    await _ensureSourcesIndexed();
  }

  Future<void> _loadSessions() async {
    if (_repository == null) return;

    if (_sessionsRefresh != null) return _sessionsRefresh;
    final refresh = _loadSessionsInternal();
    _sessionsRefresh = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_sessionsRefresh, refresh)) _sessionsRefresh = null;
    }
  }

  Future<void> _loadSessionsInternal() async {
    final repo = _repository;
    if (repo == null) return;

    // 1. Load Local Data First (Instant)
    _sessions = await repo.getSessions();
    _restoreCurrentSessionFromList(
      allowDefaultSelection: !_hasUserSelectedView,
    );
    notifyListeners();

    // 2. Background Sync
    _isSyncing = true;
    notifyListeners();
    try {
      final response = await repo.syncSessions(pageSize: 100);
      _sessions = _mergeSessions(_sessions, response.sessions);
      _hasSessionHeadSnapshot = true;
      await _setHistoryBackfillState(response.nextPageToken);
      if (_sessions.isNotEmpty) {
        _restoreCurrentSessionFromList(
          allowDefaultSelection: !_hasUserSelectedView,
        );
        await _refreshCurrentSession();
      }
      _errorMessage = null;
      unawaited(_ensureHistoryIndexed());
    } catch (e) {
      // Don't show error if we have local data, unless it's a critical failure
      if (_sessions.isEmpty) _errorMessage = "Failed to load sessions: $e";
      debugPrint("Sync error: $e");
    } finally {
      _isSyncing = false;
      _setLoading(false);
      _startOrStopPolling();
    }
  }

  Future<void> refreshSessions() async {
    await syncJulesData();
  }

  Future<void> syncJulesData() async {
    final repo = _repository;
    if (repo == null || _sessionsRefresh != null) return _sessionsRefresh;

    final refresh = _syncJulesDataInternal();
    _sessionsRefresh = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_sessionsRefresh, refresh)) _sessionsRefresh = null;
    }
  }

  Future<void> _syncJulesDataInternal() async {
    final repo = _repository;
    if (repo == null) return;

    _isSyncing = true;
    notifyListeners();
    try {
      final response = await repo.syncSessions(pageSize: 100);
      _sessions = _mergeSessions(_sessions, response.sessions);
      _hasSessionHeadSnapshot = true;
      await _setHistoryBackfillState(response.nextPageToken);
      _restoreCurrentSessionFromList(allowDefaultSelection: false);

      final session = _currentSession;
      if (session != null) {
        final freshActivities = await repo.syncSessionActivities(
          session.id,
          pageSize: 100,
        );
        if (_currentSession?.id == session.id) {
          var updatedSession = _currentSession!.copyWith(
            activities: freshActivities,
          );
          if (!_isOngoing(updatedSession)) {
            updatedSession = (await repo.getSession(
              session.id,
            )).copyWith(activities: freshActivities);
          }
          if (_currentSession?.id == session.id) {
            _currentSession = updatedSession;
          }
        }
      }

      _errorMessage = null;
      unawaited(_ensureHistoryIndexed());
    } catch (e) {
      _errorMessage = "Failed to refresh Jules data: $e";
      debugPrint("Refresh error: $e");
    } finally {
      _isSyncing = false;
      _setLoading(false);
      _startOrStopPolling();
    }
  }

  void setSidebarSearchQuery(String query) {
    if (_sidebarSearchQuery == query) return;
    _sidebarSearchQuery = query;
    notifyListeners();
    if (query.trim().isNotEmpty) {
      unawaited(_ensureHistoryIndexed());
      unawaited(_ensureSourcesIndexed());
    }
  }

  Future<void> loadMoreSessions() async {
    await _ensureHistoryIndexed();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void selectSession(Session session) {
    if (_currentSession?.id == session.id) return;
    _hasUserSelectedView = true;
    _currentSessionRefreshVersion++;
    _currentSession = session;
    _draftRepo = null; // Clear draft when switching to a real session
    _errorMessage = null;
    notifyListeners();

    // Fetch activities for the newly selected session
    _refreshCurrentSession();
    _startOrStopPolling();
  }

  void startNewThread(String? repo) {
    _hasUserSelectedView = true;
    _currentSessionRefreshVersion++;
    _currentSession = null;
    _draftRepo = repo;
    _errorMessage = null;
    notifyListeners();
  }

  void updateDraftRepo(String repo) {
    _hasUserSelectedView = true;
    _draftRepo = repo;
    notifyListeners();
  }

  void toggleSidebar() {
    setSidebarOpen(!_isSidebarOpen);
  }

  void setSidebarOpen(bool isOpen) {
    if (_isSidebarOpen == isOpen) return;
    _isSidebarOpen = isOpen;
    notifyListeners();
  }

  Future<void> createSession(String prompt, String title, String repo) async {
    if (_repository == null) return;
    _setLoading(true);
    try {
      final newSession = await _repository!.createSession(prompt, title, repo);
      _hasUserSelectedView = true;
      _sessions.insert(0, newSession);
      _currentSession = newSession;
      _draftRepo = null; // Clear draft once created
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to create session: $e";
    } finally {
      _setLoading(false);
      _startOrStopPolling();
    }
  }

  Future<void> approvePlan() async {
    if (_currentSession == null || _repository == null) return;
    _setLoading(true);
    try {
      final sessionId = _currentSession!.id;
      await _repository!.approvePlan(sessionId);
      await _refreshAfterMutation(sessionId);
    } catch (e) {
      _errorMessage = "Failed to approve plan: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendMessage(String content) async {
    if (_currentSession == null || _repository == null) return;

    // Optimistic UI Update
    final optimisticActivity = Activity(
      id: 'pending-${DateTime.now().millisecondsSinceEpoch}',
      originator: ActivityOriginator.user,
      createTime: DateTime.now(),
      userMessage: content,
    );

    final sessionId = _currentSession!.id;
    final originalActivities = List<Activity>.from(_currentSession!.activities);
    _currentSession = _currentSession!.copyWith(
      activities: [...originalActivities, optimisticActivity],
    );
    notifyListeners();

    try {
      await _repository!.sendMessage(sessionId, content);
      await _refreshAfterMutation(sessionId);
    } catch (e) {
      _errorMessage = "Failed to send message: $e";
      // Rollback optimistic update
      if (_currentSession?.id == sessionId) {
        _currentSession = _currentSession!.copyWith(
          activities: originalActivities,
        );
      }
      notifyListeners();
    }
  }

  Future<void> _refreshCurrentSession() async {
    if (_currentSession == null || _repository == null) return;

    final sessionId = _currentSession!.id;
    if (_currentSessionRefresh != null &&
        _currentSessionRefreshSessionId == sessionId) {
      return _currentSessionRefresh;
    }
    final refresh = _refreshCurrentSessionInternal(sessionId);
    _currentSessionRefresh = refresh;
    _currentSessionRefreshSessionId = sessionId;
    try {
      await refresh;
    } finally {
      if (identical(_currentSessionRefresh, refresh)) {
        _currentSessionRefresh = null;
        _currentSessionRefreshSessionId = null;
      }
    }
  }

  Future<void> _refreshCurrentSessionInternal(String sessionId) async {
    final repo = _repository;
    if (repo == null) return;

    final refreshVersion = ++_currentSessionRefreshVersion;

    // 1. Show Local Activities (Instant)
    final localActivities = await repo.getSessionActivities(sessionId);
    if (_currentSession?.id == sessionId &&
        localActivities.isNotEmpty &&
        !_hasPendingActivities(_currentSession!.activities)) {
      _currentSession = _currentSession!.copyWith(activities: localActivities);
      notifyListeners();
    }

    // 2. Background Sync
    _isSyncing = true;
    notifyListeners();
    try {
      final freshActivities = await repo.syncSessionActivities(sessionId);
      if (_currentSession?.id != sessionId ||
          refreshVersion != _currentSessionRefreshVersion) {
        return;
      }
      _currentSession = _currentSession!.copyWith(activities: freshActivities);
      notifyListeners();
    } catch (e) {
      debugPrint("Activity refresh error: $e");
    } finally {
      _isSyncing = false;
      _startOrStopPolling();
    }
  }

  void _startOrStopPolling({bool immediate = true}) {
    final hasOngoingSession = _sessions.any(_isOngoing);

    if (hasOngoingSession &&
        (_refreshTimer == null || !_refreshTimer!.isActive)) {
      _scheduleNextPoll(immediate ? Duration.zero : _nextPollDelay);
    } else if (!hasOngoingSession) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      _consecutivePollFailures = 0;
    }
  }

  Future<void> _pollActiveSession() async {
    if (_pollRefresh != null) return _pollRefresh;
    final refresh = _pollActiveSessionInternal();
    _pollRefresh = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_pollRefresh, refresh)) _pollRefresh = null;
    }
  }

  Future<void> _pollActiveSessionInternal() async {
    final repo = _repository;
    if (repo == null) return;

    var hadFailure = false;

    // 1. Sync session list to get status updates for all sessions
    try {
      final response = await repo.syncSessions(pageSize: 100);
      _sessions = _mergeSessions(_sessions, response.sessions);
      _hasSessionHeadSnapshot = true;
      await _setHistoryBackfillState(response.nextPageToken);
      _restoreCurrentSessionFromList(allowDefaultSelection: false);
      notifyListeners();
      unawaited(_ensureHistoryIndexed());
    } catch (e) {
      hadFailure = true;
      debugPrint("Poll sessions error: $e");
    }

    // 2. Sync activities for the current session if it's active
    final session = _currentSession;
    if (session != null && _isOngoing(session)) {
      try {
        final freshActivities = await repo.syncSessionActivities(session.id);

        // Re-check current session hasn't changed
        if (_currentSession?.id == session.id) {
          _currentSession = _currentSession!.copyWith(
            activities: freshActivities,
          );
          notifyListeners();
        }
      } catch (e) {
        hadFailure = true;
        debugPrint("Poll activities error: $e");
      }
    }

    _consecutivePollFailures = hadFailure ? _consecutivePollFailures + 1 : 0;

    // Update polling state
    _startOrStopPolling(immediate: false);
  }

  Future<void> _refreshAfterMutation(String sessionId) async {
    _currentSessionRefresh = null;
    _currentSessionRefreshSessionId = null;
    await _refreshCurrentSessionInternal(sessionId);
    unawaited(_loadSessions());
    _startOrStopPolling();
  }

  void _restoreCurrentSessionFromList({required bool allowDefaultSelection}) {
    if (_sessions.isEmpty) return;

    final current = _currentSession;
    if (current == null) {
      if (allowDefaultSelection && _draftRepo == null) {
        _currentSession = _sessions.first;
      }
      return;
    }

    final updatedSession = _sessions.firstWhere(
      (session) => session.id == current.id,
      orElse: () => current,
    );
    _currentSession = updatedSession.copyWith(activities: current.activities);
  }

  bool _isOngoing(Session session) =>
      session.state != SessionState.completed &&
      session.state != SessionState.failed;

  bool _hasPendingActivities(List<Activity> activities) {
    return activities.any((activity) => activity.id.startsWith('pending-'));
  }

  Future<void> _ensureHistoryIndexed() async {
    final repo = _repository;
    if (repo == null || _isHistoryIndexComplete || !_hasSessionHeadSnapshot) {
      return;
    }
    if (_historyBackfill != null) return _historyBackfill;

    final backfill = _backfillSessionHistory(repo);
    _historyBackfill = backfill;
    try {
      await backfill;
    } finally {
      if (identical(_historyBackfill, backfill)) {
        _historyBackfill = null;
      }
    }
  }

  Future<void> _backfillSessionHistory(JulesRepository repo) async {
    if (_historyBackfillToken == null) {
      if (!_isHistoryIndexComplete) {
        _isHistoryIndexComplete = true;
        await _local?.setSessionsHistoryComplete(true);
        notifyListeners();
      }
      return;
    }

    _isHistoryIndexing = true;
    notifyListeners();
    try {
      while (_historyBackfillToken != null) {
        final response = await repo.syncSessions(
          pageSize: 100,
          pageToken: _historyBackfillToken,
        );
        _sessions = _mergeSessions(_sessions, response.sessions);
        await _setHistoryBackfillState(response.nextPageToken);
        _restoreCurrentSessionFromList(allowDefaultSelection: false);
        notifyListeners();
        if (_historyBackfillToken != null) {
          await Future<void>.delayed(_backgroundBackfillDelay);
        }
      }
    } catch (e) {
      debugPrint("History indexing error: $e");
    } finally {
      _isHistoryIndexing = false;
      notifyListeners();
    }
  }

  Future<void> _ensureSourcesIndexed() async {
    final repo = _repository;
    if (repo == null || _isSourcesIndexComplete || !_hasSourcesHeadSnapshot) {
      return;
    }
    if (_sourcesBackfill != null) return _sourcesBackfill;

    final backfill = _backfillSources(repo);
    _sourcesBackfill = backfill;
    try {
      await backfill;
    } finally {
      if (identical(_sourcesBackfill, backfill)) {
        _sourcesBackfill = null;
      }
    }
  }

  Future<void> _backfillSources(JulesRepository repo) async {
    if (_sourcesBackfillToken == null) {
      if (!_isSourcesIndexComplete) {
        _isSourcesIndexComplete = true;
        await _local?.setSourcesHistoryComplete(true);
        notifyListeners();
      }
      return;
    }

    _isSourcesIndexing = true;
    notifyListeners();
    try {
      while (_sourcesBackfillToken != null) {
        final response = await repo.syncSources(
          pageSize: 100,
          pageToken: _sourcesBackfillToken,
        );
        _sources = _mergeSources(_sources, response.sources);
        await _setSourcesBackfillState(response.nextPageToken);
        notifyListeners();
        if (_sourcesBackfillToken != null) {
          await Future<void>.delayed(_backgroundBackfillDelay);
        }
      }
    } catch (e) {
      debugPrint("Source indexing error: $e");
    } finally {
      _isSourcesIndexing = false;
      notifyListeners();
    }
  }

  Future<void> _setHistoryBackfillState(String? nextPageToken) async {
    if (nextPageToken == null) {
      _historyBackfillToken = null;
      if (!_isHistoryIndexComplete) {
        _isHistoryIndexComplete = true;
        await _local?.setSessionsHistoryComplete(true);
      }
      return;
    }

    if (_isHistoryIndexComplete) return;
    _historyBackfillToken = nextPageToken;
  }

  Future<void> _setSourcesBackfillState(String? nextPageToken) async {
    if (nextPageToken == null) {
      _sourcesBackfillToken = null;
      if (!_isSourcesIndexComplete) {
        _isSourcesIndexComplete = true;
        await _local?.setSourcesHistoryComplete(true);
      }
      return;
    }

    if (_isSourcesIndexComplete) return;
    _sourcesBackfillToken = nextPageToken;
  }

  List<Session> _mergeSessions(List<Session> existing, List<Session> incoming) {
    final byId = <String, Session>{
      for (final session in existing) session.id: session,
    };
    for (final session in incoming) {
      byId[session.id] = session;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => b.createTime.compareTo(a.createTime));
    return merged;
  }

  List<Source> _mergeSources(List<Source> existing, List<Source> incoming) {
    final byId = <String, Source>{
      for (final source in existing) source.id: source,
    };
    for (final source in incoming) {
      byId[source.id] = source;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => a.id.compareTo(b.id));
    return merged;
  }

  void _scheduleNextPoll(Duration delay) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () {
      unawaited(_pollActiveSession());
    });
  }

  Duration get _nextPollDelay {
    final seconds =
        _basePollInterval.inSeconds * (1 << _consecutivePollFailures);
    return Duration(
      seconds: seconds.clamp(
        _basePollInterval.inSeconds,
        _maxPollInterval.inSeconds,
      ),
    );
  }
}
