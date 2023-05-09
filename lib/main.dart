import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_usb/quick_usb.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyHome());
}

class MyHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: MyApp(),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    UsbService.usbRecvPort = ReceivePort();
    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    await Isolate.spawn(UsbService.loopUsb, {'token': rootIsolateToken, 'port': UsbService.usbRecvPort!.sendPort});
  }

  @override
  Widget build(BuildContext context) {
    return _buildColumn();
  }

  void log(String info) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(info)));
  }

  Widget _buildColumn() {
    return Column(
      children: [
        _init_exit(),
        _getDeviceList(),
      ],
    );
  }

  Widget _init_exit() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('init'),
          onPressed: () async {
            var init = await QuickUsb.init();
            log('init $init');
          },
        ),
        ElevatedButton(
          child: Text('exit'),
          onPressed: () async {
            await QuickUsb.exit();
            log('exit');
          },
        ),
      ],
    );
  }

  List<UsbDevice>? _deviceList;

  Widget _getDeviceList() {
    return ElevatedButton(
      child: Text('getDeviceList'),
      onPressed: () async {
        _deviceList = await QuickUsb.getDeviceList();
        log('deviceList $_deviceList');
      },
    );
  }
}

class UsbService {
  static SendPort? usbSendPort;
  static ReceivePort? usbRecvPort;

  static void loopUsb(Map<String, Object> args) async {
    RootIsolateToken rootIsolateToken = args['token'] as RootIsolateToken;
    SendPort sendPort = args['port'] as SendPort;
    BackgroundIsolateBinaryMessenger
        .ensureInitialized(rootIsolateToken);
    ReceivePort p = ReceivePort();
    sendPort.send(p.sendPort);
    //QuickUsbWindows.registerWith();

    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        var init = await QuickUsb.init();
        print('init $init');

        var list = await QuickUsb.getDeviceList();
        print(list);

        await QuickUsb.exit();
      } catch (e) {
        print(e);
      }
    }
  }
}
