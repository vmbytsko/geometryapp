import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geometryapp/algorithm/parser.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class Utils {}

Map jsonReplaceAll(Map object, String string) {
  Map newObject = {};
  for (var key in object.keys) {
    var value = object[key];
    if (value is String) {
      List separatedValue = value.split("#");
      String newValue = "";

      for (int i = 0; i < separatedValue.length; i++) {
        if (i % 2 == 0) {
          newValue = newValue + separatedValue[i];
        } else {
          String argumentValue = separatedValue[i];
          if (argumentValue.startsWith("cyclefrom")) {
            List tempnums =
                argumentValue.replaceAll("cyclefrom", "").split("to");
            String strnum1 = tempnums[0];
            String strnum2 = tempnums[1];
            int num1 = 0;
            int num2 = 0;
            if (strnum1 == "*") {
              num1 = string.length - 1;
            } else {
              num1 = int.parse(strnum1);
            }
            if (strnum2 == "*") {
              num2 = string.length - 1;
            } else {
              num2 = int.parse(strnum2);
            }
            newValue = newValue + string.substring(num1, num2);
          } else if (argumentValue.startsWith("polygon")) {
          } else {
            String tempnum1 = "";
            String tempnum2 = "";
            bool range = false;

            for (int j = 0; j < argumentValue.length; j++) {
              if ("0123456789*".contains(argumentValue[j])) {
                if (!range) {
                  tempnum1 = tempnum1 + argumentValue[j];
                } else {
                  tempnum2 = tempnum2 + argumentValue[j];
                }
              } else if (argumentValue[j] == ",") {
                if (range) {
                  int startPoint = 0;
                  if (tempnum1 != "*") {
                    startPoint = int.parse(tempnum1);
                  } else {
                    startPoint = string.length - 1;
                  }
                  int endPoint = 0;
                  if (tempnum2 != "*") {
                    endPoint = int.parse(tempnum2);
                  } else {
                    endPoint = string.length - 1;
                  }
                  for (var k = startPoint; k <= endPoint; k++) {
                    newValue = newValue + string[k];
                  }
                }
                if (tempnum1 == "*") {
                  newValue = newValue + string[string.length - 1];
                } else if (int.parse(tempnum1) < string.length) {
                  newValue = newValue + string[int.parse(tempnum1)];
                }
                tempnum1 = "";
                tempnum2 = "";
                range = false;
              } else if (argumentValue[j] == "-") {
                range = true;
              }
            }

            if (range) {
              int startPoint = 0;
              if (tempnum1 != "*") {
                startPoint = int.parse(tempnum1);
              } else {
                startPoint = string.length - 1;
              }
              int endPoint = 0;
              if (tempnum2 != "*") {
                endPoint = int.parse(tempnum2);
              } else {
                endPoint = string.length - 1;
              }
              for (var k = startPoint; k <= endPoint; k++) {
                newValue = newValue + string[k];
              }
            } else if (tempnum1 != "") {
              if (tempnum1 == "*") {
                newValue = newValue + string[string.length - 1];
              } else if (int.parse(tempnum1) < string.length) {
                newValue = newValue + string[int.parse(tempnum1)];
              }
            }
          }
        }
      }
      newObject[key] = newValue;
    } else {
      newObject[key] = jsonReplaceAll(value, string);
    }
  }
  return newObject;
}

dynamic parseObjectByString(Map memory, Map simpleObjects,
    Map consequencesMemory, String objectByString, originSend, bool byParser) {
  List arguments = objectByString.split(".");
  String objectName = arguments[0].split("(")[0];
  if (arguments[0].split("(").length >= 2) {
    String objectValue = arguments[0].split("(")[1];
    return parseObject(memory, simpleObjects, consequencesMemory, objectName,
        objectValue.replaceAll(")", ""), originSend, byParser);
  } else {
    return objectByString;
  }
}

