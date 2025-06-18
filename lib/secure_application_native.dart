import 'dart:async';

import 'package:flutter/services.dart';

class SecureApplicationNative {
  static const MethodChannel _channel = const MethodChannel('secure_application');

  static void registerForEvents(VoidCallback lock, VoidCallback unlock, VoidCallback onActive, VoidCallback onInactive) {
    _channel.setMethodCallHandler((call) => secureApplicationHandler(call, lock, unlock, onActive, onInactive));
  }

  static Future<dynamic> secureApplicationHandler(MethodCall methodCall, lock, unlock, onActive, onInactive) async {
    switch (methodCall.method) {
      case 'appLifecycleStateChanged':
        var state = methodCall.arguments;
        if (state == 'active') {
          onActive();
        } else if (state == 'inactive') {
          onInactive();
        }
        break;
      case 'lock':
        lock();
        break;
      case 'unlock':
        unlock();
        break;
      default:
        throw MissingPluginException('notImplemented');
    }
  }

  static Future secure() {
    return _channel.invokeMethod('secure');
  }

  static Future open() {
    return _channel.invokeMethod('open');
  }

  static Future lock() {
    return _channel.invokeMethod('lock');
  }

  static Future unlock() {
    return _channel.invokeMethod('unlock');
  }

  static Future opacity(double opacity) {
    return _channel.invokeMethod('opacity', {"opacity": opacity});
  }
}
