import 'package:logger/logger.dart';

var customLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
);

void logBeautifully() {
  customLogger.i('Audio file successfully transcribed!');
  customLogger.w('Check connection settings if API requests fail.');
  customLogger.e('Permission denied: RECORD_AUDIO is missing.');
}

abstract class Excuse {
  void give();
}

class Overslept implements Excuse {
  @override
  void give() {
    print("I overslept. Couldn’t submit homework.");
  }
}

class BusLate implements Excuse {
  @override
  void give() {
    print("The bus was late. Assignment didn’t arrive on time.");
  }
}

class Forgot implements Excuse {
  @override
  void give() {
    print("I completely forgot about the homework. Sorry!");
  }
}
