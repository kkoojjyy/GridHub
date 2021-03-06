library gridhub.src.components.milestones_pane;

import 'package:react/react.dart' as react;
import 'package:web_skin_react/web_skin_react.dart';

import 'package:gridhub/src/components/content_loading.dart';
import 'package:gridhub/src/components/fancy_list_group_item.dart';
import 'package:gridhub/src/components/no_results_icon.dart';
import 'package:gridhub/src/components/octicon.dart';
import 'package:gridhub/src/models/repository.dart';
import 'package:gridhub/src/utils/date_utils.dart';

var MilestonesPane = react.registerComponent(() => new _MilestonesPane());
class _MilestonesPane extends react.Component {

  getDefaultProps() {
    return {
      'repo': null
    };
  }

  render() {
    Repository repo = this.props['repo'];
    var milestones = repo.milestonesData;

    var listItems = [];

    milestones.forEach((milestone) {
      String dueDateStr = milestone['due_on'];
      var dueDateMessage;
      if (dueDateStr == null) {
        dueDateMessage = react.span({'className': 'text-muted'}, 'No due date');
      }
      else {
        String dueDateClassName = 'text-muted';
        DateTime dueDate = DateTime.parse(dueDateStr);
        DateTime now = new DateTime.now();
        Duration diff = dueDate.difference(now);
        var dueDateIcon = 'calendar';
        if (diff.inHours < 0) {
          dueDateClassName = 'text-bold text-danger';
          dueDateIcon = 'alert';
        }
        dueDateMessage = react.span({'className': dueDateClassName}, [
          Octicon({'icon': dueDateIcon, 'style': {'marginRight': '4px'}}),
          react.span({}, 'Due ${getRelativeDueDate(dueDate)}')
        ]);
      }

      var title = react.div({'className': 'milestone-title'}, [
        react.h4({'className': 'list-group-item-heading'}, [
          react.a({'href': milestone['html_url'], 'target': repo.name}, milestone['title'])
        ]),
        react.div({}, [
          dueDateMessage
        ])
      ]);

      int openIssues = milestone['open_issues'];
      int closedIssues = milestone['closed_issues'];
      int totalIssues = openIssues + closedIssues;
      int progressPercentage = 0;
      if (totalIssues > 0) {
        progressPercentage = (closedIssues / (totalIssues) * 100).ceil();
      }
      var progress = react.div({'className': 'milestone-progress'}, [
        ProgressBar({'wsStyle': 'success', 'now': progressPercentage}),
        react.span({}, [
          react.span({'className': 'text-bold'}, '${progressPercentage}%'),
          react.span({'className': 'text-muted'}, ' complete'),
        ]),
        react.span({'style': {'marginLeft': '15px'}}, [
          react.span({'className': 'text-bold'}, '${openIssues}'),
          react.span({'className': 'text-muted'}, ' open')
        ]),
        react.span({'style': {'marginLeft': '15px'}}, [
          react.span({'className': 'text-bold'}, '${closedIssues}'),
          react.span({'className': 'text-muted'}, ' closed')
        ])
      ]);

      listItems.add(
        FancyListGroupItem({'key': 'milestone-${milestone['title']}'}, [
          title,
          progress
        ])
      );

    });

    var content;
    if (listItems.length > 0) {
      content = react.div({'className': 'scrollable-pane'}, [
        ListGroup({}, listItems)
      ]);
    }
    else if (repo.dataInitialized != true) {
      content = ContentLoading({});
    }
    else {
      content = NoResultsIcon({});
    }

    return content;
  }
}
