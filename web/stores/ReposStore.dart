library ReposStore;

import 'dart:async';
import 'package:pubsub/pubsub.dart';

import '../models/repo.dart';
import '../services/localStorageService.dart';


class Store {

    List<Function> _subscribers = [];

    subscribe(Function callback) {
        _subscribers.add(callback);
    }

    trigger([String actionName = '']) {  // TODO do we need action name?
        _subscribers.forEach((Function subscription) {
            subscription(actionName);
        });
    }
}


class ReposStore extends Store {

    // Private data
    Map<String, List<Repository>> _allRepos;
    RepoGridData _storage;

    // Public data
    String get currentPage => _storage.currentPage;
    List<Repository> get currentPageRepos => _allRepos[currentPage];
    List<String> get pageNames => _storage.pageNames;


    ReposStore(storage) {
        _storage = storage;
        _allRepos = {};

        initializeCurrentPageRepos();

        // Subscriptions
        Pubsub.subscribe('repo.added', _getPayload(onAddRepo));
        Pubsub.subscribe('repo.update', _getPayload(onRefresh));
        Pubsub.subscribe('repo.removed', _getPayload(onRemoveRepo));
        Pubsub.subscribe('page.deleted', _getPayload(onDeletePage));
        Pubsub.subscribe('page.edited', _getPayload(onEditPage));
        Pubsub.subscribe('page.refresh', _getPayload(onRefreshPage));
        Pubsub.subscribe('page.switch', _getPayload(onSwitchPage));
    }

    Future initializeCurrentPageRepos() {
        var currentPageRepos = _storage.getRepos(_storage.currentPage);
        List<Future> futures = [];
        List<Repository> repos = [];
        currentPageRepos.forEach((repoName) {
            var repo = new Repository(repoName);
            repos.add(repo);
            futures.add(repo.initializeData());
        });
        // Trigger immediately, and also when the data is done loading
        _allRepos[_storage.currentPage] = repos;
        trigger();

        return Future.wait(futures).then((futures) {
            _allRepos[_storage.currentPage] = repos;
            trigger();
        });
    }

    onAddRepo(String repoName) {
        var pageRepos = _allRepos[_storage.currentPage];
        var repo = new Repository(repoName);
        pageRepos.add(repo);

        trigger('repo.added');
        repo.initializeData().then((futures) {
            trigger('repo.added');
        });
        _storage.addRepo(repoName);
    }

    onRefresh(String pageName) {
        trigger();
    }

    onRemoveRepo(String repoName) {
        var pageRepos = _allRepos[_storage.currentPage];

        // TODO clean this up
        var repoToRemove = null;
        pageRepos.forEach((repo) {
            if (repo.name == repoName) {
                repoToRemove = repo;
            }
        });
        pageRepos.remove(repoToRemove);

        trigger('repo.removed');
        _storage.removeRepo(repoName);
    }

    onDeletePage(String pageName) {
        _allRepos.remove(_storage.currentPage);
        _storage.deletePage(pageName);
        onSwitchPage(_storage.currentPage);
    }

    onEditPage(String pageName) {
        var pageRepos = _allRepos[_storage.currentPage];
        _allRepos[pageName] = pageRepos;
        _allRepos.remove(_storage.currentPage);
        _storage.editPage(pageName);
        trigger('page.edited');
    }

    onRefreshPage(String pageName) {
        initializeCurrentPageRepos();
    }

    onSwitchPage(String pageName) {
        _storage.currentPage = pageName;
        if (currentPageRepos == null) {
            initializeCurrentPageRepos();
        } else {
            trigger('page.switched');
        }
    }

    _getPayload(toCall) {
        return (msg) {
            toCall(msg.args[0]);
        };
    }
}