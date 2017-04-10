import 'Executor.dart';
import 'dart:async';
import 'dart:io';

class Queue {

  Executor _executor;
  Map<int, Query> _queue;

  Queue(Executor exe) {
    _executor = exe;
    _queue = new Map();
  }

  int nextId() {
    return _queue.length; //Maybe make this unique? Do we need it?
  }

  /**
   * Returns true if a run has been scheduled
   */
  bool push(int id, Future<File> uppalModelPath, Future<File> queryPath) {
    if (_queue.containsKey(id))
      return false;

    _add(id, uppalModelPath, queryPath);

    return _queue.containsKey(id); //Should always be true
  }

  QueryStatus status(int id) {
    if (!_queue.containsKey(id))
      return QueryStatus.NotStarted;

    return _queue[id].status;
  }

  ProcessResult getResultIfFinished(int id) {
    if (status(id) == QueryStatus.Finished) {
      ProcessResult result = _queue[id].result;
      //_queue.remove(id); TODO: Remove result from memory a while after. Also delete uppaal file and query file
      return result;
    }
    return null;
  }

  void _add(int id, Future<File> uppaalModelPath, Future<File> queryPath) {
    uppaalModelPath.then((uppaalFile) => queryPath.then((queryFile) =>
      _queue[id] = _executor.run(id, uppaalFile.absolute.path, queryFile.absolute.path)
    ));
  }
}