String fullIncludeCheckID(Map objects, Map object) {
  var objectsKeys = objects.keys.toList();
  /**/
  for (var i = 0; i < objectsKeys.length; i++) {
    for (var j = 0; j < objects[objectsKeys[i]].length; j++) {
      var objectToJson = jsonDecode(jsonEncode(object));
      objectToJson.remove("toFind");
      objectToJson.remove("byParser");
      objectToJson.remove("byConsequence");
      objectToJson.remove("..consequences");

      var objectToCheckToJson =
          jsonDecode(jsonEncode(objects[objectsKeys[i]][j]));
      objectToCheckToJson.remove("toFind");
      objectToCheckToJson.remove("byParser");
      objectToCheckToJson.remove("byConsequence");
      objectToCheckToJson.remove("..consequences");
      if (jsonEncode(objectToJson) == jsonEncode(objectToCheckToJson)) {
        return objectsKeys[i];
      }
    }
  }
  return "";
}

List allIDsOfName(Map memory, String objectName) {
  List ids = [];
  for (var object in memory.entries) {
    if (object.value[0]["type"] == objectName) {
      ids.add(object.key);
    }
  }
  return ids;
}

Map allObjectsOfName(Map memory, String objectName) {
  Map objects = {};
  for (var object in memory.entries) {
    if (object.value[0]["type"] == objectName) {
      objects[object.key] = memory[object.key];
    }
  }
  return objects;
}

