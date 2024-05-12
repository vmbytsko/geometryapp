import 'dart:isolate';

import 'package:geometryapp/algorithm/parser.dart';
import 'package:geometryapp/algorithm/solver.dart';

import '../utils.dart';
import 'finder.dart';

void remoteIsolate(SendPort _originSendPort) {
  _originSendPort.send("Started remote isolate");
  ReceivePort _remoteReceivePort = ReceivePort();
  _originSendPort.send(_remoteReceivePort.sendPort);
  _originSendPort.send("Sent remoteSendPort to main");
  String _problem = "";
  bool _debug = false;
  Map _simpleObjects = {};
  Map _memory = {};
  Map _consequencesMemory = {};

  void originSend(String text) {
    if(!text.startsWith("log:") || _debug) {
      _originSendPort.send(text);
    }
  }
  
  _remoteReceivePort.listen((message) {
    originSend("log:Origin messaged: $message");
    try {
      if (message is String) {
        if (message.startsWith("start:")) {
          originSend("log:Starting solving problem");
          ////////////////////////////////////////
          // PARSING PROBLEM STRING

          originSend("log:Parsing problem string");
          _problem = message.substring(6);
          originSend("range:0.0");
          originSend("blockbutton:true");
          originSend("log:Parsed! $_problem");

          ////////////////////////////////////////
          // GETTING SIMPLE OBJECTS

          originSend("log:Giving simpleObjects");
          originSend("status:1. Чтение simpleObjects...");
          originSend("log:requesting simpleObjects from origin");
          originSend("needsSimpleObjects");

          ////////////////////////////////////////
        } else if (message.startsWith("debug:")) {
          _debug = (message.substring(6) == "true");
        }
      } else if (message is List) {
        if (message[0] == "simpleObjects") {
          ////////////////////////////////////////
          // GETTING SIMPLE OBJECTS STEP 2

          originSend("log:Got simpleString fron origin!");
          _simpleObjects = message[1];
          originSend(prettyConvert(_simpleObjects));
          originSend("range:0.1");

          ////////////////////////////////////////
          // PARSING PROBLEM STRING

          originSend("log:Reading сonditions of problem");
          originSend("status:2. Чтение \"Дано\"...");
          Uri url = Uri.parse('https://www.example.com/?' + _problem);

          for (var queryEntry in url.queryParametersAll.entries) {
            for (var queryValue in queryEntry.value) {
              parseObject(_memory, _simpleObjects, _consequencesMemory, queryValue,
                  queryEntry.key, originSend, true);
            }
          }
          originSend("log:Read (/red/) сonditions of problem!");
          originSend(prettyConvert(_memory));
          originSend("range:0.2");

          ////////////////////////////////////////
          // SOLVING ALREADY GIVEN CONSEQUENCES

          originSend("log:Solving already given consequences");
          originSend("status:3. Решение...");
          solveConsequences(_memory, _simpleObjects, _consequencesMemory, originSend);
          String tempStr1 =
          getAnswer(_memory, _simpleObjects, _consequencesMemory, originSend);
          if (tempStr1 != "") {
            // WE FOUND THE ANSWER
            originSend("\x1B[32mFound the answer!\x1B[0m $tempStr1");
            originSend(prettyConvert(_memory));
            // TODO
            makeSolveText(_memory, _simpleObjects, _consequencesMemory, originSend);
            List toFind = [];
            for(var id in _memory.entries) {
              if(id.value[0]["toFind"] == true) toFind.add(id.key);
            }
            originSend("consMemory "+prettyConvert(_consequencesMemory)+" $toFind");

            originSend("status:Ответ получен!");
            originSend("answer:$tempStr1");
            originSend("detailedAnswer:${makeSolveText(_memory, _simpleObjects, _consequencesMemory, originSend)}");
            originSend("range:1.0");
            originSend("blockbutton:false");
            Isolate.exit(_originSendPort);
          } else {
            // WE DID NOT FIND THE ANSWER
            originSend("log:Did not find the answer");
            originSend(prettyConvert(_memory));

            ////////////////////////////////////////
            // FINDING NEW OBJECTS AND SOLVING CONSEQUENCES IN PARRALLEL
            originSend("log:Finding new objects");
            originSend("status:4. Поиск новых объектов...");
            findNewObjects(_memory, _simpleObjects, _consequencesMemory, originSend);
            originSend("log:Found new objects!");
            originSend(prettyConvert(_memory));
            originSend("range:0.8");

            // ANSWERING QUESTIONS
            var tempStr2 =
            getAnswer(_memory, _simpleObjects, _consequencesMemory, originSend);
            if (tempStr2 != "") {
              originSend("log:\x1B[32mFound the answer (second attempt)!\x1B[0m $tempStr2");
              originSend(prettyConvert(_memory));
              // WE FOUND THE ANSWER
              originSend("status:Ответ получен!");
              originSend("answer:$tempStr2");
              originSend("detailedAnswer:${makeSolveText(_memory, _simpleObjects, _consequencesMemory, originSend)}");
            } else {
              originSend("log:\x1B[31mDid not find the answer (second attempt)\x1B[0m");
              originSend(prettyConvert(_memory));
              // WE DID NOT FIND THE ANSWER
              originSend("status:Ответ не получен :(");
              originSend("answer: ");
              originSend("detailedAnswer: ");
            }
            originSend("range:1.0");
            originSend("blockbutton:false");
            Isolate.exit(_originSendPort);
          }
        }
      }
    } catch (e, e1) {
      originSend("log:\x1B[31mGot an error:\x1B[0m");
      originSend("log:\x1B[31m$e\x1B[0m");
      originSend("log:\x1B[31m$e1\x1B[0m");
      originSend(
          "status:Ошибка! Отправьте её разработчику, используя кнопу слева.");
      originSend("blockbutton:false");
      originSend("answer: ");
      Isolate.exit(_originSendPort);
    }
  });
}