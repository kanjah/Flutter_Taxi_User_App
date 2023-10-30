import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  String message;
  ProgressDialog({this.message}); //string message to be used in text

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.yellow,
      child: Container(
        margin: const EdgeInsets.all(15.0),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16.0)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              const SizedBox(
                width: 6.0,
              ),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
              const SizedBox(width: 26.0),
              Text(
                message,
                style: const TextStyle(color: Colors.black, fontSize: 10.0),
              )
            ],
          ),
        ),
      ),
    );
  }
}
