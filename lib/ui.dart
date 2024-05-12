import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:geometryapp/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

devDialog(BuildContext context, _geometryProblem, showUiProblem) {
  logMain("Opening dev dialog");
  showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
            title: const Text("Дополнительные опции"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    String problem =
                        "ACDBO=perpendiculars&DOA=angle.toFind&DOC=angle.toFind&COB=angle.toFind&AOB=angle.toFind";
                    //"DB=line&ADB=dotNotInLine&CDB=dotInLine&CAB70.0=angle&ABC60.0=angle&ACB=angle&ACD=angle.toFind";
                    //"B=line&CDB=dotInLine&ADB=dotNotInLine&CDA60=angle&CAD60=angle&ACD=angle.toFind";
                    logMain("Testing standart problem ($problem)");
                    _geometryProblem(problem, kDebugMode);
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text("DEV: Тест стандартной проблемы"),
                  style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    logMain("Showing logs");
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                              title: const Text("Логи"),
                              content: Column(children: [
                                TextButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                              text: logList.join("\n")))
                                          .then((_) {
                                        Navigator.pop(context);
                                        logMain("Copying logs");
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                const CupertinoAlertDialog(
                                                  title:
                                                      Text("Логи скопированы!"),
                                                ));
                                        //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email address copied to clipboard")));
                                      });
                                    },
                                    icon: const Icon(Icons.copy),
                                    label: const Text("Скопировать логи"),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.black))),
                                SelectableText(logList.join("\n"))
                              ]),
                            ));
                  },
                  icon: const Icon(Icons.short_text),
                  label: const Text("DEV: Логи"),
                  style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    logMain("Parsing UI to query");
                    showUiProblem();
                  },
                  icon: const Icon(Icons.arrow_right_alt),
                  label: const Text("DEV: Парс UI в query"),
                  style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    logMain("Clicking 'Send ideas' button");
                    PackageInfo packageInfo = await PackageInfo.fromPlatform();
                    String version = packageInfo.version;
                    String buildNumber = packageInfo.buildNumber;
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                              title: const Text("Предложить идею"),
                              content: Column(children: [
                                const Text(
                                    "Это приложение неидеально. В нём есть небольшие (а иногда большие) недоработки. Благодаря Вашей помощи, приложение развивается! Напишите свою идею здесь: "),
                                TextButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      logMain("Sending idea email");
                                      final Email email = Email(
                                        body:
                                            'Напишите здесь свою идею. Спасибо за помощь в разработке!\n========= \n\n\n\n=========\nНаписанная ниже информация нужна для разработчика, не удаляйте её!\nVersion: $version\nBuildNumber: $buildNumber',
                                        subject:
                                            'Предложить идею | GeometryApp',
                                        recipients: [
                                          'cute.tadpole.gen@gmail.com'
                                        ],
                                        //cc: ['cc@example.com'],
                                        //bcc: ['bcc@example.com'],
                                        //attachmentPaths: ['/path/to/attachment.zip'],
                                        isHTML: false,
                                      );
                                      await FlutterEmailSender.send(email);
                                    },
                                    icon: const Icon(Icons.email_outlined),
                                    label: const Text("E-mail"),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.black))),
                              ]),
                            ));
                  },
                  icon: const Icon(Icons.assistant_outlined),
                  label: const Text("Предложить идею"),
                  style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    logMain("Clicking 'Send an error' button");
                    Navigator.pop(context);
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => CupertinoAlertDialog(
                              title: const Text("Отправить ошибку"),
                              content: Column(children: [
                                const Text(
                                    "Это приложение неидеально. В нём иногда происходят ошибки, и, сообщая о них, Вы помогаете развивать приложение!\n\nПожалуйста, убедитесь, что Вы отправляете ошибку сразу после неудачной попытки решения геометрической проблемы - приложение сохраняет журнал только последнего решения! Журнал будет отправлен разработчику."),
                                TextButton.icon(
                                    onPressed: () async {
                                      var directory =
                                          (await getTemporaryDirectory()).path;
                                      var file = File('$directory/log.txt');
                                      if (file.existsSync()) {
                                        file.deleteSync();
                                      }
                                      file.createSync();
                                      file.writeAsStringSync(
                                          logList.join("\n· "));
                                      Navigator.pop(context);
                                      logMain("Sending error email");
                                      final Email email = Email(
                                        body:
                                            'Напишите сюда дополнительную информацию об ошибке, если таковая имеется. Спасибо за помощь в разработке!\n========= \n\n',
                                        subject:
                                            'Ошибка в приложении | GeometryApp',
                                        recipients: [
                                          'cute.tadpole.gen@gmail.com'
                                        ],
                                        //cc: ['cc@example.com'],
                                        //bcc: ['bcc@example.com'],
                                        attachmentPaths: ['$directory/log.txt'],
                                        isHTML: false,
                                      );
                                      await FlutterEmailSender.send(email);
                                    },
                                    icon: const Icon(Icons.email_outlined),
                                    label: const Text("E-mail"),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.black))),
                              ]),
                            ));
                  },
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text("Отправить ошибку"),
                  style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black)),
                )
              ],
            ),
          ));
}
