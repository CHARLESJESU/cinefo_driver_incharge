import 'package:flutter/material.dart';

void showsuccessPopUp(
    BuildContext context, String message, VoidCallback onDismissed) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Text(message),
          ),
        ],
      );
    },
  );

  Future.delayed(const Duration(seconds: 1), () {
    Navigator.of(context).pop();
    print('Pop-up dismissed');
    onDismissed();
  });
}

void showmessage(BuildContext context, String message, String ok) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.start,
              overflow: TextOverflow.visible,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Widget commonRow(String imagePath, String text, int number) {
  return Row(
    children: [
      Image.asset(
        imagePath,
        width: 50,
        height: 50,
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      Spacer(),
      Text(
        number.toString(),
        style: const TextStyle(fontSize: 14, color: Colors.blue),
      ),
    ],
  );
}

void showSimplePopUp(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text('Message'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25),
            child: Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.start,
              overflow: TextOverflow.visible,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