List allConsequences(Map memory, originSend) {
  /*List consequences = [];
  // получаем все объекты в виде айди: лист
  for (var object in memory.entries) {
    // берём каждый элемент листа, каждый энтрай
    for (var i = 0; i < object.value.length; i++) {
      // если в энтрае есть следствия
      if (object.value[i].keys.contains("..consequences")) {
        // принтим их, но не видим их в консоли почему-то
        originSend("${memory[object.key]} ${object.key}");
        // получаем в виде отдельного списка
        List objectConsequences =
            List.from(memory[object.key][i]["..consequences"]);
        // каждый добавляем
        for (var objectConsequence in objectConsequences) {
          objectConsequence["objectid"] = object.key;
          objectConsequence["objectentryorder"] = i;
          consequences.add(objectConsequence);
        }
      }
    }
  }*/
  //return consequences;
  List consequences = [];
  for (var object in memory.entries) {
    for (var i = 0; i < object.value.length; i++) {
      if (object.value[i].keys.contains("..consequences")) {
        if (object.value[i]["..consequences"] != []) {
          originSend(
              "CONSEQUENCE MASTER: ${object.key}[$i] ${memory[object.key][0]["type"]}");
          for (var j = 0; j < object.value[i]["..consequences"].length; j++) {
            var newObject =
                jsonDecode(jsonEncode(object.value[i]["..consequences"][j]));
            originSend(
                "CONSEQUENCE MASTER2: ${object.key}[$i] ${memory[object.key][0]["type"]}");
            newObject["objectid"] = object.key;
            newObject["objectentryorder"] = i;
            //originSend(" debug ${object.value[i]["..consequences"][j]["objectid"]} ${object.value[i]["..consequences"][j]["objectentryorder"]}");
            consequences.add(newObject);
          }
        }
      }
    }
  }
  return consequences;
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

String IDforObject() {
  return getRandomString(10);
}

/*String freeDot(Map memory) {
  dot =
}*/
List expandArrayOfEntries(List objects) {
  /*
    something similar to permutations()
    Entries: [[{baselime: aaa}, {baseline: bbb}], [{baselime: ccc}, {baseline: ddd}]] => Entries: [
                                [{baseline: aaa}, {baseline: ccc}],
                                [{baseline: bbb}, {baseline: ccc}],
                                [{baseline: aaa}, {baseline: ddd}],
                                [{baseline: bbb}, {baseline: ddd}],
                            ]
    */
  List array = [];
  if (objects.isEmpty) return array;
  for (var i = 0; i < objects[0].length; i++) {
    array.add([objects[0][i]]);
  }
  if (objects.length >= 2) {
    for (var i = 1; i < objects.length; i++) {
      List temparray = [];
      for (var j = 0; j < objects[i].length; j++) {
        for (var o = 0; o < array.length; o++) {
          List ooo = List.of(array[o]);
          ooo.add(objects[i][j]);
          temparray.add(ooo);
        }
      }
      //print("before: $array $temparray");
      array = List.of(temparray);
      //print("after: $array $temparray");
    }
  }
  return array;
}

///////////////////// mathematical functions /////////

List combinations(List array) {
  List combi = [];
  List temp = [];
  int slent = pow(2, array.length).toInt();

  for (int i = 0; i < slent; i++) {
    temp = [];
    for (int j = 0; j < array.length; j++) {
      if ((i & pow(2, j).toInt()) >= 1) {
        temp.add(array[j]);
      }
    }
    if (temp.isNotEmpty) {
      combi.add(temp);
    }
  }
  combi.sort((a, b) => a.length - b.length);
  return combi;
}

List permutations(List source) {
  List allCombinations = combinations(source);
  //print("ALL COMBINATIONS $allCombinations $source");
  List allPermutations = [];
  for (var combination in allCombinations) {
    void permutate(List list, int cursor) {
      // when the cursor gets this far, we've found one permutation, so save it
      if (cursor == list.length) {
        allPermutations.add(list);
        return;
      }

      for (int i = cursor; i < list.length; i++) {
        List permutation = List.from(list);
        permutation[cursor] = list[i];
        permutation[i] = list[cursor];
        permutate(permutation, cursor + 1);
      }
    }

    permutate(combination, 0);
  }

  List strPermutations = [];
  for (List permutation in allPermutations) {
    strPermutations.add(permutation);
  }
  return strPermutations;
}

List partialPermutations(List array, int k) {
  List permuts = permutations(array);
  List newArray = [];
  for (var permut in permuts) {
    if (permut.length == k) {
      newArray.add(permut);
    }
  }
  return newArray;
}

void printWrapped(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

void prettyPrint(Object json) {
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  String prettyprint = encoder.convert(json);
  printWrapped(prettyprint);
}

String prettyConvert(Object json) {
  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  String prettyprint = encoder.convert(json);
  return prettyprint;
}

dynamic getObjectByLinkIntegrated(Map memory, Map simpleObjects,
    Map consequencesMemory, var object, String id, String link, originSend) {
  originSend("getting object by link $link from new object $id");
  List splits = link.split(".");
  dynamic workingObject;
  originSend("789432");
  for (var i = 0; i < splits.length; i++) {
    originSend("789433");
    if (i == 0) {
      // starting point - cannot rely on workingObject
      if (splits[0].startsWith("_")) {
        if (splits[0] == "_id") {
          workingObject = id;
        } else {
          workingObject = splits[0].substring(1);
        }
      } else if (splits[0].startsWith("\$")) {
        originSend(
            "789434 $object ${splits[0].substring(1)} ${object[splits[0].substring(1)]}");
        // from our object
        workingObject = object[splits[0].substring(1)];
      } else {
        originSend("789435 ${splits[0]}");
        // from memory
        // for example, angle($dot1+O+dot($dot2.letter)) -> angle(AOB)

        // at first, we should get what is in brackets:
        var figure = splits[0].substring(0, splits[0].indexOf("("));
        var args = splits[0].substring(splits[0].indexOf("(") + 1).substring(
            0, splits[0].substring(splits[0].indexOf("(") + 1).length - 1);

        // then split by plus
        List argsList = args.split("+");

        String doneArg = "";
        // then parse all
        for (String arg in argsList) {
          originSend("789436 $arg $figure $args $link");
          if (arg.startsWith("\$") ||
              (arg.contains("(") && arg.contains(")"))) {
            originSend("789437");
            doneArg = doneArg +
                getObjectByLinkIntegrated(memory, simpleObjects,
                    consequencesMemory, object, id, arg, originSend);
          } else {
            doneArg = doneArg + arg;
          }
        }
        originSend(
            ("we have great news! $figure($doneArg) ${allObjectsOfName(memory, "dot")}"));
        workingObject = parseObjectByString(memory, simpleObjects,
            consequencesMemory, "$figure($doneArg)", originSend, false);
      }
    } else if (i > 0 && i < splits.length) {
      originSend("223 $workingObject");
      if (splits[i].startsWith("[") && splits[i].endsWith("]")) {
        // working with list - we need to get data from list
        /*if(splits[i] == "[all]") {
          List tempList = [];
          for(var i = 0; i < workingObject.length; i++) {
            tempList.add(getObjectByLinkIntegrated(memory, simpleObjects, object, link, originSend))
          }
        } else {*/
        originSend(
            "224 $workingObject ${splits[i]} ${int.parse(splits[i].substring(1, splits[i].length - 1))}");
        try {
          workingObject = memory[workingObject]
              [int.parse(splits[i].substring(1, splits[i].length - 1))];
        } catch (e) {
          workingObject = workingObject[
              int.parse(splits[i].substring(1, splits[i].length - 1))];
        }
        //}
      } else {
        // working with id - we should get object itself and then data from object

        // BUT IF the working object is a list of entries (id of entries)...
        // AND we did not use the next variable as a _listDots...
        originSend("225 $workingObject ${splits.length} ${i + 1} ${splits[i]}");
        originSend("${splits[i]}");
        try {
          originSend("${workingObject[splits[i]]}");
        } catch (e) {
          originSend(" workingObject[splits[i]] didnt work");
        }
        if (memory[workingObject] is List && splits[i] != "_listDots") {
          originSend("226");
          originSend(
              "228 $link ${splits.sublist(0, i).join(".") + ".[0]." + splits.sublist(i).join(".")}");
          return getObjectByLinkIntegrated(
              memory,
              simpleObjects,
              consequencesMemory,
              object,
              id,
              splits.sublist(0, i).join(".") +
                  ".[0]." +
                  splits.sublist(i).join("."),
              originSend);
        } else {
          originSend("227");
          switch (splits[i]) {
            case "_listDots":
              originSend("$workingObject");
              if (memory[workingObject][0]["type"] == "line") {
                originSend("${memory[workingObject]}");
                workingObject = getMaxLine(memory[workingObject], originSend);
              }
              break;
            default:
              try {
                workingObject = memory[workingObject][splits[i]];
              } catch (e) {
                originSend("$e");
                originSend(
                    "hdhdhddkkhkdfdhfk $splits ${splits[i]} $workingObject hhhh");
                workingObject = workingObject[splits[i]];
              }
              break;
          }
        }
      }
    }
  }
  originSend("got $workingObject");
  return workingObject;
}

dynamic getMaxLine(List line, originSend) {
  //originSend("working to get the max line of $line");
  var tempList = [];
  for (var o = 0; o < line.length; o++) {
    if (line[o]["dots"].length >= tempList.length) {
      tempList = line[o]["dots"];
    }
  }
  //originSend("the max line of $line is $tempList");
  return tempList.toSet().toList(growable: true);
}

/*dynamic findNonUsedDot(Map memory) {
  var dots = allObjectsOfName(memory, "dot");
  List dotsList = ['A', 'B', 'C',];
  for(var dot in dots) {

  }
}*/

dynamic getObjectByLink(Map memory, Map simpleObjects, Map consequencesMemory,
    String id, int entryOrder, String link, originSend) {
  // -1 of entryOrder means nothing and return error
  originSend("getting object by link $link from $id[$entryOrder]");
  return getObjectByLinkIntegrated(memory, simpleObjects, consequencesMemory,
      memory[id][entryOrder], id, link, originSend);
}

void setObjectByLink(Map memory, Map simpleObjects, Map consequencesMemory,
    String id, int entryOrder, String link, dynamic setTo, originSend) {
  // -1 of entryOrder means working with every entry TODO
  originSend("setting object by link $link from $id[$entryOrder] to $setTo");
  List splits = link.split(".");
  dynamic workingObject;
  for (var i = 0; i < splits.length; i++) {
    if (i == 0) {
      // starting point - cannot rely on workingObject
      if (splits[0].startsWith("\$")) {
        // from our object
        workingObject = memory[id][entryOrder][splits[0].substring(1)];
      } else {
        originSend("789435");
        // from memory
        // for example, angle($dot1+O+dot($dot2.letter)) -> angle(AOB)

        // at first, we should get what is in brackets:
        var figure = splits[0].substring(0, splits[0].indexOf("("));
        var args = splits[0].substring(splits[0].indexOf("(") + 1).substring(
            0, splits[0].substring(splits[0].indexOf("(") + 1).length - 1);

        // then split by plus
        List argsList = args.split("+");

        String doneArg = "";
        // then parse all
        for (String arg in argsList) {
          originSend("789436 $arg $figure $args $link");
          if (arg.startsWith("\$") ||
              (arg.contains("(") && arg.contains(")"))) {
            originSend("789437");
            doneArg = doneArg +
                getObjectByLink(memory, simpleObjects, consequencesMemory, id,
                    entryOrder, arg, originSend);
          } else {
            doneArg = doneArg + arg;
          }
        }
        originSend(
            ("we have great news! $figure($doneArg) ${allObjectsOfName(memory, "dot")}"));
        workingObject = parseObjectByString(memory, simpleObjects,
            consequencesMemory, "$figure($doneArg)", originSend, false);
      }
    } else if (i > 0 && i < splits.length - 1) {
      originSend(" split: i != 0 ($i)");
      if (splits[i].startsWith("[") && splits[i].endsWith("]")) {
        // working with list - we need to get data from list
        originSend(
            " split: [${splits[i].substring(1, splits[i].length - 1)}] from $workingObject");
        try {
          workingObject = memory[workingObject]
              [int.parse(splits[i].substring(1, splits[i].length - 1))];
        } catch (e) {
          workingObject = workingObject[
              int.parse(splits[i].substring(1, splits[i].length - 1))];
        }

        originSend(
            " split: [${splits[i].substring(1, splits[i].length - 1)}] returned $workingObject");
      } else {
        // working with id - we should get object itself and then data from object
        originSend("$workingObject ${memory[workingObject]} ${splits[i]}");
        try {
          workingObject = memory[workingObject][splits[i]];
        } catch (e) {
          workingObject = workingObject[splits[i]];
        }
      }
    } else if (i == splits.length - 1) {
      // setting some object as setTo
      originSend("setTo $workingObject ${memory[workingObject]}");
      memory[workingObject][0][splits[i]] = setTo;
      // TODO: make for all entries (this will be done in simplifyMemory function)
    }
  }
  originSend("link is $workingObject.${splits[splits.length - 1]} = $setTo");
}

void appendObjectByLink(
    Map memory, String id, int entryOrder, String linkToList, dynamic add) {
  // -1 of entryOrder means working with every entry TODO
}

void handleBrightness(Brightness brightness) {
  if (brightness == Brightness.light) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0xFFFFFFFF),
        systemNavigationBarColor: const Color(0x00FFFFFF)));

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: const Color(0x00FFFFFF),
        systemNavigationBarColor: const Color(0x00FFFFFF)));
  }
}

