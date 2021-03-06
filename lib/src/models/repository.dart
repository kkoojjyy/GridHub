library gridhub.src.models.repository;

import 'dart:async';

import 'package:gridhub/src/actions/repo_actions.dart';  // TODO temp
import 'package:gridhub/src/services/github_service.dart' as githubService;

class RepoDescriptor {
  String name;
  String url;

  RepoDescriptor(String name) {
    this.name = name;
    this.url = 'https://github.com/${name}';
  }
}

class Repository extends RepoDescriptor {
  String readmeData;
  List tagsData;
  List releasesData;
  List issuesData;
  List pullRequestsData;
  List commitsData;
  List milestonesData;
  Map<int, List<Map>> commentsMap;
  Map<int, List<Map>> issuesMap;
  Map<int, List<Map>> pullRequestsMap;

  bool dataInitialized;

  RepoActions _actions;  // TODO temp

  Repository(String name, this._actions) : super(name) {
    readmeData = '';
    tagsData = [];
    releasesData = [];
    issuesData = [];
    pullRequestsData = [];
    commitsData = [];
    milestonesData = [];

    commentsMap = {};
    issuesMap = {};
    pullRequestsMap = {};

    dataInitialized = false;
  }

  Future initializeData() {
    Completer commitsCompleter = new Completer();
    Future commitsFuture = commitsCompleter.future;

    Future readmeFuture = githubService.getReadme(this).then((responseString) {
      this.readmeData = responseString;
      _actions.updateRepo(this.name);
    }).catchError((_) {
      this.readmeData = '';
    });
    Future tagsFuture = githubService.getTags(this).then((response) {
      this.tagsData = response;
      githubService.getCommitsSinceLastTag(this, this.tagsData).then((response) {
        this.commitsData = response['commits'];
        commitsCompleter.complete();
      });
    });
    Future releasesFuture = githubService.getReleases(this).then((response) {
      this.releasesData = response;
    });
    Future issuesFuture = githubService.getIssues(this, 'issues').then((response) {
      this.issuesData = response;
      this.issuesData.forEach((issue) {
        int issueNumber = issue['number'];

        // Add each issue to a map
        this.issuesMap[issueNumber] = issue;

        // Only get comments for open pull requests
        if (issue['state'] == 'open' && issue['pull_request'] != null) {
          githubService.getCommentsForIssue(this, issueNumber).then((comments) {
            if (comments != null) {
              this.commentsMap[issueNumber] = comments;
              _actions.updateRepo(this.name);
            }
          });
        }
      });
    });
    Future pullRequestsFuture = githubService.getIssues(this, 'pulls').then((response) {
      this.pullRequestsData = response;
      this.pullRequestsData.forEach((pullRequest) {
        int pullRequestNumber = pullRequest['number'];

        // Add each pull request to a map
        this.pullRequestsMap[pullRequestNumber] = pullRequest;
      });
    });
    Future milestonesFuture = githubService.getMilestones(this).then((response) {
      this.milestonesData = response;
    });

    return Future.wait([
      readmeFuture,
      tagsFuture,
      releasesFuture,
      issuesFuture,
      pullRequestsFuture,
      commitsFuture,
      milestonesFuture
    ]).then((args) {
      this.dataInitialized = true;
      return args;
    });
  }
}
