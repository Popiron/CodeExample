import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';
import 'package:walkscreen/com_services/main_methods/convert.dart';
import 'package:walkscreen/com_services/models/request_to_screen/summary_phone_info.dart';
import 'package:walkscreen/helpers/blue_interaction.dart';
import 'package:walkscreen/helpers/requests.dart';

///Класс для взаимодействия с платформой `Android` и для работы с `COM-портом (Bluetooth RFCOMM)`.
class AndroidRFCOMM {
  ///Подписка на `поток` сообщений из `Android`
  static StreamSubscription _messagesSubscription;

  ///Канал для `потока` из `Android`
  static const _stream = EventChannel('com.walkscreen.app/stream');

  ///Канал для `методов` из `Android`
  static const _platform = MethodChannel('com.walkscreen.app/rfcomm');

  static const _tag = "rfcomm_android.dart/ ";

  ///`Контроллер для внутреннего потока`
  static StreamController<Tuple2<String, String>> _controller =
      StreamController<Tuple2<String, String>>.broadcast();

  ///`Получение внутреннего потока`
  static Stream<Tuple2<String, String>> get messagesStream =>
      _controller.stream;

  ///`Получение внутреннего потока`
  static StreamController<Tuple2<String, String>> get notificationController =>
      _controller;

  static StreamController<int> _connectionController =
      StreamController<int>.broadcast();

  static Stream<int> get connectionStream => _connectionController.stream;

  ///`Включение` потока сообщений из Android
  static _enableMessagesStream() {
    if (_messagesSubscription == null) {
      _messagesSubscription =
          _stream.receiveBroadcastStream().listen(_processStream);
    }
  }

  ///`Выключение` потока сообщений из Android
  static _disableMessagesStream() {
    if (_messagesSubscription != null) {
      _messagesSubscription.cancel();
      _messagesSubscription = null;
    }
  }

//обработка входящих сообщений
  static _processMessage(String message) {
    _controller.sink.add(Tuple2<String, String>("message", message));
  }

  ///`Обработка` потока сообщений из Android
  static _processStream(incomingMessage) {
    var message = incomingMessage as Map<dynamic, dynamic>;
    //Тип сообщения
    switch (message["Type"]) {

      //Принятие информации от другого устройства
      case "MESSAGE_READ":
        print(_tag + message["Message"].toString());
        //Добавление сообщения во внутренний поток
        _controller.sink.add(Tuple2<String, String>(
            "Новое сообщение!", message["Message"].toString()));
        _processMessage(message["Message"].toString());

        break;
      //Ошибка
      case "MESSAGE_ERROR":
        print(_tag + message["Message"].toString());
        _controller.sink.add(
            Tuple2<String, String>("Ошибка", message["Message"].toString()));
        _connectionController.sink.add(0);

        break;
      case "MESSAGE_CONNECTION":
        print(_tag + message["Message"].toString());
        _connectionController.sink.add(message["Message"]);
        break;
      //Уведомление
      case "MESSAGE_NOTIFICATION":
        print(_tag + message["Message"].toString());
        _controller.sink.add(Tuple2<String, String>(
            "Уведомление", message["Message"].toString()));
        break;

      default:
        print(_tag + "Not implemented case: ${message["Type"]}");
    }
  }

  ///`Запускает сервис` для bluetooth.
  ///Вызывать в самом начале работы программы. Например, в initState()
  static void startBluetoothService() {
    try {
      _enableMessagesStream();
      _platform.invokeMethod('startService');
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///`Останавливает сервис` для bluetooth. Можно вызвать в  любом месте программы.
  static void stopBluetoothService() {
    try {
      _disableMessagesStream();
      _platform.invokeMethod('stopService');
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///Возвращает `Map` сопряженных устройств.
  /// [key] == `MAC-address`, [value] == `Имя устройства`.
  /// Использовать после запуска сервиса!
  static Future<Map<dynamic, dynamic>> getPairedDevices() async {
    Map<dynamic, dynamic> devices = Map<dynamic, dynamic>();
    try {
      var res = await _platform.invokeMethod('getPairedDevices');
      devices = res as Map<dynamic, dynamic>;
      return devices;
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  ///`Устанавливает соединение` с устройством.
  /// [name_of_device] == `имя устройства`, [mac_address] == `MAC-адрес`.
  /// Использовать после запуска сервиса!
  static void establishConnection(
      String nameOfDevice, String macAddress) async {
    try {
      await _platform.invokeMethod('establishConnection',
          {"nameOfDevice": nameOfDevice, "macAddress": macAddress});
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///`Отправка сообщения` на присоединенное устройство.
  ///  `mes` == `Строка с сообщением`.
  /// Использовать после запуска сервиса!
  static Future<void> sendMessage(String mes) async {
    try {
      var byteMes = utf8.encode(mes);
      await _platform.invokeMethod('sendMessage', {"message": byteMes});
      return;
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///`Отправка информации` на присоединенное устройство.
  ///  `phoneInfo` == `Информация о телефоне`.
  /// Использовать после запуска сервиса!
  static Future<void> sendDataMessage(PhoneInfo phoneInfo) async {
    try {
      var message = Convert.convertPhoneInfoToBytes(phoneInfo);
      return await _platform.invokeMethod('sendMessage', {"message": message});
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///`Отправка файла` на присоединенное устройство.
  ///  `file` == `файл на отправку`.
  /// Использовать после запуска сервиса!
  static Future<void> sendFile(File file) async {
    try {
      if (file != null) {
        var isExists = await file.exists();
        if (isExists)
          // return await _platform.invokeMethod('sendMessage', {"message": file.readAsBytesSync()});
          return await _platform.invokeMethod('sendFile', {"path": file.path});
      }
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }

  ///`Переход приложения в фоновый режим`.
  ///Используется для устранение бага при выходе из приложения посредством нижней панели управления.
  static void sendToBackground() async {
    try {
      await _platform.invokeMethod('sendToBackground');
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }

  static void disconnectFromDevice() async {
    try {
      await _platform.invokeMethod('disconnectFromDevice');
    } on PlatformException catch (error) {
      print(error.message);
    } catch (e) {
      print(e.toString());
    }
  }
}
