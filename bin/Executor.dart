import 'dart:async';
import 'dart:io';

class Executor {

  String _verifyta;

  Executor(String verifytaPath) {
    _verifyta = verifytaPath;
  }

  Query run(int id, String modelFilePath, String queryFilePath) {
    return new Query(id, Process.run(_verifyta, [modelFilePath, queryFilePath]));
  }

  ProcessResult runSync(String modelFilePath, String queryFilePath) {
    return Process.runSync(_verifyta, [modelFilePath, queryFilePath]);
  }
}

class Query {
  int id;
  ProcessResult result;
  bool get isFinished => result != null;
  QueryStatus get status => isFinished ? QueryStatus.Finished : QueryStatus.Running;

  Query(int id, Future<ProcessResult> future) {
    this.id = id;
    future.then((finished) => result = finished);
  }
}

enum QueryStatus {
  NotStarted, Running, Finished
}