Future<double> getSystemNavBarHeight() async {
  try {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        MethodChannel platform =
            const MethodChannel("com.cutetadpole.geometryapp/android");
        final double result =
            await platform.invokeMethod('getSystemNavBarHeight');
        return result;
      } else {
        return 0.0;
      }
    } else {
      return 0.0;
    }
  } catch (e) {
    return 0.0;
  }
}

String getAnswer(
    Map memory, Map simpleObjects, Map consequencesMemory, originSend) {
  try {
    String answer = "";
    for (var object in memory.entries) {
      if (object.value[0]["toFind"]) {
        if (simpleObjects[object.value[0]["type"]].keys.contains("answerUI")) {
          for (var addition in simpleObjects[object.value[0]["type"]]
              ["answerUI"]) {
            if (addition.startsWith("'") && addition.endsWith("'")) {
              answer = answer + addition.substring(1, addition.length - 1);
            } else {
              originSend("123 + $addition");
              //try {
              answer = answer +
                  getObjectByLink(memory, simpleObjects, consequencesMemory,
                      object.key, 0, addition, originSend);
              //} catch(e, e1) {
              //  _originSend("error here! ${object.key} ${_memory[object.key]} $addition $e $e1 ${_memory[object.key][0]}");
              //}
            }
          }
          answer = answer + ";\n";
        }
      }
    }
    originSend(
        "got answer from getAnswer (raw): $answer and (ended) ${answer.substring(0, answer.length - 2) + "."}");
    return answer.substring(0, answer.length - 2) + ".";
  } catch (e, e1) {
    originSend("got error from getAnswer: $e $e1");
    return "";
  }
}

