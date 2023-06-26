import 'package:stalemate/stalemate.dart';

class StringEmptyValueHandler extends RemoteOnlyStaleMateHandler<String> {
  @override
  String get emptyValue => '';

  @override
  Future<String> getRemoteData() async {
    return 'remote data';
  }
}

class IntEmptyValueHandler extends RemoteOnlyStaleMateHandler<int> {
  @override
  int get emptyValue => -1;

  @override
  Future<int> getRemoteData() async {
    return 1;
  }
}

class DoubleEmptyValueHandler extends RemoteOnlyStaleMateHandler<double> {
  @override
  double get emptyValue => -1.0;

  @override
  Future<double> getRemoteData() async {
    return 1.0;
  }
}

class BoolEmptyValueHandler extends RemoteOnlyStaleMateHandler<bool> {
  @override
  bool get emptyValue => false;

  @override
  Future<bool> getRemoteData() async {
    return true;
  }
}

class ListEmptyValueHandler extends RemoteOnlyStaleMateHandler<List> {
  @override
  List get emptyValue => [];

  @override
  Future<List> getRemoteData() async {
    return [1, 2, 3];
  }
}

class MapEmptyValueHandler extends RemoteOnlyStaleMateHandler<Map> {
  @override
  Map get emptyValue => {};

  @override
  Future<Map> getRemoteData() async {
    return {'key': 'value'};
  }
}

class SetEmptyValueHandler extends RemoteOnlyStaleMateHandler<Set> {
  @override
  Set get emptyValue => {};

  @override
  Future<Set> getRemoteData() async {
    return {1, 2, 3};
  }
}

class NullableEmptyValueHandler extends RemoteOnlyStaleMateHandler<String?> {
  @override
  String? get emptyValue => null;

  @override
  Future<String?> getRemoteData() async {
    return 'remote data';
  }
}

enum TestEnum { empty, one, two }

class EnumEmptyValueHandler extends RemoteOnlyStaleMateHandler<TestEnum> {
  @override
  TestEnum get emptyValue => TestEnum.empty;

  @override
  Future<TestEnum> getRemoteData() async {
    return TestEnum.one;
  }
}

class TestClass {
  final String name;
  final int age;

  TestClass(this.name, this.age);

  @override
  String toString() {
    return 'TestClass{name: $name, age: $age}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestClass &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

class CustomClassEmptyValueHandler extends RemoteOnlyStaleMateHandler<TestClass> {
  @override
  TestClass get emptyValue => TestClass('', -1);

  @override
  Future<TestClass> getRemoteData() async {
    return TestClass('name', 1);
  }
}