import 'Queue.dart';
import 'package:intl/intl.dart';
import 'package:redstone/redstone.dart' as web;
import 'package:args/args.dart';
import 'dart:io';
import 'dart:async';
import 'Executor.dart';

Executor executor;
Queue queryQueue;

main(List<String> args) {
  var arguments = setupArgumentParser().parse(args);
  String verifytaPath = arguments["verifyta-path"];
  if (verifytaPath == null || verifytaPath.isEmpty) {
    print("Specify the path to verifyta executable with the 'verifyta-path' argument");
    exit(1);
  }

  executor = new Executor(verifytaPath);
  queryQueue = new Queue(executor);
  int port = int.parse(arguments["port"]);

  print("Starting webservice on port $port using following executeable as verifyta: $verifytaPath");
  web.setupConsoleLog();
  web.start(port: port);
}

ArgParser setupArgumentParser() {
  var argParser = new ArgParser();
  argParser.addOption("verifyta-path", help: "Specify the path to the executable of Verifyta");
  argParser.addOption("port", help: "Override default port for webservice (60000)", defaultsTo: "60000");
  return argParser;
}

@web.Route("/run", methods: const [web.POST], allowMultipartRequest: true)
run(@web.Body(web.FORM) Map form) async {
  var file = form["upload-file"];
  var query = form["query"];

  String now = new DateFormat("yyyy_MM_dd_H_m_s").format(new DateTime.now());
  String fileName = "$now\_${file.filename}";

  File uppaalFile = new File(fileName);
  uppaalFile.writeAsStringSync(new String.fromCharCodes(file.content));

  File queryFile = new File(fileName + ".q");
  queryFile.writeAsStringSync(query);

  ProcessResult results = executor.runSync(uppaalFile.absolute.path, queryFile.absolute.path);
  return results.stdout;
}

@web.Route("/queue", methods: const [web.POST], allowMultipartRequest: true)
queue(@web.Body(web.FORM) Map form) {
  var file = form["upload-file"];
  var query = form["query"];

  int id = queryQueue.nextId();
  String fileName = "query_$id\_${file.filename}";

  Future<File> uppaalFile = new File(fileName).writeAsString(new String.fromCharCodes(file.content));
  Future<File> queryFile = new File(fileName + ".q").writeAsString(query);


  queryQueue.push(id, uppaalFile, queryFile);

  return id;
}

@web.Route("/queue/:id", methods: const [web.GET])
getQuery(int id) {
  switch (queryQueue.status(id)) {
    case QueryStatus.NotStarted:
      return "A query with ID $id has not been started.";
    case QueryStatus.Running:
      return "Query with ID $id is still running in UPPAAL.";
    case QueryStatus.Finished:
      return queryQueue.getResultIfFinished(id).stdout;
  }
}