List<String> logList = [];

void logIsolate(String isolateID, String text) {
  if (kDebugMode)
    log("\x1B[36misolate messaged: \x1B[32m$isolateID \x1B[0m|", text);
}

void logMain(String text) {
  if (kDebugMode) log("\x1B[33mmain messaged:\x1B[0m", text);
}

void logIsolateDebug(String isolateID, String text, bool debug) {
  if (debug) log("\x1B[36misolate messaged: \x1B[32m$isolateID \x1B[0m|", text);
}

void logMainDebug(String text, bool debug) {
  if (debug) log("\x1B[33mmain messaged:\x1B[0m", text);
}

void log(String prefix, String text) {
  logList.add("| ${DateTime.now()} | $prefix $text");
  printWrapped("| ${DateTime.now()} | $prefix $text");
}

List postCheck(Map simpleObjects, List entries) {
  String type = entries[0]["type"];
  Map properties = {};
  for (var property in simpleObjects[type]["properties"].entries) {
    if (property.value.keys.contains("..sameForAllEntries")) {
      if (property.value["..sameForAllEntries"]) {
        properties[property.key] = null;
      }
    }
  }
  bool byParser = false;
  bool byConsequence = false;
  Map consequences = {};
  bool toFind = false;

  for (int i = 0; i < entries.length; i++) {
    for (var property in properties.keys) {
      if (entries[i][property] != null) {
        properties[property] = entries[i][property];
      }
    }
    if (entries[i].keys.contains("byParser")) {
      if (entries[i]["byParser"]) byParser = true;
    }
    if (entries[i].keys.contains("byConsequence")) {
      if (entries[i]["byConsequence"]) byConsequence = true;
    }
    if (entries[i].keys.contains("toFind")) {
      if (entries[i]["toFind"]) toFind = true;
    }
    if (entries[i].keys.contains("..consequences")) {
      if (entries[i]["..consequences"].isNotEmpty) {
        if (!consequences.keys.contains(i)) {
          consequences[i] = [];
        }
        consequences[i].addAll(entries[i]["..consequences"]);
      }
    }
  }

  List entries1 = [];

  for (int i = 0; i < entries.length; i++) {
    entries1.add(entries[i]);
    for (var property in properties.keys) {
      entries1[i][property] = properties[property];
    }
    entries1[i]["byParser"] = byParser;
    entries1[i]["byConsequence"] = byConsequence;
    entries1[i]["toFind"] = toFind;
    if (consequences.keys.contains(i)) {
      entries1[i]["..consequences"] = consequences[i];
    }
  }

  return listOfUniqueJSONs(entries1);
}

