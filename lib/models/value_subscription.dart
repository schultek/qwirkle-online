import 'dart:async';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase/firebase.dart';
import 'package:flutter/foundation.dart';

abstract class JsonEncodable {
  dynamic toJson();
}

class ValueSubscription<T> extends ValueNotifier<T> {
  late StreamSubscription subscription;

  DatabaseReference ref;

  ValueSubscription(this.ref, T? Function(dynamic data) mapper, T initialValue) : super(initialValue) {
    subscription = ref.onValue.listen((event) {
      var data = event.snapshot.val();
      value = mapper(data) ?? initialValue;
    });
  }

  Future<void> set(T newValue) async {
    if (newValue == value) return;
    var v = encode(newValue);
    await ref.set(v);
  }

  static dynamic encode(dynamic value) {
    if (value is List) {
      return value.map(encode).toList();
    } else if (value is JsonEncodable) {
      return value.toJson();
    } else {
      return value;
    }
  }

  @override
  void dispose() {
    super.dispose();
    subscription.cancel();
  }
}
