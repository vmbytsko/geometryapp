import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geometryapp/algorithm/finder.dart';
import 'package:geometryapp/algorithm/parser.dart';
import 'package:geometryapp/algorithm/solver.dart';
import 'package:geometryapp/ui.dart';
import 'package:geometryapp/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'algorithm/isolate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    logMain("Stating main app");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GeometryApp',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      darkTheme: ThemeData(primarySwatch: Colors.amber),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String status = "Введите условие задачи";
  String answer = "";
  String detailedAnswer = "";

  double _range = 0.0;
  double _indicatorSize = 2;
  double _systemNavBarHeight = 0.0;
  bool _blockButton = false;
  Map problemBlocks = {};
  Map findBlocks = {};
  List<Widget> uiProblemBlocks = [];
  List<Widget> uiFindBlocks = [];

  @override
  void initState() {
    logMain("Stating main page");
    super.initState();
    var widgetsBindInstance = WidgetsBinding.instance!;
    widgetsBindInstance.addPostFrameCallback((_) => getSystemNavBarHeight()
        .then((value) => setState(() => _systemNavBarHeight = value)));
    var window = widgetsBindInstance.window;
    window.onPlatformBrightnessChanged = () {
      handleBrightness(window.platformBrightness);
    };
    handleBrightness(window.platformBrightness);

    setState(() {
      uiProblemBlocks.add(plusBlockButton(1));
      uiFindBlocks.add(plusBlockButton(2));
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget plusBlockButton(int type) {
    return Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 3, top: 2),
        child: IconButton(
            onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) => CupertinoAlertDialog(
                      title: Text(type == 1
                          ? "Добавить условие:"
                          : type == 2
                              ? "Необходимо найти:"
                              : ""),
                      content: SizedBox(
                        child: FutureBuilder<Widget>(
                          future: addBlockDialog(type),
                          builder: (BuildContext context,
                              AsyncSnapshot<Widget> snapshot) {
                            Widget widget = const SizedBox(
                                height: 10, width: 10, child: Text(""));
                            if (snapshot.hasData) {
                              widget = snapshot.data!;
                            } else if (snapshot.hasError) {
                              widget = const Text("Error!");
                            }
                            return widget;
                          },
                        ),
                      ),
                    )),
            icon: const Icon(Icons.add)));
  }

  Future<Widget> addBlockDialog(int type) async {
    String searchUI = type == 1
        ? "problemUI"
        : type == 2
            ? "findUI"
            : "";
    Map mainJSON =
        jsonDecode(await rootBundle.loadString('assets/data/main.json'));
    Map polygonsJSON =
        jsonDecode(await rootBundle.loadString('assets/data/polygons.json'));

    Map simpleObjects = {...mainJSON, ...polygonsJSON};
    List<Widget> children = [];
    List<Widget> tempChildren = [];
    try {
      for (var simpleObject in simpleObjects.keys) {
        if (!simpleObject.startsWith("..")) {
          if (simpleObjects[simpleObject].keys.contains(searchUI)) {
            for (var i = 0;
                i < simpleObjects[simpleObject][searchUI].length;
                i++) {
              var searchUIr = simpleObjects[simpleObject][searchUI][i];
              //print("$searchUI'r: $searchUIr");
              for (var uiString in searchUIr["ui"]) {
                //print("uiString: $uiString");
                if (uiString.startsWith("'") && uiString.startsWith("'")) {
                  // this string is exact string
                  tempChildren.add(Text(
                    uiString.substring(1, uiString.length - 1),
                    style: const TextStyle(
                        fontFamily: "Times New Roman",
                        fontStyle: FontStyle.italic),
                  ));
                } else {
                  // this ui string is a text field
                  tempChildren.add(Padding(
                      padding: const EdgeInsets.all(1),
                      child: Container(
                          decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 255, 229, 127),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(3))),
                          height: 28,
                          width: 28,
                          child: Align(
                              alignment: Alignment.center,
                              child: uiString.split(":")[1] == "letter"
                                  ? Text(
                                      uiString
                                          .split(":")[0]
                                          .substring(1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.black38,
                                          fontFamily: "Times New Roman"),
                                    )
                                  : uiString.split(":")[1] == "double"
                                      ? const Center(
                                          child: Text("0.0",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black38,
                                                  fontFamily:
                                                      "Times New Roman")))
                                      : const SizedBox.shrink()))));
                  //print("hello there!");
                }
              }
              children.add(MaterialButton(
                child: Row(children: tempChildren),
                /*onPressed: () => addProblemBlock(
                  simpleObjects[simpleObject]["problemUI"][i]),*/
                onPressed: () =>
                    addBlock(type, simpleObjects[simpleObject][searchUI][i]),
              ));
              tempChildren = [];
            }
          }
        }
      }
    } catch (e, e1) {
      //print("$e $e1");
    }

    Widget widget = SizedBox(
        width: 200,
        child: Column(
          children: children,
        ));

    return widget;
  }

  void addBlock(int type, var blockUI) {
    Navigator.pop(context);
    //print("$blockUI");
    String id = IDforObject();

    if (type == 1) {
      while (problemBlocks.keys.contains(id)) {
        id = IDforObject();
      }
    } else if (type == 2) {
      while (findBlocks.keys.contains(id)) {
        id = IDforObject();
      }
    }
    //print(id);
    var object = {};
    List<InlineSpan> widgetSpans = [];
    var widget = Padding(
        padding:
            const EdgeInsets.only(top: 10, right: 15, left: 20, bottom: 12),
        child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Text.rich(
              TextSpan(children: widgetSpans),
              style: TextStyle(
                  background: Paint()
                    ..color = Colors.white
                    ..strokeWidth = 30
                    ..strokeJoin = StrokeJoin.round
                    ..strokeCap = StrokeCap.round
                    ..style = PaintingStyle.stroke,
                  fontSize: 14,
                  color: Colors.black,
                  fontStyle: FontStyle.italic,
                  fontFamily: "Times New Roman"),
            )));
    for (var str in blockUI["ui"]) {
      if (str.startsWith("\$")) {
        // new variable
        object[str.split(":")[0].substring(1)] = TextEditingController();
        widgetSpans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 30, maxHeight: 30),
              child: TextField(
                controller: object[str.split(":")[0].substring(1)],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: "Times New Roman", fontSize: 20),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 255, 229, 127),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 1)),
                  enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white54, width: 0.1)),
                  border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white54, width: 0.1)),
                  contentPadding: EdgeInsets.all(3.5),
                ),
              ),
            )));
      } else if (str.startsWith("'") && str.endsWith("'")) {
        widgetSpans.add(TextSpan(text: str.substring(1, str.length - 1)));
      }
    }
    widgetSpans.add(WidgetSpan(
        child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: GestureDetector(
                child: const Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: Colors.red,
                ),
                onTap: () {
                  if (type == 1) {
                    problemBlocks.remove(id);
                  } else if (type == 2) {
                    findBlocks.remove(id);
                  }
                  updateBlocks(type);
                }))));
    if (type == 1) {
      problemBlocks[id] = {};
      problemBlocks[id]["variables"] = object;
      problemBlocks[id]["widget"] = widget;
      problemBlocks[id]["problemUI"] = blockUI;
    } else if (type == 2) {
      findBlocks[id] = {};
      findBlocks[id]["variables"] = object;
      findBlocks[id]["widget"] = widget;
      findBlocks[id]["findUI"] = blockUI;
    }

    updateBlocks(type);
  }

  void updateBlocks(int type) {
    List<Widget> tempList = [plusBlockButton(type)];
    if (type == 1) {
      for (var object in problemBlocks.entries) {
        tempList.add(object.value["widget"]);
      }

      setState(() {
        uiProblemBlocks = tempList;
      });
    } else if (type == 2) {
      for (var object in findBlocks.entries) {
        tempList.add(object.value["widget"]);
      }

      setState(() {
        uiFindBlocks = tempList;
      });
    }
  }

  showUiProblem(bool debug) {
    setState(() {
      answer = parseUiProblem(debug);
    });
  }

  String parseUiProblem(bool debug) {
    logMain("Parsing UI problem");
    String parseProblem = "";
    for (var object in problemBlocks.entries) {
      String donestr = "";
      //print(object.value);
      for (var str in object.value["problemUI"]["parse"]) {
        if (str.startsWith("'") && str.endsWith("'")) {
          donestr = donestr + str.substring(1, str.length - 1);
        } else if (str.startsWith("\$")) {
          donestr = donestr + object.value["variables"][str.substring(1)].text;
        }
      }
      parseProblem = parseProblem + donestr + "&";
    }
    for (var object in findBlocks.entries) {
      String donestr = "";
      //print(object.value);
      for (var str in object.value["findUI"]["parse"]) {
        if (str.startsWith("'") && str.endsWith("'")) {
          donestr = donestr + str.substring(1, str.length - 1);
        } else if (str.startsWith("\$")) {
          donestr = donestr + object.value["variables"][str.substring(1)].text;
        }
      }
      parseProblem = parseProblem + donestr + "&";
    }
    String doneParseProblem = parseProblem.substring(0, parseProblem.length - 1);
    logMain("UI problem parsed! $doneParseProblem");
    return doneParseProblem;
  }

  Future<void> _geometryProblem(String problem, bool debug) async {
    String isolateID = getRandomString(4);
    logMainDebug("Starting to solve geometryProblem ($problem)", debug);
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    logMainDebug("Version of app: ${packageInfo.version} (${packageInfo.buildNumber})", debug);

    logMainDebug("Creating isolate", debug);
    ReceivePort _originReceivePort = ReceivePort();
    SendPort? _remoteSendPort;
    await Isolate.spawn(remoteIsolate, _originReceivePort.sendPort);
    logMainDebug("Created isolate", debug);

    setState(() {
      status = "Создали изолят";
    });

    _originReceivePort.listen((message) async {
      logIsolateDebug(isolateID, "$message", debug);
      if (message is SendPort) {
        logMainDebug("Got SendPort from isolate", debug);
        _remoteSendPort = message;
        setState(() {
          status = "Запуск изолята";
        });
        logMainDebug("Sending start signal to isolate", debug);
        _remoteSendPort?.send("debug:$debug");
        _remoteSendPort?.send("start:$problem");
      } else if (message is String) {
        if (message.startsWith("status:")) {
          String newStatus = message.substring(7);
          logMainDebug("Setting status to $newStatus", debug);
          setState(() {
            status = newStatus;
          });
        } else if (message.startsWith("answer:")) {
          String newAnswer = message.substring(7);
          logMainDebug("Setting answer to $newAnswer", debug);
          setState(() {
            answer = newAnswer;
          });
        } else if (message.startsWith("detailedAnswer:")) {
          String newDetailedAnswer = message.substring(15);
          logMainDebug("Setting detailed answer to $newDetailedAnswer", debug);
          setState(() {
            detailedAnswer = newDetailedAnswer;
          });
        } else if (message == "needsSimpleObjects") {
          logMainDebug("Sending simpleObjects to isolate", debug);
          Map mainJSON =
              jsonDecode(await rootBundle.loadString('assets/data/main.json'));
          Map polygonsJSON = jsonDecode(
              await rootBundle.loadString('assets/data/polygons.json'));

          Map simpleObjects = {...mainJSON, ...polygonsJSON};
          _remoteSendPort?.send(["simpleObjects", simpleObjects]);
        } else if (message.startsWith("range:")) {
          double newRange = double.parse(message.substring(6));
          logMainDebug("Setting range to $newRange", debug);
          setState(() {
            _range = newRange;
            if (_range == 1.0) {
              _indicatorSize = 2.0;
            } else {
              _indicatorSize = 5.0;
            }
          });
        } else if (message.startsWith("blockbutton:")) {
          bool newBlockButton = (message.substring(12) == "true");
          logMainDebug("Setting blockButton to $newBlockButton", debug);
          setState(() {
            _blockButton = newBlockButton;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    logMain("Building main page");
    return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        " Дано:",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Times New Roman",
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: Colors.amberAccent[100]),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(left: 0),
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.start,
                                    children: uiProblemBlocks,
                                  )),
                            ]),
                        width: double.infinity,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        " Найти:",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Times New Roman",
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: Colors.amberAccent[100]),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(left: 0),
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.start,
                                    children: uiFindBlocks,
                                  )),
                            ]),
                        width: double.infinity,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        " Ответ:",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Times New Roman",
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        answer,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Times New Roman",
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        detailedAnswer,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Times New Roman",
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  )),
              const SizedBox(height: 100)
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _blockButton
              ? () => {}
              : () {
            logMain("Sending UI geometry problem to solve it");
            _geometryProblem(parseUiProblem(kDebugMode), kDebugMode);
            },
          child: const Icon(Icons.arrow_forward),
        ),
        bottomNavigationBar: SizedBox(
            height: kBottomNavigationBarHeight * 1.5 + _systemNavBarHeight,
            width: MediaQuery.of(context).size.width,
            child: Stack(children: [
              LinearProgressIndicator(
                minHeight: _indicatorSize,
                value: _range,
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                          height: kBottomNavigationBarHeight * 1.5, width: 10),
                      IconButton(
                          constraints: const BoxConstraints.expand(
                              height: kBottomNavigationBarHeight - 10,
                              width: kBottomNavigationBarHeight - 10),
                          onPressed: () => devDialog(
                              context, _geometryProblem, showUiProblem),
                          icon: const Icon(Icons.code)),
                      const SizedBox(width: 30),
                      Flexible(
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontFamily: "Times New Roman",
                              fontWeight: FontWeight.bold),
                        ),
                        fit: FlexFit.tight,
                      ),
                      const SizedBox(width: 30),
                      IconButton(
                          constraints: const BoxConstraints.expand(
                              height: kBottomNavigationBarHeight - 10,
                              width: kBottomNavigationBarHeight - 10),
                          onPressed: () => showDialog(context: context, builder: (BuildContext context) => const CupertinoAlertDialog(
                              title: Text("Информация"),
                              content: Text("Нажав на кнопку 'плюс' в блоках 'Дано' или 'Найти', появится меню возможных объектов для добавления. Нажмите на нужный блок, чтобы добавить его в поле. Если Вы добавили неверный блок, можно нажать на красный минус у блока с объектом. После добавления всех нужных блоков, нажмите на стрелку внизу приложения. Вам выведется ответ."))),
                          icon: const Icon(Icons.help)),
                      const SizedBox(
                          height: kBottomNavigationBarHeight * 1.5, width: 10)
                    ],
                  ),
                  SizedBox(height: _systemNavBarHeight.toDouble()),
                ],
              )
            ])));
  }
}
