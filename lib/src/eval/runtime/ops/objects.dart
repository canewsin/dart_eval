part of '../runtime.dart';

class InvokeDynamic implements DbcOp {
  InvokeDynamic(Runtime runtime)
      : _location = runtime._readInt16(),
        _method = runtime._readString();

  InvokeDynamic.make(this._location, this._method);

  final int _location;
  final String _method;

  static int len(InvokeDynamic s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._method);
  }

  @override
  void run(Runtime runtime) {
    var object = runtime.frame[_location];

    while (true) {
      if (object is $InstanceImpl) {
        final methods = object.evalClass.methods;
        final _offset = methods[_method];
        if (_offset == null) {
          object = object.evalSuperclass;
          continue;
        }
        runtime.callStack.add(runtime._prOffset);
        runtime._prOffset = _offset;
        return;
      }

      final method = ((object as $Instance).$getProperty(runtime, _method) as EvalFunction);
      if (method is $Function) {
        runtime.returnValue = method.call(runtime, object, runtime.args.cast());
        runtime.args = [];
        return;
      } else {
        runtime.returnValue = method.call(runtime, object, runtime.args.cast());
        runtime.args = [];
        return;
      }
    }

  }

  @override
  String toString() => 'InvokeDynamic (L$_location.$_method)';
}

// Create a class
class CreateClass implements DbcOp {
  CreateClass(Runtime runtime) :
        _library = runtime._readInt32(),
        _super = runtime._readInt16(),
        _name = runtime._readString(),
        _valuesLen = runtime._readInt16();

  CreateClass.make(this._library, this._super, this._name, this._valuesLen);

  final int _library;
  final String _name;
  final int _super;
  final int _valuesLen;

  static int len(CreateClass s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.I16_LEN * 2 + Dbc.istr_len(s._name);
  }

  @override
  void run(Runtime runtime) {
    final $super = runtime.frame[_super] as $Instance?;
    final $cls = runtime.declaredClasses[_library]![_name]!;

    final instance = $InstanceImpl($cls, $super, List.filled(_valuesLen, null));
    runtime.frame[runtime.frameOffset++] = instance;
  }

  @override
  String toString() => 'CreateClass (F$_library:"$_name", super L$_super, vLen=$_valuesLen))';
}

class SetObjectProperty implements DbcOp {
  SetObjectProperty(Runtime runtime)
      : _location = runtime._readInt16(),
        _property = runtime._readString(),
        _valueOffset = runtime._readInt16();

  SetObjectProperty.make(this._location, this._property, this._valueOffset);

  final int _location;
  final String _property;
  final int _valueOffset;

  static int len(SetObjectProperty s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._property) + Dbc.I16_LEN;
  }

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[_location];
    (object as $Instance)
        .$setProperty(runtime, _property, runtime.frame[_valueOffset] as $Value);
  }

  @override
  String toString() => 'SetObjectProperty (L$_location.$_property = L$_valueOffset)';
}

class PushObjectProperty implements DbcOp {
  PushObjectProperty(Runtime runtime)
      : _location = runtime._readInt16(),
        _property = runtime._readString();

  PushObjectProperty.make(this._location, this._property);

  final int _location;
  final String _property;

  static int len(PushObjectProperty s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._property);
  }

  @override
  void run(Runtime runtime) {
    var object = runtime.frame[_location];

    while (true) {
      if (object is $InstanceImpl) {
        final evalClass = object.evalClass;
        final _offset = evalClass.getters[_property];
        if (_offset == null) {
          final method = evalClass.methods[_property];
          if (method == null) {
            object = object.evalSuperclass;
            continue;
          }
          runtime.returnValue = EvalFunctionPtr(object, method, 0, [], [], []);
          runtime.args = [];
          return;
        }
        runtime.args.add(object);
        runtime.callStack.add(runtime._prOffset);
        runtime._prOffset = _offset;
        return;
      }

      final result = ((object as $Instance).$getProperty(runtime, _property));
      runtime.returnValue = result;
      runtime.args = [];
      return;
    }
  }

  @override
  String toString() => 'PushObjectProperty (L$_location.$_property)';
}

class PushObjectPropertyImpl implements DbcOp {
  PushObjectPropertyImpl(Runtime runtime) :
        _objectOffset = runtime._readInt16(),
        _propertyIndex = runtime._readInt16();

  final int _objectOffset;
  final int _propertyIndex;

  PushObjectPropertyImpl.make(this._objectOffset, this._propertyIndex);

  static int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[_objectOffset] as $InstanceImpl;
    runtime.frame[runtime.frameOffset++] = object.values[_propertyIndex];
  }

  @override
  String toString() => 'PushObjectPropertyImpl (L$_objectOffset[$_propertyIndex])';
}

class SetObjectPropertyImpl implements DbcOp {
  SetObjectPropertyImpl(Runtime runtime)
      : _objectOffset = runtime._readInt16(),
        _propertyIndex = runtime._readInt16(),
        _valueOffset = runtime._readInt16();

  final int _objectOffset;
  final int _propertyIndex;
  final int _valueOffset;

  SetObjectPropertyImpl.make(this._objectOffset, this._propertyIndex, this._valueOffset);

  static int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 3;

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[_objectOffset] as $InstanceImpl;
    final value = runtime.frame[_valueOffset]!;
    object.values[_propertyIndex] = value;
  }

  @override
  String toString() => 'SetObjectPropertyImpl (L$_objectOffset[$_propertyIndex] = L$_valueOffset)';
}

class PushSuper implements DbcOp {
  PushSuper(Runtime runtime) :
        _objectOffset = runtime._readInt16();

  final int _objectOffset;

  PushSuper.make(this._objectOffset);

  static int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[_objectOffset] as $InstanceImpl;
    runtime.frame[runtime.frameOffset++] = object.evalSuperclass;
  }

  @override
  String toString() => 'PushSuper (L$_objectOffset.super)';
}
