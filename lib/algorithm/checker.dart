import 'dart:convert';

import 'package:geometryapp/algorithm/parser.dart';
import 'package:geometryapp/algorithm/solver.dart';
import 'package:geometryapp/utils.dart' as utils;

String checkAndInsertObject(Map memory, Map simpleObjects, Map consequencesMemory, Map object,
    Function originSend, bool byParser) {
  var id = utils.IDforObject();
  while (memory.containsKey(id)) {
    id = utils.IDforObject();
  }

  originSend("Check and insert $id: $object");
  originSend("${simpleObjects[object["type"]]["properties"]}");
  for (var property in simpleObjects[object["type"]]["properties"].entries) {
    if (property.value.keys.contains("..required")) {
      if (property.value["..required"] == true) {
        assert(object[property.key] != null);
      }
    }
  }

  String objectName = object["type"];
  if (simpleObjects.containsKey(objectName)) {
    List checks = simpleObjects[objectName]["checks"];
    originSend("checks: $checks");
    bool toMerge = false;
    String mergeID = "";
    bool toDelete = false;
    String deletingReason = "";
    for (Map check in checks) {
      originSend("working with check $check");
      if (check["operation"] == "full") {
        var sameObject = utils.fullIncludeCheckID(
            utils.allObjectsOfName(memory, objectName), object);
        if (sameObject != "" && sameObject != id) {
          /*print(
              "We find same object. Adding this object to already existing ID.");*/
          mergeID = sameObject;
          toMerge = true;
        }
      } else if (check["operation"] == "_line") {
        originSend(
            "attention please! ${object["dots"].length} ${object["dots"].toSet().length} ${object["dots"]}");
        if (object["dots"].length != object["dots"].toSet().length) {
          toDelete = true;
          deletingReason = "repeated elements in line";
          break;
        }
        object["dots"] = object["dots"].toSet().toList(growable: true);
        Map allLines = utils.allObjectsOfName(memory, "line");
        var allLinesKeys = allLines.keys.toList();
        for (var k = 0; k < allLinesKeys.length; k++) {
          var lineID = allLinesKeys[k];
          for (var o = 0; o < allLines[lineID].length; o++) {
            var oneEntryOfLineID = allLines[lineID][o];
            List lists = [object["dots"], oneEntryOfLineID["dots"]];
            final intersection = lists.fold<Set>(
                lists.first.toSet(), (a, b) => a.intersection(b.toSet()));
            if (intersection.length >= 2 && id != lineID) {
              // the lane is same, actually
              // merge all excluded dots so they'll become equal.
              object["excludedDots"] = oneEntryOfLineID["excludedDots"];

              List excludedLists = [object["excludedDots"], object["dots"]];
              final excludedIntersection = excludedLists.fold<Set>(
                  excludedLists.first.toSet(),
                  (a, b) => a.intersection(b.toSet()));

              // if line include dots that are excluded - throw error.
              if (excludedIntersection.isNotEmpty) {
                toDelete = true;
                deletingReason =
                    "given line contains dots that are in 'dots' and 'excludedDots' lists at the same time";
              }
              // merge letter of line
              object["letter"] = oneEntryOfLineID["letter"];
              // but what if the order of dots is wrong? let's check that.
              List maxListOfDots = [];
              for (var i = 0; i < memory[lineID].length; i++) {
                if (memory[lineID][i]["dots"].length > maxListOfDots.length) {
                  maxListOfDots = [];
                  maxListOfDots.addAll(memory[lineID][i]["dots"]);
                }
              }
              originSend("$maxListOfDots");
              // found max list. now we're going to check indexes of dots of our object
              // in maxListOfDots. if they are sorted from min to max or vise versa -
              // line is correct.
              int max = -1;
              int direction =
                  0; // 0 - not specified, 1 - left to right; -1 - right to left.
              for (var i = 0; i < object["dots"].length; i++) {
                //originSend("before: $max $direction");
                int index = maxListOfDots.indexOf(object["dots"][i]);
                if ((index > max && (direction == 0 || direction == 1)) ||
                    (index < max && (direction == 0 || direction == -1))) {
                  // either index lower than prev and we're going left
                  // or index higher than prev and we're going right.
                  // no? error? then line is wrong.
                  if (max != -1) {
                    direction = index > max ? 1 : -1;
                  }
                  max = index;
                  //originSend("after: $max $direction");
                } else {
                  //originSend("after: $max $direction");
                  // whoops! exception! our line is broken. delete this.
                  toDelete = true;
                  deletingReason =
                      "dots in line are in impossible order in context of given problem";
                  break;
                }
              }
              mergeID = lineID;
              toMerge = true;

              o = allLines[lineID].length;
              k = allLinesKeys.length;
            }
          }
        }
      } else if (check["operation"] == "equal") {
        // this operation checks if some values are equal.
        // if not - we should delete our object.
        List equalValues = [];
        for (var value in check["values"]) {
          originSend(" equal: object is $object, value is $value");
          String valueID = utils.getObjectByLinkIntegrated(
              memory, simpleObjects, consequencesMemory, object, id, value, originSend);
          equalValues.add(valueID);
        }
        if (equalValues.toSet().length == 1) {
          // yeah, they are equal.
        } else {
          // delete
          toDelete = true;
          deletingReason =
              "object has property 'equal' but this operation exited with exception";
        }
      } else if (check["operation"] == "notEqual") {
        // this operation checks if some values are not equal.
        // if they are equal - we should delete our object.
        List notEqualValues = [];
        for (var value in check["values"]) {
          originSend(" notEqual: object is $object, value is $value");
          String valueID = utils.getObjectByLinkIntegrated(
              memory, simpleObjects, consequencesMemory, object, id, value, originSend);
          notEqualValues.add(valueID);
        }
        if (notEqualValues.toSet().length == notEqualValues.length) {
          // yeah, they are not equal.
        } else {
          // delete
          toDelete = true;
          deletingReason =
              "object has property 'notEqual' but this operation exited with exception";
        }
      } else if (check["operation"] == "listProperties") {
        var listLink = check["list"];
        // TODO: make use of getObjectByLink and setObjectByLink

        List lists = [];

        if (listLink.startsWith("\$")) {
          lists = [
            utils.getObjectByLinkIntegrated(
                memory, simpleObjects, consequencesMemory, object, id, listLink, originSend)
          ];
        } else {
          // TODO and CHECK
        }

        originSend("lists in listProperties: $lists");

        bool shouldDelete = true;
        for (List list in lists) {
          if (check.containsKey("moreThan")) {
            if (list.length <= check["moreThan"]) {
              //toDelete = true;
              deletingReason =
                  "given list (${listLink.substring(1)}) did not pass 'moreThan' check";
              break;
            } else {
              shouldDelete = false;
            }
          }
          if (check.containsKey("length")) {
            if (list.length != check["length"]) {
              //toDelete = true;
              deletingReason =
                  "given list (${listLink.substring(1)}) did not pass 'length' check";
              break;
            } else {
              shouldDelete = false;
            }
          }
          if (check.containsKey("contains")) {
            List listOfObjects = check["contains"];
            originSend(
                "working with check 'contains' with $list where need to be all of $listOfObjects.");
            // TODO: make getting list not by hard-writing list but by string link (getObjectByLink)
            int allMatches = 0;
            for (String containsObject in listOfObjects) {
              if (containsObject.startsWith("\$")) {
                if (!list.contains(object[containsObject.substring(1)])) {
                  //print(
                  //    "not contains!!! $list ${object[containsObject.substring(1)]}");
                  //toDelete = true;
                  deletingReason =
                      "given list (${listLink.substring(1)}) has not neccessary object (${containsObject.substring(1)})";
                } else {
                  //print(
                  //    "contains!!! $list ${object[containsObject.substring(1)]}");
                  allMatches = allMatches + 1;
                }
              } else {
                // TODO
              }
            }
            if (listOfObjects.length == allMatches) {
              originSend(
                  " 'contains' with $list and $listOfObjects sent good!");
              shouldDelete = false;
            } else {
              originSend(
                  " 'contains' with $list and $listOfObjects sent error.");
            }
          }
          if (check.containsKey("containsOne")) {
            List anotherListOfObjects = [];
            originSend(
                "working with check 'containsOne' with $list where need to be atleast one of $anotherListOfObjects.");
            if (check["containsOne"] is String) {
              anotherListOfObjects = utils.getObjectByLinkIntegrated(memory,
                  simpleObjects, consequencesMemory, object, id, check["containsOne"], originSend);
              originSend(
                  "we parsed 'containsOne' from ${check["containsOne"]} to $anotherListOfObjects.");
            } else if (check["containsOne"] is List) {
              anotherListOfObjects = check["containsOne"];
              for (var j = 0; j < anotherListOfObjects.length; j++) {
                if (anotherListOfObjects[j].startsWith("\$")) {
                  anotherListOfObjects[j] =
                      object[anotherListOfObjects[j].substring(1)];
                } else {
                  // TODO: add support for getObjectByLink
                }
              }
            }
            var tempInt = 0;
            for (var objectInAnotherList in anotherListOfObjects) {
              if (list.contains(objectInAnotherList)) {
                tempInt++;
              }
            }
            if (tempInt == 1) {
              originSend(
                  " 'containsOne' with $list and $anotherListOfObjects sent good!");
              shouldDelete = false;
            } else {
              originSend(
                  " 'containsOne' with $list and $anotherListOfObjects sent error.");
            }
          }
        }
        if (shouldDelete) {
          toDelete = true;
          deletingReason =
              "did not find any entry of given id where list is that passes this check | " +
                  deletingReason;
        }
      } else if (check["operation"] == "_ray") {
        // firstly, check if this ray is valid - startDot and continueDot are not the same.
        if (object["startDot"] == object["continueDot"]) {
          toDelete = true;
          deletingReason = "startDot cannot be continueDot at the same time";
          break;
        }
        // now we should find entry of baseline that contains all our dots.
        bool shouldDelete = true;
        for (var k = 0; k < memory[object["baseline"]].length; k++) {
          var oneOfBaselines = memory[object["baseline"]][k];
          var listOfDots = oneOfBaselines["dots"];
          if (listOfDots.contains(object["startDot"]) &&
              listOfDots.contains(object["continueDot"])) {
            shouldDelete = false;
            // found entry.
            // now we have to find direction of ray - from left to right or from right to left.
            var direction = "";
            // finding which dot is first
            var startIndex = oneOfBaselines["dots"].indexOf(object["startDot"]);
            var continueIndex =
                oneOfBaselines["dots"].indexOf(object["continueDot"]);
            if (startIndex < continueIndex) {
              // from left to right.
              direction = "ltr";
            } else {
              // from right to left.
              direction = "rtl";
            }
            originSend("direction: $direction");
            // found direction. now start merging - or adding as independent object.
            var allRays = utils.allObjectsOfName(memory, "ray");
            for (var ray in allRays.entries) {
              for (var rayVariable in ray.value) {
                if (rayVariable["startDot"] == object["startDot"] &&
                    rayVariable["baseline"] == object["baseline"]) {
                  // found ray that can be same. we should check if
                  // direction is same as our object.

                  var sameObjectStartIndex =
                      oneOfBaselines["dots"].indexOf(rayVariable["startDot"]);
                  var sameObjectContinueIndex = oneOfBaselines["dots"]
                      .indexOf(rayVariable["continueDot"]);
                  /*print(
                      "sameObjectIndexes: $sameObjectStartIndex $sameObjectContinueIndex");*/
                  if (sameObjectStartIndex < sameObjectContinueIndex) {
                    if (direction == "ltr") {
                      // rayVariable has same direction as our object.
                      toMerge = true;
                      mergeID = ray.key;
                    }
                  } else {
                    if (direction == "rtl") {
                      // rayVariable has same direction as our object.
                      toMerge = true;
                      mergeID = ray.key;
                    }
                  }
                  /*if(direction == "ltr") {
                    // get sublist of righter dots and check if this sublist contains continueDot. if contains - we should merge.
                    if(baselineDots.sublist(startindex+1).contains(object["continueDot"])) {
                      originSend("baselineDots: ${baselineDots.sublist(startindex+1)}");
                      toMerge = true;
                      mergeID = ray.key;
                    }
                  } else {
                    // sublist of lefter dots.
                    if(baselineDots.sublist(0,startindex).contains(object["continueDot"])) {
                      originSend("baselineDots: ${baselineDots.sublist(0,startindex)}");
                      toMerge = true;
                      mergeID = ray.key;
                    }
                  }*/
                }
              }
            }
            break;
          }
          if (shouldDelete) {
            // we did not found any entry that contains allour dots.
            // removing this object.
            toDelete = true;
            deletingReason = "startDot or continueDot are not in baseline";
          }
        }
      } else if (check["operation"] == "changePlaces") {
        // changePlaces means that values in this operation can change places with themselves,
        // and if there's object presented with changed order of objects - we should merge
        // our object into existing object.
        List changeKeys = [];
        List changeValues = [];
        for (var value in check["values"]) {
          if (value.startsWith("\$")) {
            // checking object itself
            changeKeys.add(value.substring(1));
            changeValues.add(object[value.substring(1)]);
          }
        }
        List partialPermutationsOfValues =
            utils.partialPermutations(changeValues, changeValues.length);
        /*print(
            "changePlaces - keys are $changeKeys and values are $changeValues");*/
        Map allSameObjects = utils.allObjectsOfName(memory, objectName);
        bool found = false;
        for (var sameObject in allSameObjects.entries) {
          for (var sameObjectEntry in sameObject.value) {
            for (var j = 0; j < partialPermutationsOfValues.length; j++) {
              bool shouldBreak = false;
              for (var i = 0; i < changeKeys.length; i++) {
                if (sameObjectEntry[changeKeys[i]] !=
                    partialPermutationsOfValues[j][i]) {
                  // no, with given value of specific entry there's mismatch -
                  // given entry is not same, so we can't use this entry
                  // as same object for our object.
                  shouldBreak = true;
                  i = changeKeys.length;
                }
              }
              if (!shouldBreak) {
                // but if all values of this permutation matches with values of given entry -
                // wow, we find same object! we should merge it.
                toMerge = true;
                mergeID = sameObject.key;
                found = true;
                break;
              }
              // else - we continue our researching.
            }
            if (found) break;
          }
          if (found) break;
        }
      } else if (check["operation"] == "_polygon") {
        // check if dots are more than 2
        if (object["dots"].length <= 2) {
          toDelete = true;
          deletingReason = "polygon has lower than 3 dots";
          break;
        }
        // polygon is valid only when it doesn't cross itself.
        // how can we check it? interesting question.
        // for example, let's check some quadrilateral ABCD with diagonals AC and BD crossed in dot E.
        // if we go from dot A to dot B and write all in-way dots to special list,
        // we'll get list [A, B]. Now from B to C: [A, B, C]. So, there we get [A, B, C, D, A].
        // this list can also be [A, Q, F, B, J, C, D, A].
        // now we'll check quadrilateral ABDC. As we know, diagonals are crossed with E,
        // so our list will be [A, B, E, D, C, E, A].
        // and we know that this quadrilateral is invalid. Why?
        // And here's the answer - we got E two times. So, when polygon crosses itself,
        // polygon crosses itself in some dot (E, for example), and we can monitor that
        // and say that ABDC is INVALID quadrilateral.
        // this will work with either convex or concave polygon. Nice!

        // we should also check if previous line is not the line of next pair of dots,
        // so we will not create object that has three dots and three sides, for example
        List listOfLines = [];
        List listOfDots = [];
        // going through every pair of dots.
        for (var i = 0; i < object["dots"].length; i++) {
          String dot1 = object["dots"][i];
          String dot2 =
              object["dots"][(i + 1) == object["dots"].length ? 0 : i + 1];

          var maxLine = [];
          for (var line in utils.allObjectsOfName(memory, "line").entries) {
            var tempLine = utils.getMaxLine(line.value, originSend);
            if (tempLine.contains(dot1) && tempLine.contains(dot2)) {
              maxLine = tempLine;
              listOfLines.add(tempLine);
              break;
            }
          }
          int index1 = maxLine.indexOf(dot1);
          int index2 = maxLine.indexOf(dot2);
          if (index1 > index2) {
            // right to left
            listOfDots.addAll(maxLine.sublist(index2, index1).reversed);
            originSend(
                "ALL OF A SUDDEN index2 -> index1 $listOfDots $index2 ($dot2) $index1 ($dot1) $maxLine ${maxLine.sublist(index2, index1).reversed}");
          } else {
            // left to right
            listOfDots.addAll(maxLine.sublist(index1 + 1, index2 + 1));
            originSend(
                "ALL OF A SUDDEN index1 -> index2 $listOfDots $index1 ($dot1) $index2 ($dot2) $maxLine ${maxLine.sublist(index1 + 1, index2 + 1)}");
          }
        }

        //utils.printWrapped(
        //    "ListOfDots: $listOfDots, ${listOfDots.toSet()} ${listOfDots.length} ${listOfDots.toSet().length}");
        originSend(
            "polygon dots: $id ${object["dots"]} $listOfDots ${listOfDots.sublist(0, listOfDots.length - 1)} ${listOfDots.toSet()}");
        if (listOfDots.length != listOfDots.toSet().length) {
          // got crossings. bad! delete.
          toDelete = true;
          deletingReason = "polygon has crossed itself";
          break;
        }

        originSend(
            "polygon lines: $id ${object["dots"].length} $listOfLines ${listOfLines.toSet()}");
        if (object["dots"].length != listOfLines.toSet().length) {
          // number of lines should equal to list of dots
          toDelete = true;
          deletingReason = "polygon has three dots on a single line somewhere";
        }

        // fuck it! no one wants to do something that consumes our CPUs!
        // instead of checking and checking and checking, we'll create copies of polygon by ourself!

        List dotsLetters = [];
        List segmentsCopies = [];
        List anglesCopies = [];

        // firstly, we change our dots from IDs to letters
        for (var i = 0; i < object["dots"].length; i++) {
          dotsLetters.add(memory[object["dots"][i]][0]["letter"]);
        }

        // secondly, we'll create segments and angles.
        for (var i = 0; i < dotsLetters.length; i++) {
          var dot1 = dotsLetters[i];
          var dot2 = dotsLetters[(i + 1) % (dotsLetters.length)];
          var dot3 = dotsLetters[(i + 2) % (dotsLetters.length)];

          segmentsCopies.add(parseObject(memory, simpleObjects, consequencesMemory, "segment",
              dot1 + dot2, originSend, byParser));
          anglesCopies.add(parseObject(memory, simpleObjects, consequencesMemory, "angle",
              dot1 + dot2 + dot3, originSend, byParser));
        }

        // we will not doing copies of polygon with same dots and different orders of segments and angles. why?
        // because this is unnecessary - we will write all math sequences about all of the angles
        // and it would be less cpu-consuming for our telephones.

        object["angles"] = anglesCopies;
        object["segments"] = segmentsCopies;

        // now we should check if somewhere in memory we already have this polygon
        // no need to check the direction - we did a lot of checks already.

        for (var polygon in utils.allObjectsOfName(memory, "polygon").entries) {
          // we suppose that different variants of polygon contains same dots
          // so we get the first polygon entry and their dots responsibly
          var polygonDots = polygon.value[0]["dots"];

          bool samePolygon = true;

          if (polygonDots.length == object["dots"].length) {
            for (String polygonDot in polygonDots) {
              if (!object["dots"].contains(polygonDot)) {
                samePolygon = false;
              }
            }
          }

          if (samePolygon) {
            toMerge = true;
            mergeID = polygon.key;
            break;
          }
        }
      } else if (check["operation"] == "onlyByParser") {
        // use this operation only for testing purposes!!!
        if (!object.keys.contains("byParser")) {
          toDelete = true;
          deletingReason = "object did not pass onlyByParser check";
          break;
        }
        if (!object["byParser"]) {
          toDelete = true;
          deletingReason = "object did not pass onlyByParser check";
        }
      } else if (check["operation"] == "onlyByParserOrConsequence") {
        bool byParser = false;
        bool byConsequence = false;
        //if (!object.keys.contains("byParser")) {
        //toDelete = true;
        //deletingReason = "object did not pass onlyByParserOrConsequence (parser) check";
        //break;
        //}
        if (object["byParser"] == true) {
          byParser = true;
          //toDelete = true;
          //deletingReason = "object did not pass onlyByParserOrConsequence (parser) check";
        }
        //if (!object.keys.contains("byConsequence")) {
        //toDelete = true;
        //deletingReason = "object did not pass onlyByParserOrConsequence (consequence) check";
        //break;
        //}
        if (object["byConsequence"] == true) {
          byConsequence = true;
          //toDelete = true;
          //deletingReason = "object did not pass onlyByParserOrConsequence (consequence) check";
        }
        if (!(byParser || byConsequence)) {
          toDelete = true;
          if (!byParser) {
            deletingReason =
                "object did not pass onlyByParserOrConsequence (parser) check";
          } else {
            deletingReason =
                "object did not pass onlyByParserOrConsequence (consequence) check";
          }
        }
      } else if (check["operation"] == "objectExists") {
        // TODO!
      } else if (check["operation"] == "_perpendicular") {
        // TODO
      } else if (check["operation"] == "_triangleSameness") {
        var triangles = utils.allObjectsOfName(memory, "triangle");
        for (var triangle in triangles.entries) {
          if (triangle.value[0]["polygon"] == object["polygon"]) {
            toMerge = true;
            mergeID = triangle.key;
            break;
          }
        }
      } else if (check["operation"] == "_rightTriangle") {
        var triangle = object["triangle"];
        var rightAngle = "";
        originSend("log:$triangle ${memory[triangle][0]}");
        originSend(
            "log:angles of triangle: ${memory[memory[memory[triangle][0]["polygon"]][0]["angles"][0]][0]["degrees"]} ${memory[memory[memory[triangle][0]["polygon"]][0]["angles"][1]][0]["degrees"]} ${memory[memory[memory[triangle][0]["polygon"]][0]["angles"][2]][0]["degrees"]}");

        var angle1ID = memory[memory[triangle][0]["polygon"]][0]["angles"][0];
        var angle2ID = memory[memory[triangle][0]["polygon"]][0]["angles"][1];
        var angle3ID = memory[memory[triangle][0]["polygon"]][0]["angles"][2];

        var angle1object = memory[angle1ID][0];
        var angle2object = memory[angle2ID][0];
        var angle3object = memory[angle3ID][0];

        if(angle1object["degrees"] != null && double.parse(angle1object["degrees"]) == 90.0) {
          originSend("log:true angle1");
          rightAngle = angle1ID;
        } else if(angle2object["degrees"] != null && double.parse(angle2object["degrees"]) == 90.0) {
          originSend("log:true angle2");
          rightAngle = angle2ID;
        } else if(angle3object["degrees"] != null && double.parse(angle3object["degrees"]) == 90.0) {
          originSend("log:true angle3");
          rightAngle = angle3ID;
        } else {
          toDelete = true;
          deletingReason = "right triangle has no right angle";
          break;
        }

        var angle90DotID = memory[memory[rightAngle][0]["ray1"]][0]["startDot"];
        var angle90DotLetter = memory[angle90DotID][0]["letter"];
        var otherTopDotsIDs = jsonDecode(jsonEncode(memory[memory[object["triangle"]][0]["polygon"]][0]["dots"]));
        otherTopDotsIDs.remove(angle90DotID);
        var otherTopDot0Letter = memory[otherTopDotsIDs[0]][0]["letter"];
        var otherTopDot1Letter = memory[otherTopDotsIDs[1]][0]["letter"];

        object["rightAngle"] = utils.parseObjectByString(
            memory,
            simpleObjects,
            consequencesMemory,
            "angle(" +
                otherTopDot0Letter +
                angle90DotLetter +
                otherTopDot1Letter +
                ")",
            originSend,
            byParser);

        object["legs"] = [];
        object["legs"].add(utils.parseObjectByString(
            memory,
            simpleObjects,
            consequencesMemory,
            "segment(" + angle90DotLetter + otherTopDot0Letter + ")",
            originSend,
            byParser));
        object["legs"].add(utils.parseObjectByString(
            memory,
            simpleObjects,
            consequencesMemory,
            "segment(" + angle90DotLetter + otherTopDot1Letter + ")",
            originSend,
            byParser));

        object["hypotenuse"] = utils.parseObjectByString(
            memory,
            simpleObjects,
            consequencesMemory,
            "segment(" + otherTopDot0Letter + otherTopDot1Letter + ")",
            originSend,
            byParser);
      }
    }
    if (!toDelete) {
      // we created object (or merged it) - we should check for consequences
      if (simpleObjects[objectName].keys.contains("consequences")) {
        object["..consequences"] = simpleObjects[objectName]["consequences"];
      }

      if (toMerge) {
        memory[mergeID].add(object);
        if (object["toFind"]) {
          for (var i = 0; i < memory[mergeID].length; i++) {
            memory[mergeID][i]["toFind"] = true;
          }
        }
        memory[mergeID] = utils.postCheck(simpleObjects, memory[mergeID]);
        originSend("This object $id was merged into $mergeID.");
        //algorithm.printWrapped("memory now: $memory");
        id = mergeID;
      } else {
        originSend("This object was added as $id.");
        memory[id] = [object];
        //algorithm.printWrapped("memory now: $memory");
      }
      //originSend(" so the memory is: ${utils.prettyConvert(memory)}");

      if (simpleObjects[objectName].keys.contains("consequences")) {
        // TODO
        solveConsequences(memory, simpleObjects, consequencesMemory, originSend);
        String tempStr1 = utils.getAnswer(memory, simpleObjects, consequencesMemory, originSend);
        if (tempStr1 != "") {
          // we found the answer
          return id + "_solved";
        }
      }

      return id;
    } else {
      originSend("During check, this object was deleted ($deletingReason).");
      //originSend(" so the memory is: ${utils.prettyConvert(memory)}");
      return "";
    }
  } else {
    return "";
  }
}
