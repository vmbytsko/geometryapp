import 'dart:isolate';

import 'package:geometryapp/algorithm/checker.dart';
import 'package:geometryapp/utils.dart' as utils;

void findNewObjects(Map memory, Map simpleObjects, Map consequencesMemory, Function originSend) {

  // At first, we should say that all dots except included ones are excluded
  List allDots = [];
  Map allDotsMap = utils.allObjectsOfName(memory, "dot");
  for(var dot in allDotsMap.entries) {
    allDots.add(dot.key);
  }

  Map allLinesMap = utils.allObjectsOfName(memory, "line");
  for(var line in allLinesMap.entries) {
    List maxLine = utils.getMaxLine(line.value, originSend);
    List excludedDots = [];
    for(var dot in allDots) {
      if(!maxLine.contains(dot)) {
        excludedDots.add(dot);
      }
    }
    for(var i = 0; i < memory[line.key].length; i++) {
      memory[line.key][i]["excludedDots"] = excludedDots;
    }
  }

  for (var objectName in simpleObjects.keys) {
    if (!objectName.startsWith("..")) {
      if (simpleObjects[objectName].containsKey("properties")) {
        originSend("parsing all ${objectName}s");
        List dependentObjects = [];
        for (var property in simpleObjects[objectName]["properties"].entries) {
          if (property.value["..required"] == false) {
            // ignore this dependency
          } else if (property.value["..obj"] == "char" ||
              property.value["..obj"] == "string" ||
              property.value["..obj"] == "int" ||
              property.value["..obj"] == "float") {
            // ignore this dependency as it is non-geometrical object.
            // interrupt this.
            dependentObjects = ["..deny"];
          } else {
            dependentObjects.add(property.key);
          }
        }

        if(dependentObjects.contains("..deny") || dependentObjects.isEmpty) {
          originSend("Cannot find dependencies for $objectName");
        } else {
          originSend("Dependencies are $dependentObjects");

          List arraysOfDependencies = [];

          for (var dependency in dependentObjects) {
            var dependencyName =
                simpleObjects[objectName]["properties"][dependency]["..obj"];
            originSend(
                "now working with dependency $dependency - $dependencyName");
            if (dependencyName == "list") {
              var permutations = utils.permutations(utils.allIDsOfName(memory,
                  simpleObjects[objectName]["properties"][dependency]["type"]));
              originSend("work of permutations: $permutations");
              arraysOfDependencies.add(permutations);
            } else {
              var allObjects = utils.allIDsOfName(memory, dependencyName);
              arraysOfDependencies.add(allObjects);
            }
          }

          var allPossibleVariantsOfFindingObject =
              utils.expandArrayOfEntries(arraysOfDependencies);

          originSend("creating objects");

          bool toFind = objectName.endsWith(".toFind");
          if (toFind) objectName = objectName.replaceFirst(".toFind", "");
          Map objectPattern = {"type": objectName, "toFind": toFind};

          Map properties = simpleObjects[objectName]["properties"];
          for (var key in properties.keys) {
            if (properties[key]["..obj"] == "list") {
              objectPattern[key] = [];
            } else {
              objectPattern[key] = null;
            }
          }

          for(var j = 0; j < allPossibleVariantsOfFindingObject.length; j++) {
            Map object = {};
            object.addAll(objectPattern);
            for (var k = 0; k < dependentObjects.length; k++) {
              object[dependentObjects[k]] =
                  allPossibleVariantsOfFindingObject[j][k];
            }
            originSend("So final object is: $object");
            String id = checkAndInsertObject(memory, simpleObjects, consequencesMemory, object, originSend, false);
            if(id.endsWith("_solved")) {
                originSend("We found the answer in finder.dart");
                return;
            }
          }

          /*
          for(var j = 0; j < allPossibleVariantsOfFindingObject.length; j++) {
                        // we must create clone of pattern, not to use it
                        object = Object.assign({}, objectpattern, {})
                        object["type"] = objectname;
                        for(var k = 0; k < dependentobjects.length; k++) {
                            object[dependentobjects[k]] = allPossibleVariantsOfFindingObject[j][k];
                        }
                        console.log(object);

                        var id = algorithm.IDforObject();
                        while(memory[id] != undefined) {
                            id = algorithm.IDforObject();
                        }


                        memory[id] = [object];

                    }
           */

        }
        originSend("so the memory is: ${utils.prettyConvert(memory)}");
      }
    }
  }
  //Isolate.exit(p, memory);
}