library ReposStore;

import 'dart:async';
import 'package:pubsub/pubsub.dart';

import '../models/repo.dart';
import '../services/localStorageService.dart';


class ReposStore {

    RepoGridData storage;
    Map<String, List<Repository>> allRepos;

    ReposStore(storage) {
        this.storage = storage;
        this.allRepos = {};

        initializeCurrentPageRepos();

        // Subscriptions
        Pubsub.subscribe('repo.added', this._getPayload(this.onAddRepo));
        Pubsub.subscribe('repo.removed', this._getPayload(this.onRemoveRepo));
        Pubsub.subscribe('page.switch', this._getPayload(this.onSwitchPage));
    }

    initializeCurrentPageRepos() {
        var currentPageRepos = this.storage.getRepos(this.storage.currentPage);
        List<Future> futures = [];
        List<Repository> repos = [];
        currentPageRepos.forEach((repoName) {
            var repo = new Repository(repoName);
            repos.add(repo);
            futures.add(repo.initializeData());
        });

        this.allRepos[this.storage.currentPage] = repos;
        Future.wait(futures).then((futures) {
            this.trigger(repos);
        });
    }

    onAddRepo(String repoName) {
        var pageRepos = this.allRepos[this.storage.currentPage];
        var repo = new Repository(repoName);
        pageRepos.add(repo);
        repo.initializeData().then((futures) {
            this.trigger(pageRepos);
        });
        storage.addRepo(repoName);
    }

    onRemoveRepo(String repoName) {
        var pageRepos = this.allRepos[this.storage.currentPage];

        // TODO clean this up
        var repoToRemove = null;
        pageRepos.forEach((repo) {
            if (repo.name == repoName) {
                repoToRemove = repo;
            }
        });
        pageRepos.remove(repoToRemove);

        this.trigger(pageRepos);
        storage.removeRepo(repoName);
    }

    onSwitchPage(String pageName) {
        storage.currentPage = pageName;
        var pageRepos = this.allRepos[pageName];
        if (pageRepos == null) {
            initializeCurrentPageRepos();
        } else {
            this.trigger(pageRepos);
        }
    }

    trigger(List<Repository> repos) {
        Pubsub.publish('repos', repos);
    }

    _getPayload(toCall) {
        return (msg) {
            toCall(msg.args[0]);
        };
    }
}