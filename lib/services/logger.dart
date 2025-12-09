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

// Output will look similar to the example you saw (with box borders, coloring, and icons).
