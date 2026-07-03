import 'dart:mirrors';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  ClassMirror cm = reflectClass(GoogleSignIn);
  print('Constructors:');
  cm.declarations.values.whereType<MethodMirror>().where((m) => m.isConstructor).forEach((m) {
    print(m.simpleName);
  });
  
  print('Methods:');
  cm.declarations.values.whereType<MethodMirror>().where((m) => !m.isConstructor).forEach((m) {
    print(m.simpleName);
  });
}
