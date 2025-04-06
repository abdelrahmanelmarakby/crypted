import 'dart:async';

class StreamedList<T> {
  final StreamController<List<T>> _controller = StreamController.broadcast();

  Stream<List<T>> get data => _controller.stream;

  List<T> _list = [];

  void updateList(List<T> list) {
    _list = list;
    _dispatch();
  }

  void addToList(T value) {
  _list = [..._list, value];
  _dispatch();
  }

  void _dispatch() {
    _controller.sink.add(_list);
  }

  void dispose() {
    _list = [];
    _controller.close();
  }
}

class Streamed<T> {
  final StreamController<T> _controller = StreamController.broadcast();

  Stream<T> get data => _controller.stream;

  T? _value;

  void updateValue(T value) {
    _value = value;
    _dispatch();
  }

  void _dispatch() {
    if (_value == null) return;
    _controller.sink.add(_value as T);
  }

  void dispose() {
    _value = null;
    _controller.close();
  }
}