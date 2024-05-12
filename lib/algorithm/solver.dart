import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:geometryapp/utils.dart';

void solveConsequences(
    Map memory, Map simpleObjects, Map consequencesMemory, Function originSend) {
  // DO NOT FORGET ABOUNT CONS
  int cons = 1;
  while (cons != 0) {
    cons = 0;
    List remainingConsequences = [];
    List consequences = allConsequences(memory, originSend);
    originSend("consequences are ${prettyConvert(consequences)}");
    for (var consequence in consequences) {
      var dependentsList = [];
      var dependenciesList = [];
      if(consequence["dependents"] != null) {
        for(var dependent in consequence["dependents"]) {
          //tempList.add(dependent);
          dependentsList.add(getObjectByLink(memory, simpleObjects, consequencesMemory, consequence["objectid"], consequence["objectentryorder"], dependent, originSend));
        }
      }
      if(consequence["dependencies"] != null) {
        for(var dependency in consequence["dependencies"]) {
          //tempList.add(dependency);
          dependenciesList.add(getObjectByLink(memory, simpleObjects, consequencesMemory, consequence["objectid"], consequence["objectentryorder"], dependency, originSend));
        }
      }
      switch (consequence["operation"]) {
        case "math":
          // we're solving math!
          if (solveMath(
                  memory,
                  simpleObjects,
                consequencesMemory,
                  consequence["math"],
                  consequence["objectid"],
                  consequence["objectentryorder"],
                  originSend) !=
              double.negativeInfinity) {
            originSend("we solved consequence $consequence");
            for(var dependent in dependentsList) {
              if(!consequencesMemory.keys.contains(dependent)) consequencesMemory[dependent] = {};
              if(consequencesMemory[dependent]["dependencies"] == null) consequencesMemory[dependent]["dependencies"] = [];
              consequencesMemory[dependent]["dependencies"].addAll(dependenciesList);

              String solveText = "";
              for(var addition in consequence["text"]) {
                if(addition.startsWith("'") && addition.endsWith("'")) {
                  solveText = solveText + addition.substring(1, addition.length - 1);
                } else {
                  solveText = solveText +
                      getObjectByLink(memory, simpleObjects, consequencesMemory,
                          consequence["objectid"], consequence["objectentryorder"], addition, originSend);
                }
              }

              consequencesMemory[dependent]["text"] = solveText;
              consequencesMemory[dependent]["id"] = consequence["id"];
              originSend("consequences memory hii! $consequencesMemory");
            }
            cons = cons + 1;
          } else {
            originSend("we did not solve consequence $consequence");
            remainingConsequences.add(consequence);
          }
          break;
        case "_perpendicular":
          cons = cons + 1;
          originSend("making consequences of perpendicular");
          originSend(
              " perpendicular: ${memory[consequence["objectid"]][consequence["objectentryorder"]]}");
          originSend(" intersection: ${memory[memory[consequence["objectid"]][consequence["objectentryorder"]]["intersection"]]}");
          originSend(" line1 ${memory[memory[memory[consequence["objectid"]][consequence["objectentryorder"]]["intersection"]][0]["line1"]]}");
          List line1 = getMaxLine(
              memory[memory[memory[consequence["objectid"]][consequence["objectentryorder"]]["intersection"]][0]["line1"]],
              originSend);
          List line2 = getMaxLine(
              memory[memory[memory[consequence["objectid"]][consequence["objectentryorder"]]["intersection"]][0]["line2"]],
              originSend);
          String dot = memory[memory[consequence["objectid"]]
              [consequence["objectentryorder"]]["intersection"]][0]["dot"];
          var line1splitted = [
            line1.sublist(0, line1.indexOf(dot)),
            line1.sublist(line1.indexOf(dot) + 1)
          ];
          var line2splitted = [
            line2.sublist(0, line2.indexOf(dot)),
            line2.sublist(line2.indexOf(dot) + 1)
          ];

          List newConsequences = [];
          try {
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 6;
            newConsequences[index]["text"] = [
              "'При перпендикулярных прямых углы равны 90°: ${memory[line1splitted[0][0]][0]["letter"]}${memory[line1splitted[1][0]][0]["letter"]} ⟂ ${memory[line2splitted[0][0]][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} => ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 90°'"
            ];
            newConsequences[index]["dependencies"] = ["_id"];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value"] = "90.0";
            originSend("log:set angle to 90 1");
          } catch (e, e1) {
            originSend(" cannot set angle to 90.0: $e $e1");
            newConsequences.removeLast();
          }
          try {
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 6;
            newConsequences[index]["text"] = [
              "'При перпендикулярных прямых углы равны 90°: ${memory[line1splitted[0][0]][0]["letter"]}${memory[line1splitted[1][0]][0]["letter"]} ⟂ ${memory[line2splitted[0][0]][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} => ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 90°'"
            ];
            newConsequences[index]["dependencies"] = ["_id"];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value"] = "90.0";
            originSend("log:set angle to 90 2");
          } catch (e, e1) {
            originSend(" cannot set angle to 90.0: $e $e1");
            newConsequences.removeLast();
          }
          try {
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 6;
            newConsequences[index]["text"] = [
              "'При перпендикулярных прямых углы равны 90°: ${memory[line1splitted[0][0]][0]["letter"]}${memory[line1splitted[1][0]][0]["letter"]} ⟂ ${memory[line2splitted[0][0]][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} => ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 90°'"
            ];
            newConsequences[index]["dependencies"] = ["_id"];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value"] = "90.0";
            originSend("log:set angle to 90 3");
          } catch (e, e1) {
            originSend(" cannot set angle to 90.0: $e $e1");
            newConsequences.removeLast();
          }
          try {
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 6;
            newConsequences[index]["text"] = [
              "'При перпендикулярных прямых углы равны 90°: ${memory[line1splitted[0][0]][0]["letter"]}${memory[line1splitted[1][0]][0]["letter"]} ⟂ ${memory[line2splitted[0][0]][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} => ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 90°'"
            ];
            newConsequences[index]["dependencies"] = ["_id"];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value"] = "90.0";
            originSend("log:set angle to 90 4");
          } catch (e, e1) {
            originSend(" cannot set angle to 90.0: $e $e1");
            newConsequences.removeLast();
          }
          remainingConsequences.addAll(newConsequences);
          originSend("added all consequences of perpendicular ${prettyConvert(remainingConsequences)}");
          break;
        case "addStringObject":
          break;
        case "_intersection":
          cons = cons + 1;
          originSend("making consequences of intersection");
          List line1 = getMaxLine(
              memory[memory[consequence["objectid"]]
                  [consequence["objectentryorder"]]["line1"]],
              originSend);
          List line2 = getMaxLine(
              memory[memory[consequence["objectid"]]
                  [consequence["objectentryorder"]]["line2"]],
              originSend);
          String dot = memory[consequence["objectid"]]
              [consequence["objectentryorder"]]["dot"];
          var line1splitted = [
            line1.sublist(0, line1.indexOf(dot)),
            line1.sublist(line1.indexOf(dot) + 1)
          ];
          var line2splitted = [
            line2.sublist(0, line2.indexOf(dot)),
            line2.sublist(line2.indexOf(dot) + 1)
          ];

          originSend(
              "splitted lines is: line1 $line1splitted, line2 $line2splitted");

          /*
                          line1splitted[0]
                                 |
                                 |
          line2splitted[0]------dot------line2splitted[1]
                                 |
                                 |
                          line1splitted[1]
           */

          //vertical angles are equal (0,1 and 1,0)
          List newConsequences = [];
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 0,1 = 1,0");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 1;
            newConsequences[index]["text"] = [
              "'Вертикальные углы равны: ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
            consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
            "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "sum";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] = "0.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
            "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 1,0 = 0,1");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 1;
            newConsequences[index]["text"] = [
              "'Вертикальные углы равны: ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["text"] = [];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
            consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
            "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "sum";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] = "0.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
            "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // vertical angles are equal (0,0 and 1,1)
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 0,0 = 1,1");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 1;
            newConsequences[index]["text"] = [
              "'Вертикальные углы равны: ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["text"] = [];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
            consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
            "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "sum";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] = "0.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
            "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 1,1 = 0,0");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 1;
            newConsequences[index]["text"] = [
              "'Вертикальные углы равны: ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["text"] = [];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
            consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
            "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "sum";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] = "0.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
            "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // angle 0,1 = 180 - 1,1
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 0,1 = 180 - 1,1");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // angle 1,1 = 180 - 0,1
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 1,1 = 180 - 0,1");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }
          // angle 0,1 = 180 - 0,0
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 0,1 = 180 - 0,0");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // angle 0,0 = 180 - 0,1
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 0,0 = 180 - 0,1");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // angle 1,0 = 180 - 0,0
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 1,0 = 180 - 0,0");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // angle 0,0 = 180 - 1,0
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 0,0 = 180 - 1,0");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[0][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[0][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // angle 1,1 = 180 - 1,0
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 1,1 = 180 - 1,0");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          // angle 1,0 = 180 - 1,1
          try {
            originSend(
                "working with splitted lines: line1 $line1splitted and line2 $line2splitted, where angle 1,0 = 180 - 1,1");
            newConsequences.add({});
            var index = newConsequences.length - 1;
            newConsequences[index]["id"] = 2;
            newConsequences[index]["text"] = [
              "'Сумма смежных углов равна 180°: ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[0][0]][0]["letter"]} = 180° - ∠${memory[line1splitted[1][0]][0]["letter"]}${memory[dot][0]["letter"]}${memory[line2splitted[1][0]][0]["letter"]} = 180° - '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees",
              "'° = '",
              "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees",
              "'°'"
            ];
            newConsequences[index]["dependents"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]})"];
            newConsequences[index]["dependencies"] = ["angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]})"];
            newConsequences[index]["operation"] = "math";
            newConsequences[index]["objectid"] = consequence["objectid"];
            newConsequences[index]["objectentryorder"] =
                consequence["objectentryorder"];
            newConsequences[index]["math"] = {};
            newConsequences[index]["math"]["operation"] = "equals";
            newConsequences[index]["math"]["value1"] = {};
            newConsequences[index]["math"]["value1"]["operation"] = "num";
            originSend("hello world! 1");
            originSend(
                "line1splitted[1] = ${line1splitted[1][0]} ${memory[line1splitted[1][0]][0]}");
            originSend(
                "line2splitted[0] = ${line2splitted[0][0]} ${memory[line2splitted[0][0]][0]}");
            newConsequences[index]["math"]["value1"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[0][0]][0]["letter"]}).degrees";
            newConsequences[index]["math"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["operation"] = "diff";
            newConsequences[index]["math"]["value2"]["value1"] = {};
            newConsequences[index]["math"]["value2"]["value1"]["operation"] =
                "exactNum";
            newConsequences[index]["math"]["value2"]["value1"]["value"] =
                "180.0";
            newConsequences[index]["math"]["value2"]["value2"] = {};
            newConsequences[index]["math"]["value2"]["value2"]["operation"] =
                "num";
            originSend("hello world! 2");
            originSend(
                "line1splitted[1] = ${line1splitted[1][0]} ${memory[line1splitted[1][0]][0]}");
            originSend(
                "line2splitted[1] = ${line2splitted[1][0]} ${memory[line2splitted[1][0]][0]}");
            newConsequences[index]["math"]["value2"]["value2"]["value"] =
                "angle(${memory[line1splitted[1][0]][0]["letter"]}+${memory[dot][0]["letter"]}+${memory[line2splitted[1][0]][0]["letter"]}).degrees";
          } catch (e, e1) {
            originSend(" working did not work :( $e $e1");
            newConsequences.removeLast();
          }

          originSend(
              " new consequences from intersection is $newConsequences");

          // and then all angles are found
          remainingConsequences.addAll(newConsequences);
          break;
        case "_angle30":
          var objectid = consequence["objectid"];
          var objectentryorder = consequence["objectentryorder"];
          var rightTriangleObject = memory[objectid][objectentryorder];
          var angles = jsonDecode(jsonEncode(memory[memory[memory[objectid][objectentryorder]["triangle"]][0]["polygon"]][0]["angles"]));
          angles.remove(rightTriangleObject["rightAngle"]);

          var angle1object = memory[angles[0]][0];
          var angle2object = memory[angles[1]][0];
          var angle30Object = {};
          var legObject = {};
          var hypotenuseObject = memory[rightTriangleObject["hypotenuse"]][0];

          var newConsequences = [];

          if(angle1object["degrees"] != null && double.parse(angle1object["degrees"]) == 30.0) {
            angle30Object = angle1object;

            var dots = jsonDecode(jsonEncode(memory[memory[memory[objectid][objectentryorder]["triangle"]][0]["polygon"]][0]["dots"]));
            dots.remove(memory[angle30Object["ray1"]][0]["startDot"]);
            legObject = memory[parseObjectByString(memory, simpleObjects, consequencesMemory, "segment(${memory[dots[0]][0]["letter"]}${memory[dots[1]][0]["letter"]})", originSend, false)][0];
            originSend("found angle 30!1 ${angles[0]} $dots ${parseObjectByString(memory, simpleObjects, consequencesMemory, "segment(${memory[dots[0]][0]["letter"]}${memory[dots[1]][0]["letter"]})", originSend, false)} $legObject");
            try {
              newConsequences.add({});
              var index = newConsequences.length - 1;
              newConsequences[index]["operation"] = "math";
              newConsequences[index]["id"] = 5;
              newConsequences[index]["dependents"] = ["segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]})"];
              newConsequences[index]["dependencies"] = ["_id", "segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]})", "_${angles[0]}"];
              newConsequences[index]["objectid"] = consequence["objectid"];
              newConsequences[index]["objectentryorder"] = consequence["objectentryorder"];
              newConsequences[index]["math"] = {};
              newConsequences[index]["math"]["operation"] = "equals";
              newConsequences[index]["math"]["value1"] = {};
              newConsequences[index]["math"]["value1"]["operation"] = "num";
              // leg
              newConsequences[index]["math"]["value1"]["value"] = "segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]}).length";
              newConsequences[index]["math"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["operation"] = "times";
              newConsequences[index]["math"]["value2"]["value1"] = {};
              newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
              newConsequences[index]["math"]["value2"]["value1"]["value"] = "0.5";
              newConsequences[index]["math"]["value2"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
              //hypotenuse
              newConsequences[index]["math"]["value2"]["value2"]["value"] = "segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]}).length";
            } catch(e, e1) {
              originSend("log:some error occured while setting consequences to angle 30 (1): $e $e1");
              newConsequences.removeLast();
            }

            try {
              newConsequences.add({});
              var index = newConsequences.length - 1;
              newConsequences[index]["operation"] = "math";
              newConsequences[index]["id"] = 5;
              newConsequences[index]["dependents"] = ["segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]})"];
              newConsequences[index]["dependencies"] = ["_id", "segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]})", "_${angles[0]}"];
              newConsequences[index]["objectid"] = consequence["objectid"];
              newConsequences[index]["objectentryorder"] = consequence["objectentryorder"];
              newConsequences[index]["math"] = {};
              newConsequences[index]["math"]["operation"] = "equals";
              newConsequences[index]["math"]["value1"] = {};
              newConsequences[index]["math"]["value1"]["operation"] = "num";
              //hypotenuse
              newConsequences[index]["math"]["value1"]["value"] = "segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]}).length";

              newConsequences[index]["math"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["operation"] = "times";
              newConsequences[index]["math"]["value2"]["value1"] = {};
              newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
              newConsequences[index]["math"]["value2"]["value1"]["value"] = "2.0";
              newConsequences[index]["math"]["value2"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
              //leg
              newConsequences[index]["math"]["value2"]["value2"]["value"] = "segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]}).length";
            } catch(e, e1) {
              originSend("log:some error occured while setting consequences to angle 30 (2): $e $e1");
              newConsequences.removeLast();
            }

            remainingConsequences.addAll(newConsequences);
            cons = cons + 1;
          } else if(angle2object["degrees"] != null && double.parse(angle2object["degrees"]) == 30.0) {
            angle30Object = angle2object;

            var dots = jsonDecode(jsonEncode(memory[memory[memory[objectid][objectentryorder]["triangle"]][0]["polygon"]][0]["dots"]));
            dots.remove(memory[angle30Object["ray1"]][0]["startDot"]);
            legObject = memory[parseObjectByString(memory, simpleObjects, consequencesMemory, "segment(${memory[dots[0]][0]["letter"]}${memory[dots[1]][0]["letter"]})", originSend, false)][0];
            originSend("found angle 30!1 ${angles[1]} $dots ${parseObjectByString(memory, simpleObjects, consequencesMemory, "segment(${memory[dots[0]][0]["letter"]}${memory[dots[1]][0]["letter"]})", originSend, false)} $legObject");
            try {
              newConsequences.add({});
              var index = newConsequences.length - 1;
              newConsequences[index]["operation"] = "math";
              newConsequences[index]["id"] = 5;
              newConsequences[index]["dependents"] = ["segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]})"];
              newConsequences[index]["dependencies"] = ["_id", "segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]})", "_${angles[1]}"];
              newConsequences[index]["objectid"] = consequence["objectid"];
              newConsequences[index]["objectentryorder"] = consequence["objectentryorder"];
              newConsequences[index]["math"] = {};
              newConsequences[index]["math"]["operation"] = "equals";
              newConsequences[index]["math"]["value1"] = {};
              newConsequences[index]["math"]["value1"]["operation"] = "num";
              // leg
              newConsequences[index]["math"]["value1"]["value"] = "segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]}).length";
              newConsequences[index]["math"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["operation"] = "times";
              newConsequences[index]["math"]["value2"]["value1"] = {};
              newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
              newConsequences[index]["math"]["value2"]["value1"]["value"] = "0.5";
              newConsequences[index]["math"]["value2"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
              //hypotenuse
              newConsequences[index]["math"]["value2"]["value2"]["value"] = "segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]}).length";
            } catch(e, e1) {
              originSend("log:some error occured while setting consequences to angle 30 (3): $e $e1");
              newConsequences.removeLast();
            }

            try {
              newConsequences.add({});
              var index = newConsequences.length - 1;
              newConsequences[index]["operation"] = "math";
              newConsequences[index]["id"] = 5;
              newConsequences[index]["dependents"] = ["segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]})"];
              newConsequences[index]["dependencies"] = ["_id", "segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]})", "_${angles[1]}"];
              newConsequences[index]["objectid"] = consequence["objectid"];
              newConsequences[index]["objectentryorder"] = consequence["objectentryorder"];
              newConsequences[index]["math"] = {};
              newConsequences[index]["math"]["operation"] = "equals";
              newConsequences[index]["math"]["value1"] = {};
              newConsequences[index]["math"]["value1"]["operation"] = "num";
              //hypotenuse
              newConsequences[index]["math"]["value1"]["value"] = "segment(${memory[hypotenuseObject["dot1"]][0]["letter"]}+${memory[hypotenuseObject["dot2"]][0]["letter"]}).length";

              newConsequences[index]["math"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["operation"] = "times";
              newConsequences[index]["math"]["value2"]["value1"] = {};
              newConsequences[index]["math"]["value2"]["value1"]["operation"] = "exactNum";
              newConsequences[index]["math"]["value2"]["value1"]["value"] = "2.0";
              newConsequences[index]["math"]["value2"]["value2"] = {};
              newConsequences[index]["math"]["value2"]["value2"]["operation"] = "num";
              //leg
              newConsequences[index]["math"]["value2"]["value2"]["value"] = "segment(${memory[dots[0]][0]["letter"]}+${memory[dots[1]][0]["letter"]}).length";
            } catch(e, e1) {
              originSend("log:some error occured while setting consequences to angle 30 (4): $e $e1");
              newConsequences.removeLast();
            }

            remainingConsequences.addAll(newConsequences);
            cons = cons + 1;
          } else {
            remainingConsequences.add(consequence);
          }
      }
    }

    // after passing all consequences, let's restore remaining consequences
    for (var object in memory.entries) {
      var objectValue = object.value;
      for (var entry in objectValue) {
        entry["..consequences"] = [];
        memory[object.key] = objectValue;
      }
    }
    originSend("remainingConsequences: ${prettyConvert(remainingConsequences)}");
    for (var consequence in remainingConsequences) {
      originSend("gpofg $consequence ${consequence["objectid"]} ${memory[consequence["objectid"]]}");
      if (memory[consequence["objectid"]][consequence["objectentryorder"]]
              ["..consequences"] ==
          null) {
        memory[consequence["objectid"]][consequence["objectentryorder"]]
            ["..consequences"] = [consequence];
      } else {
        List tempCons = memory[consequence["objectid"]]
            [consequence["objectentryorder"]]["..consequences"];
        tempCons.add(consequence);
        originSend(
            "adding consequence $consequence to ${consequence["objectid"]} [${consequence["objectentryorder"]} ${memory[consequence["objectid"]][consequence["objectentryorder"]]["..consequences"].length}]");
        memory[consequence["objectid"]][consequence["objectentryorder"]]
            ["..consequences"] = tempCons;
        originSend(
            "added! ${memory[consequence["objectid"]][consequence["objectentryorder"]]["..consequences"].length}");
      }
    }
  }
  // we solved as much as we could but also we maybe solved our problem
}

double solveMath(Map memory, Map simpleObjects, Map consequencesMemory, Map consequence, String id,
    int entryOrder, Function originSend) {
  if (consequence["operation"] == "equals") {
    // equals = value1 is equal to value2
    var value1 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value1"], id,
        entryOrder, originSend);
    var value2 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value2"], id,
        entryOrder, originSend);
    if (value1 == double.negativeInfinity &&
        value2 != double.negativeInfinity) {
      if (consequence["value1"]["operation"] == "num") {
        setObjectByLink(memory, simpleObjects, consequencesMemory, id, entryOrder,
            consequence["value1"]["value"], "$value2", originSend);
        /*String linkObject = consequence["value1"]["value"].split(".")[0].substring(1);
        String linkObjectID = memory[id][entryOrder][linkObject];
        for(var j = 0; j < memory[linkObjectID].length; j++) {
          memory[linkObjectID][j][consequence["value1"]["value"].split(".")[1]] = "$value2";
        }*/
      } else {
        return double.negativeInfinity;
      }
      /*
      String linkObject = consequence["value"].split(".")[0].substring(1);
      String linkObjectID = memory[consequence["objectid"]][consequence["objectentryorder"]][linkObject];
      if(memory[linkObjectID][0].keys.contains(consequence["value"].split(".")[1])) {

        if(memory[linkObjectID][0][consequence["value"].split(".")[1]] != null) {
          return memory[linkObjectID][0][consequence["value"].split(".")[1]];
        } else {
          return double.negativeInfinity;
        }
      } else {
        return double.negativeInfinity;
      }
       */
      return value2;
    } else if (value2 == double.negativeInfinity &&
        value1 != double.negativeInfinity) {
      if (consequence["value2"]["operation"] == "num") {
        setObjectByLink(memory, simpleObjects, consequencesMemory, id, entryOrder,
            consequence["value2"]["value"], "$value1", originSend);
        /*String linkObject = consequence["value2"]["value"].split(".")[0].substring(1);
        String linkObjectID = memory[id][entryOrder][linkObject];
        for(var j = 0; j < memory[linkObjectID].length; j++) {
          memory[linkObjectID][j][consequence["value2"]["value"].split(".")[1]] = "$value1";
        }*/
      } else if (value1 != double.negativeInfinity &&
          value2 != double.negativeInfinity) {
      } else {
        return double.negativeInfinity;
      }
      return value1;
    } else {
      return double.negativeInfinity;
    }
  } else if (consequence["operation"] == "sum") {
    // sum = sum of value1 and value2
    var value1 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value1"], id,
        entryOrder, originSend);
    var value2 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value2"], id,
        entryOrder, originSend);
    if (value1 != double.negativeInfinity &&
        value2 != double.negativeInfinity) {
      return value1 + value2;
    } else {
      return double.negativeInfinity;
    }
  } else if (consequence["operation"] == "times") {
    // sum = sum of value1 and value2
    var value1 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value1"], id,
        entryOrder, originSend);
    var value2 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value2"], id,
        entryOrder, originSend);
    if (value1 != double.negativeInfinity &&
        value2 != double.negativeInfinity) {
      return value1 * value2;
    } else {
      return double.negativeInfinity;
    }
  } else if (consequence["operation"] == "diff") {
    // diff = difference of value1 and value2
    var value1 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value1"], id,
        entryOrder, originSend);
    var value2 = solveMath(memory, simpleObjects, consequencesMemory, consequence["value2"], id,
        entryOrder, originSend);
    if (value1 != double.negativeInfinity &&
        value2 != double.negativeInfinity) {
      return value1 - value2;
    } else {
      return double.negativeInfinity;
    }
  } else if (consequence["operation"] == "num") {
    // num = some variable
    var someNum = getObjectByLink(memory, simpleObjects, consequencesMemory, id, entryOrder,
        consequence["value"], originSend);
    if (someNum == null) {
      return double.negativeInfinity;
    } else {
      return double.parse(someNum);
    }
  } else if (consequence["operation"] == "exactNum") {
    // exactNum = some number that is presented by numbers, not variable
    return double.parse(consequence["value"]);
  } else if (consequence["operation"] == "squareRoot") {
    var value = solveMath(memory, simpleObjects, consequencesMemory, consequence["value"], id,
        entryOrder, originSend);
    if (value == double.negativeInfinity) {
      return double.negativeInfinity;
    } else {
      return sqrt(value);
    }
  } else if (consequence["operation"] == "cosine") {
    var value = solveMath(memory, simpleObjects, consequencesMemory, consequence["value"], id,
        entryOrder, originSend);
    if (value == double.negativeInfinity) {
      return double.negativeInfinity;
    } else {
      return cos(value * (pi / 180));
    }
  } else if (consequence["operation"] == "squared") {
    var value = solveMath(memory, simpleObjects, consequencesMemory, consequence["value"], id,
        entryOrder, originSend);
    if (value == double.negativeInfinity) {
      return double.negativeInfinity;
    } else {
      return value * value;
    }
  } else {
    return double.negativeInfinity;
  }
}
