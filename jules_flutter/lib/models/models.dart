enum SessionState {
  queued,
  planning,
  awaitingPlanApproval,
  awaitingUserFeedback,
  inProgress,
  paused,
  completed,
  failed,
}

class Session {
  final String name;
  final String id;
  final String title;
  final String? prompt;
  final SessionState state;
  final DateTime createTime;
  final List<Activity> activities;
  final String? repo;

  Session({
    required this.name,
    required this.id,
    required this.title,
    this.prompt,
    required this.state,
    required this.createTime,
    this.activities = const [],
    this.repo,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final sourceContext = json['sourceContext'] is Map
        ? (json['sourceContext'] as Map).cast<String, dynamic>()
        : null;
    final repoData = json['repo_data'] is Map
        ? (json['repo_data'] as Map).cast<String, dynamic>()
        : null;

    return Session(
      name: name,
      id: json['id'] ?? name.split('/').last,
      title: json['title'] ?? 'Untitled Session',
      prompt: json['prompt'],
      state: _parseState(json['state']),
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'])
          : DateTime.now(),
      repo: _extractRepo(sourceContext ?? repoData),
      activities:
          (json['activities'] as List?)
              ?.map(
                (a) => Activity.fromJson((a as Map).cast<String, dynamic>()),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'title': title,
    'prompt': prompt,
    'state': state.name,
    'createTime': createTime.toIso8601String(),
    'repo_data': {'source': repo != null ? 'sources/$repo' : null},
    'activities': activities.map((a) => a.toJson()).toList(),
  };

  static SessionState _parseState(String? state) {
    switch (state?.toUpperCase()) {
      case 'QUEUED':
        return SessionState.queued;
      case 'PLANNING':
        return SessionState.planning;
      case 'AWAITING_PLAN_APPROVAL':
        return SessionState.awaitingPlanApproval;
      case 'AWAITING_USER_FEEDBACK':
        return SessionState.awaitingUserFeedback;
      case 'IN_PROGRESS':
        return SessionState.inProgress;
      case 'PAUSED':
        return SessionState.paused;
      case 'COMPLETED':
        return SessionState.completed;
      case 'FAILED':
        return SessionState.failed;
      default:
        return SessionState.queued;
    }
  }

  static String? _extractRepo(Map<String, dynamic>? context) {
    if (context == null) return null;
    final source = context['source'] as String?;
    if (source != null && source.startsWith('sources/')) {
      return source.replaceFirst('sources/', '').replaceAll('-', '/');
    }
    return null;
  }

  Session copyWith({
    String? name,
    String? id,
    String? title,
    String? prompt,
    SessionState? state,
    DateTime? createTime,
    List<Activity>? activities,
    String? repo,
  }) {
    return Session(
      name: name ?? this.name,
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      state: state ?? this.state,
      createTime: createTime ?? this.createTime,
      activities: activities ?? this.activities,
      repo: repo ?? this.repo,
    );
  }
}

class SessionsResponse {
  final List<Session> sessions;
  final String? nextPageToken;

  SessionsResponse({required this.sessions, this.nextPageToken});

  factory SessionsResponse.fromJson(Map<String, dynamic> json) {
    return SessionsResponse(
      sessions:
          (json['sessions'] as List?)
              ?.map(
                (session) =>
                    Session.fromJson((session as Map).cast<String, dynamic>()),
              )
              .toList() ??
          [],
      nextPageToken: json['nextPageToken'] as String?,
    );
  }
}

enum ActivityOriginator { system, agent, user }

class Activity {
  final String id;
  final ActivityOriginator originator;
  final String? description;
  final DateTime createTime;

  // Specific activity data
  final Plan? planGenerated;
  final String? userMessage;
  final String? agentMessage;
  final ProgressUpdate? progressUpdated;
  final List<Artifact> artifacts;

  Activity({
    required this.id,
    required this.originator,
    this.description,
    required this.createTime,
    this.planGenerated,
    this.userMessage,
    this.agentMessage,
    this.progressUpdated,
    this.artifacts = const [],
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;

    final planGeneratedObj = json['planGenerated'] is Map
        ? (json['planGenerated'] as Map).cast<String, dynamic>()
        : null;
    final userMessagedObj = json['userMessaged'] is Map
        ? (json['userMessaged'] as Map).cast<String, dynamic>()
        : null;
    final agentMessagedObj = json['agentMessaged'] is Map
        ? (json['agentMessaged'] as Map).cast<String, dynamic>()
        : null;
    final progressUpdatedObj = json['progressUpdated'] is Map
        ? (json['progressUpdated'] as Map).cast<String, dynamic>()
        : null;
    final artifactsList = json['artifacts'] as List?;

    return Activity(
      id:
          json['id']?.toString() ??
          (name != null ? name.split('/').last : 'unknown'),
      originator: _parseOriginator(json['originator'] as String?),
      description: json['description'] as String?,
      createTime: DateTime.parse(json['createTime'] as String),
      planGenerated:
          (planGeneratedObj != null && planGeneratedObj['plan'] is Map)
          ? Plan.fromJson(
              (planGeneratedObj['plan'] as Map).cast<String, dynamic>(),
            )
          : null,
      userMessage:
          userMessagedObj?['userMessage'] as String? ??
          userMessagedObj?['message'] as String? ??
          userMessagedObj?['prompt'] as String? ??
          json['userMessage'] as String?,
      agentMessage:
          agentMessagedObj?['agentMessage'] as String? ??
          agentMessagedObj?['message'] as String? ??
          json['agentMessage'] as String?,
      progressUpdated: progressUpdatedObj != null
          ? ProgressUpdate.fromJson(progressUpdatedObj)
          : null,
      artifacts:
          artifactsList
              ?.map(
                (a) => Artifact.fromJson((a as Map).cast<String, dynamic>()),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'originator': originator.name,
    'description': description,
    'createTime': createTime.toIso8601String(),
    'planGenerated': planGenerated != null
        ? {'plan': planGenerated!.toJson()}
        : null,
    'userMessage': userMessage,
    'agentMessage': agentMessage,
    'progressUpdated': progressUpdated?.toJson(),
    'artifacts': artifacts.map((a) => a.toJson()).toList(),
  };

  static ActivityOriginator _parseOriginator(String? originator) {
    switch (originator?.toLowerCase()) {
      case 'user':
        return ActivityOriginator.user;
      case 'agent':
        return ActivityOriginator.agent;
      case 'system':
        return ActivityOriginator.system;
      default:
        return ActivityOriginator.system;
    }
  }
}

class Plan {
  final String id;
  final List<PlanStep> steps;

  Plan({required this.id, required this.steps});

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id']?.toString() ?? 'unknown',
      steps: (json['steps'] is List)
          ? (json['steps'] as List)
                .map(
                  (s) => PlanStep.fromJson((s as Map).cast<String, dynamic>()),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'steps': steps.map((s) => s.toJson()).toList(),
  };
}

class PlanStep {
  final String id;
  final int index;
  final String title;
  final String description;

  PlanStep({
    required this.id,
    required this.index,
    required this.title,
    required this.description,
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      id: json['id']?.toString() ?? 'unknown',
      index: json['index'] is int ? json['index'] as int : 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'index': index,
    'title': title,
    'description': description,
  };
}

class ProgressUpdate {
  final String title;
  final String description;

  ProgressUpdate({required this.title, required this.description});

  factory ProgressUpdate.fromJson(Map<String, dynamic> json) {
    return ProgressUpdate(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'description': description};
}

class Artifact {
  final ChangeSet? changeSet;
  final BashOutput? bashOutput;
  final Media? media;

  Artifact({this.changeSet, this.bashOutput, this.media});

  factory Artifact.fromJson(Map<String, dynamic> json) {
    final changeSetObj = json['changeSet'] is Map
        ? (json['changeSet'] as Map).cast<String, dynamic>()
        : null;
    final bashOutputObj = json['bashOutput'] is Map
        ? (json['bashOutput'] as Map).cast<String, dynamic>()
        : null;
    final mediaObj = json['media'] is Map
        ? (json['media'] as Map).cast<String, dynamic>()
        : null;

    return Artifact(
      changeSet: changeSetObj != null ? ChangeSet.fromJson(changeSetObj) : null,
      bashOutput: bashOutputObj != null
          ? BashOutput.fromJson(bashOutputObj)
          : null,
      media: mediaObj != null ? Media.fromJson(mediaObj) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'changeSet': changeSet?.toJson(),
    'bashOutput': bashOutput?.toJson(),
    'media': media?.toJson(),
  };
}

class ChangeSet {
  final String source;
  final GitPatch gitPatch;

  ChangeSet({required this.source, required this.gitPatch});

  factory ChangeSet.fromJson(Map<String, dynamic> json) {
    final gitPatchObj = json['gitPatch'] is Map
        ? (json['gitPatch'] as Map).cast<String, dynamic>()
        : null;

    return ChangeSet(
      source: json['source']?.toString() ?? 'unknown',
      gitPatch: gitPatchObj != null
          ? GitPatch.fromJson(gitPatchObj)
          : GitPatch(baseCommitId: '', unidiffPatch: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'gitPatch': gitPatch.toJson(),
  };
}

class GitPatch {
  final String baseCommitId;
  final String unidiffPatch;
  final String? suggestedCommitMessage;

  GitPatch({
    required this.baseCommitId,
    required this.unidiffPatch,
    this.suggestedCommitMessage,
  });

  factory GitPatch.fromJson(Map<String, dynamic> json) {
    return GitPatch(
      baseCommitId: json['baseCommitId']?.toString() ?? '',
      unidiffPatch: json['unidiffPatch']?.toString() ?? '',
      suggestedCommitMessage: json['suggestedCommitMessage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'baseCommitId': baseCommitId,
    'unidiffPatch': unidiffPatch,
    'suggestedCommitMessage': suggestedCommitMessage,
  };
}

class BashOutput {
  final String command;
  final String output;
  final int exitCode;

  BashOutput({
    required this.command,
    required this.output,
    required this.exitCode,
  });

  factory BashOutput.fromJson(Map<String, dynamic> json) {
    return BashOutput(
      command: json['command']?.toString() ?? '',
      output: json['output']?.toString() ?? '',
      exitCode: json['exitCode'] is int ? json['exitCode'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'command': command,
    'output': output,
    'exitCode': exitCode,
  };
}

class Media {
  final String mimeType;
  final String data; // Base64

  Media({required this.mimeType, required this.data});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      mimeType: json['mimeType']?.toString() ?? 'text/plain',
      data: json['data']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'mimeType': mimeType, 'data': data};
}

class Source {
  final String name;
  final String id;
  final GitHubRepo? githubRepo;

  Source({required this.name, required this.id, this.githubRepo});

  factory Source.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return Source(
      name: name,
      id: json['id'] as String? ?? name.replaceFirst('sources/', ''),
      githubRepo: json['githubRepo'] != null
          ? GitHubRepo.fromJson(
              (json['githubRepo'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class SourcesResponse {
  final List<Source> sources;
  final String? nextPageToken;

  SourcesResponse({required this.sources, this.nextPageToken});

  factory SourcesResponse.fromJson(Map<String, dynamic> json) {
    return SourcesResponse(
      sources:
          (json['sources'] as List?)
              ?.map((s) => Source.fromJson((s as Map).cast<String, dynamic>()))
              .toList() ??
          [],
      nextPageToken: json['nextPageToken'] as String?,
    );
  }
}

class GitHubRepo {
  final String owner;
  final String repo;

  GitHubRepo({required this.owner, required this.repo});

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      owner: json['owner'] as String,
      repo: json['repo'] as String,
    );
  }
}
