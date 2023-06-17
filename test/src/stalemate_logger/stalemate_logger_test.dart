import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stalemate/src/stalemate_logger/stalemate_logger.dart';

void main() {
  late StaleMateLogger staleMateLogger;

  setUp(() {
    staleMateLogger = StaleMateConsoleLogger();
    // Set the log level to debug so that all logs are printed to console
    // log level functionality will be tested separatly
    staleMateLogger.setLogLevel(StaleMateLogLevel.debug);
  });

  Future<void> captureConsoleOutput(
    Future<void> Function(StringBuffer buffer) testCode,
  ) async {
    final StringBuffer buffer = StringBuffer();
    final Completer completer = Completer<void>();

    runZonedGuarded(
      () async {
        await testCode(buffer);
        completer.complete();
      },
      (error, stackTrace) {
        completer.completeError(error, stackTrace);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, message) {
          buffer.writeln(message); // Capture the console output
        },
      ),
    );

    await completer.future;
  }

  group('basic logging functionality', () {
    test('log should print to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log('test log message', StaleMateLogLevel.debug);
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test log message'));
      });
    });

    test('logError should print to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.logError('test error message');
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test error message'));
        expect(consoleOutput, contains('ERROR'));
      });
    });

    test('logWarning should print to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.logWarning('test warning message');
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test warning message'));
        expect(consoleOutput, contains('WARNING'));
      });
    });

    test('logInfo should print to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.logInfo('test info message');
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test info message'));
        expect(consoleOutput, contains('INFO'));
      });
    });

    test('logDebug should print to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.logDebug('test debug message');
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test debug message'));
        expect(consoleOutput, contains('DEBUG'));
      });
    });

    test('log should print tag to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log('test log message', StaleMateLogLevel.debug,
            tag: 'test tag');
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test tag'));
      });
    });

    test('log should print error to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log(
          'test log message',
          StaleMateLogLevel.error,
          error: 'test error message',
        );
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test error message'));
      });
    });

    test('log should print stackTrace to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log(
          'test log message',
          StaleMateLogLevel.error,
          stackTrace: StackTrace.current,
        );
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('Stack Trace'));
      });
    });

    test('log should print data to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log(
          'test log message',
          StaleMateLogLevel.error,
          data: 'test data',
        );
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test data'));
      });
    });

    test('log should print list data to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log(
          'test log message',
          StaleMateLogLevel.error,
          data: ['test data', 'test data 2'],
        );
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test data'));
        expect(consoleOutput, contains('test data 2'));
      });
    });

    test('log should print map data to console', () async {
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log(
          'test log message',
          StaleMateLogLevel.error,
          data: {
            'testDataKey1': 'test data 1',
            'testDataKey2': 'test data 2',
          },
        );
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('testDataKey1'));
        expect(consoleOutput, contains('test data 1'));
        expect(consoleOutput, contains('test data 2'));
        expect(consoleOutput, contains('testDataKey1'));
      });
    });
  });

  group('Logger log levels', () {
    test('None logging level never logs out', () async {
      staleMateLogger.setLogLevel(StaleMateLogLevel.none);
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log('test error message', StaleMateLogLevel.error);
        staleMateLogger.log('test warning message', StaleMateLogLevel.warning);
        staleMateLogger.log('test info message', StaleMateLogLevel.info);
        staleMateLogger.log('test debug message', StaleMateLogLevel.debug);
        final consoleOutput = buffer.toString();
        expect(consoleOutput, isEmpty);
      });
    });

    test('Error log level only logs out error logs', () async {
      staleMateLogger.setLogLevel(StaleMateLogLevel.error);
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log('test error message', StaleMateLogLevel.error);
        staleMateLogger.log('test warning message', StaleMateLogLevel.warning);
        staleMateLogger.log('test info message', StaleMateLogLevel.info);
        staleMateLogger.log('test debug message', StaleMateLogLevel.debug);
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test error message'));
        expect(consoleOutput, contains('ERROR'));
        expect(consoleOutput, isNot(contains('test debug message')));
        expect(consoleOutput, isNot(contains('test warning message')));
        expect(consoleOutput, isNot(contains('test info message')));
      });
    });

    test('Warning log level only shows error and warning logs', () async {
      staleMateLogger.setLogLevel(StaleMateLogLevel.warning);
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log('test error message', StaleMateLogLevel.error);
        staleMateLogger.log('test warning message', StaleMateLogLevel.warning);
        staleMateLogger.log('test info message', StaleMateLogLevel.info);
        staleMateLogger.log('test debug message', StaleMateLogLevel.debug);
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test error message'));
        expect(consoleOutput, contains('ERROR'));
        expect(consoleOutput, contains('test warning message'));
        expect(consoleOutput, contains('WARNING'));
        expect(consoleOutput, isNot(contains('test debug message')));
        expect(consoleOutput, isNot(contains('test info message')));
      });
    });

    test('Info log level contains everything except debug', () async {
      staleMateLogger.setLogLevel(StaleMateLogLevel.info);
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log('test error message', StaleMateLogLevel.error);
        staleMateLogger.log('test warning message', StaleMateLogLevel.warning);
        staleMateLogger.log('test info message', StaleMateLogLevel.info);
        staleMateLogger.log('test debug message', StaleMateLogLevel.debug);
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test error message'));
        expect(consoleOutput, contains('ERROR'));
        expect(consoleOutput, contains('test warning message'));
        expect(consoleOutput, contains('WARNING'));
        expect(consoleOutput, contains('test info message'));
        expect(consoleOutput, contains('INFO'));
        expect(consoleOutput, isNot(contains('test debug message')));
      });
    });

    test('Debug log level contains everything', () async {
      staleMateLogger.setLogLevel(StaleMateLogLevel.debug);
      await captureConsoleOutput((buffer) async {
        staleMateLogger.log('test error message', StaleMateLogLevel.error);
        staleMateLogger.log('test warning message', StaleMateLogLevel.warning);
        staleMateLogger.log('test info message', StaleMateLogLevel.info);
        staleMateLogger.log('test debug message', StaleMateLogLevel.debug);
        final consoleOutput = buffer.toString();
        expect(consoleOutput, contains('test error message'));
        expect(consoleOutput, contains('ERROR'));
        expect(consoleOutput, contains('test warning message'));
        expect(consoleOutput, contains('WARNING'));
        expect(consoleOutput, contains('test info message'));
        expect(consoleOutput, contains('INFO'));
        expect(consoleOutput, contains('test debug message'));
        expect(consoleOutput, contains('DEBUG'));
      });
    });
  });
}
