import 'dart:isolate';

import 'package:geometryapp/algorithm/checker.dart';
import 'package:geometryapp/utils.dart' as utils;

String parseObject(Map memory, Map simpleObjects, Map consequencesMemory, String objectName,
    String objectValue, Function originSend, bool byParser) {
  //print("Parsing object $objectName $objectValue");

  bool toFind = objectName.endsWith(".toFind");
  if (toFind) objectName = objectName.replaceFirst(".toFind", "");
  Map object = {"type": objectName, "toFind": toFind, "byParser": byParser};

  if (simpleObjects[objectName].containsKey("properties")) {
    // create object properties if they exist
    Map properties = simpleObjects[objectName]["properties"];
    for (var key in properties.keys) {
      if (properties[key]["..obj"] == "list") {
        object[key] = [];
      } else {
        object[key] = null;
      }
    }
  }

  //print("Object: $object");

  // get parse operations
  List parseOperations = [];
  for (var i = 0; i < simpleObjects[objectName]["parse"].length; i++) {
    parseOperations.add(utils.jsonReplaceAll(
        simpleObjects[objectName]["parse"][i], objectValue));
  }
  //print(parseOperations);

  // operate
  for (var operation in parseOperations) {
    //print("Right now operation is ${operation["operation"]}");
    if (operation["operation"] == "set") {
      //print("got set.");
      // REMEMBER!!! Operations "set", "append" uses same parsing scheme.
      if (operation.containsKey("value")) {
        if (operation["value"] != "") {
          if (operation["key"].startsWith("\$")) {
            // changing object itself
            if (operation["value"].startsWith("\$")) {
              object[operation["key"].substring(1)] =
                  object[operation["value"].substring(1)];
            } else {
              //print("SET! ${operation["key"].substring(1)} ${await algorithm.parseObjectByString(memory, simpleObjects, operation["value"])}");
              object[operation["key"].substring(1)] = utils.parseObjectByString(
                  memory, simpleObjects, consequencesMemory, operation["value"], originSend, true);
            }
          } else {
            // TODO utils.setObjectByLinkIntegrated(memory, simpleObjects, object, operation["key"], operation["value"], originSend);
          }
        }
      }
    } else if (operation["operation"] == "append") {
      // TODO: remake append function.
      var listLink = operation["list"];
      var valueLink = operation["value"];
      if (listLink.startsWith("\$")) {
        // changing object itself
        String existingObject;
        if (valueLink.startsWith("\$")) {
          existingObject = "";
        } else {
          existingObject = utils.parseObjectByString(
              memory, simpleObjects, consequencesMemory, valueLink, originSend, true);
        }
        object[listLink.substring(1)].add(existingObject);
      } else {
        String idOfObjectWhereListIs = utils.parseObjectByString(
            memory, simpleObjects, consequencesMemory, listLink.split(".")[0], originSend, true);
        String idOfAppendingObject = utils.parseObjectByString(
            memory, simpleObjects, consequencesMemory, valueLink, originSend, true);
        //print(idOfObjectWhereListIs);
        List allEntriesOfObjectWhereListIs = memory[idOfObjectWhereListIs];
        String listName = listLink.split(".")[1];

        for (var j = 0; j < allEntriesOfObjectWhereListIs.length; j++) {
          //print(allEntriesOfObjectWhereListIs[0]);
          if (!allEntriesOfObjectWhereListIs[j].containsKey(listName)) {
            allEntriesOfObjectWhereListIs[j][listName] = [];
          }

          if (operation.containsKey("between")) {
            if (allEntriesOfObjectWhereListIs[j][listName]
                .contains(idOfAppendingObject)) {
              // если точка уже есть на линии - прерываем

            } else {
              var element1 = utils.parseObjectByString(memory, simpleObjects, consequencesMemory,
                  operation["between"].split(";")[0], originSend, true);
              var element2 = utils.parseObjectByString(memory, simpleObjects, consequencesMemory,
                  operation["between"].split(";")[1], originSend, true);

              var index1 =
                  allEntriesOfObjectWhereListIs[j][listName].indexOf(element1);
              var index2 =
                  allEntriesOfObjectWhereListIs[j][listName].indexOf(element2);
              //print("indexes: $index1 $index2 in $object");
              if (index1 < index2) {
                allEntriesOfObjectWhereListIs[j][listName]
                    .insert(index1 + 1, idOfAppendingObject);
              } else {
                allEntriesOfObjectWhereListIs[j][listName]
                    .insert(index2 + 1, idOfAppendingObject);
              }
            }
          } else {
            if (allEntriesOfObjectWhereListIs[j][listName]
                .contains(idOfAppendingObject)) {
              // точка уже есть на линии - прерываем
            } else {
              allEntriesOfObjectWhereListIs[j][listName]
                  .add(idOfAppendingObject);
            }
          }
        }
      }
    } else if (operation["operation"] == "_polygon") {
      object["dots"] = [];
      object["segments"] = [];
      object["angles"] = [];
      for (int i = 0; i < objectValue.length; i++) {
        var dot1 = utils.parseObjectByString(memory, simpleObjects, consequencesMemory,
            "dot(" + objectValue[i] + ")", originSend, byParser);
        var segment1 = utils.parseObjectByString(
            memory,
            simpleObjects,
            consequencesMemory,
            "segment(" +
                objectValue[i] +
                objectValue[(i + 1) % (objectValue.length)] +
                ")",
            originSend,
            byParser);
        var angle1 = utils.parseObjectByString(
            memory,
            simpleObjects,
            consequencesMemory,
            "angle(" +
                objectValue[i] +
                objectValue[(i + 1) % (objectValue.length)] +
                objectValue[(i + 2) % (objectValue.length)] +
                ")",
            originSend,
            byParser);
        object["dots"].add(dot1);
        object["angles"].add(angle1);
        object["segments"].add(segment1);
      }
    } else if (operation["_operation"] == "_rightTriangle") {
      // TODO
    }
  }

  if (simpleObjects[objectName].containsKey("properties")) {
    var id = checkAndInsertObject(memory, simpleObjects, consequencesMemory, object, originSend, true);
    id = id.replaceAll("_solved", "");
    //print("New object $id: $object");
    return id;
  }

  return "";
}
