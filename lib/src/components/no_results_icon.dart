library gridhub.src.components.no_results_icon;

import 'package:react/react.dart' as react;

import 'package:gridhub/src/components/octicon.dart';

var NoResultsIcon = react.registerComponent(() => new _NoResultsIcon());
class _NoResultsIcon extends react.Component {

  render() {
    return react.div({'className': 'empty-results'}, [
      Octicon({'icon': 'gift', 'style': {'fontSize': '28px', 'key': 'icon'}}),
      react.div({'key': 'description'}, 'Nothing to show!')
    ]);
  }
}
