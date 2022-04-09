import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/statement/block.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

int compileMethodDeclaration(MethodDeclaration d, CompilerContext ctx, NamedCompilationUnitMember parent) {
  ctx.runPrescan(d);
  final b = d.body;
  final pos = beginMethod(ctx, d, d.offset, parent.name.name + '.' + d.name.name + '()');

  ctx.beginAllocScope(existingAllocLen: (d.parameters?.parameters.length ?? 0));
  ctx.scopeFrameOffset += d.parameters?.parameters.length ?? 0;
  final resolvedParams = resolveFPLDefaults(ctx, d.parameters!, true, allowUnboxed: true);

  var i = 1;

  for (final param in resolvedParams) {
    final p = param.parameter;
    Variable Vrep;

    p as SimpleFormalParameter;
    var type = EvalTypes.dynamicType;
    if (p.type != null) {
      type = TypeRef.fromAnnotation(ctx, ctx.library, p.type!);
    }
    Vrep = Variable(i, type)..name = p.identifier!.name;

    ctx.setLocal(Vrep.name!, Vrep);

    i++;
  }

  StatementInfo? stInfo;
  if (b is BlockFunctionBody) {
    stInfo = compileBlock(
        b.block, AlwaysReturnType.fromAnnotation(ctx, ctx.library, d.returnType, EvalTypes.dynamicType), ctx,
        name: d.name.name + '()');
  } else {
    throw CompileError('Unknown function body type ${b.runtimeType}');
  }

  ctx.endAllocScope();

  if (!(stInfo.willAlwaysReturn || stInfo.willAlwaysThrow)) {
    ctx.pushOp(Return.make(-1), Return.LEN);
  }

  if (d.isStatic) {
    ctx.topLevelDeclarationPositions[ctx.library]!['${parent.name.name}.${d.name.name}'] = pos;
  } else {
    ctx.instanceDeclarationPositions[ctx.library]![parent.name.name]![2][d.name.name] = pos;
  }

  return pos;
}
