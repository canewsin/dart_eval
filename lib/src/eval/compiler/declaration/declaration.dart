import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/class.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/compiler/declaration/function.dart';
import 'package:dart_eval/src/eval/compiler/declaration/method.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';

int? compileDeclaration(Declaration d, CompilerContext ctx,
    {Declaration? parent, int? fieldIndex, List<FieldDeclaration>? fields}) {
  if (d is ClassDeclaration) {
    compileClassDeclaration(ctx, d);
  } else if (d is MethodDeclaration) {
    return compileMethodDeclaration(
        d, ctx, parent as NamedCompilationUnitMember);
  } else if (d is FunctionDeclaration) {
    compileFunctionDeclaration(d, ctx);
  } else if (d is FieldDeclaration) {
    compileFieldDeclaration(fieldIndex!, d, ctx, parent as ClassDeclaration);
  } else if (d is ConstructorDeclaration) {
    compileConstructorDeclaration(ctx, d, parent as ClassDeclaration, fields!);
  } else {
    throw CompileError('No support for ${d.runtimeType}');
  }
}