List listOfUniqueJSONs(List list) {
  List newStringList = [];
  List newList = [];
  for (var object in list) {
    newStringList.add(jsonEncode(object));
  }
  //logMain("Work of uniqueJSON: list from (${newStringList.length}) $newStringList became (${newStringList.toSet().toList(growable: true).length}) ${newStringList.toSet().toList(growable: true)}");
  newStringList = newStringList.toSet().toList(growable: true);
  for (var object in newStringList) {
    newList.add(jsonDecode(object));
  }
  return newList;
}

String makeSolveText(Map memory, Map simpleObjects, Map consequencesMemory, Function originSend) {
  List toFind = [];
  for (var id in memory.entries) {
    if (id.value[0]["toFind"] == true) toFind.add(id.key);
  }
  originSend("consMemory " + prettyConvert(consequencesMemory) + " $toFind");

  // at first, we should get all dependencies of object from bottom to top
  Map extendedDependencies = {};

  List getExtendedDependencies(String element) {
    var tempList = [];
    for (var dependent in consequencesMemory[element]["dependencies"]) {
      tempList.add(dependent);
      if (consequencesMemory[dependent] != null) {
        tempList.addAll(getExtendedDependencies(dependent));
      }
    }
    return tempList.toSet().toList(growable: true);
  }

  for (var dependent in consequencesMemory.entries) {
    originSend("${dependent.key}: ${getExtendedDependencies(dependent.key)}");
    extendedDependencies[dependent.key] = getExtendedDependencies(dependent.key);
  }

  // then, we should sort our map of dependencies
  // TODO: remove sorting - make removing from all entries except working entry itself
  var sortedKeys = extendedDependencies.keys.toList(growable: false)
    ..sort((k1, k2) => extendedDependencies[k2]
        .length
        .compareTo(extendedDependencies[k1].length));
  LinkedHashMap sortedMap = LinkedHashMap.fromIterable(sortedKeys,
      key: (k) => k, value: (k) => extendedDependencies[k]);
  originSend("sortedMap: $sortedMap");

  // then, we should remove all already-existing dependencies
  Map orderedDependencies = {};
  for(var i = 0; i < sortedMap.length; i++) {
    var strDependencies = jsonEncode(sortedMap[sortedMap.keys.toList(growable: true)[i]]);
    List tempDependencies = jsonDecode(strDependencies);
    for(var j = i + 1; j < sortedMap.length; j++) {
      for(var dependency in sortedMap[sortedMap.keys.toList(growable: true)[j]]) {
        tempDependencies.remove(dependency);
      }
    }
    if(tempDependencies.isEmpty) {
      // somewhere we have object that deleted all entries, so we should recheck all objects again
      for(var j = i + 1; j < sortedMap.length; j++) {
        List tempDependencies = jsonDecode(strDependencies);
        if(tempDependencies.every((element) => sortedMap[sortedMap.keys.toList(growable: true)[j]].contains(element))) {
          // yes, all elements are in this element j.
          tempDependencies = [[sortedMap.keys.toList(growable: true)[j]]];
          break;
        }
      }
    }
    orderedDependencies[sortedMap.keys.toList(growable: true)[i]] = tempDependencies;
  }
  originSend("orderedDependencies: $orderedDependencies");

  // and then we should create tree for toFind object
  if(toFind.length == 1) {
    List goThrough(var element) {
      List tempList = [];
      if(orderedDependencies.containsKey(element)) {
        tempList.add(element);
        for(var dependency in orderedDependencies[element]) {
          tempList.addAll(goThrough(dependency));
        }
      }
      return tempList;
    }

    List orderedSolving = goThrough(toFind[0]);
    originSend("ordered solving: $orderedSolving");

    List orderedText = [];
    for(var solve in orderedSolving) {
      String string = consequencesMemory[solve]["text"];
      orderedText.add(string);
    }
    originSend("ordered text: ${orderedText.join(";\n")}");
    return orderedText.join(";\n");
  } else {
    // TODO
  }

  return "";
}
