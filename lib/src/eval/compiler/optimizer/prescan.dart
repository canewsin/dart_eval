import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/ops/all_ops.dart';

class PrescanVisitor extends RecursiveAstVisitor<PrescanContext?> {

  final PrescanContext ctx = PrescanContext();

  @override
  PrescanContext? visitFunctionDeclaration(FunctionDeclaration node) {
    ctx.beginAllocScope();
    super.visitFunctionDeclaration(node);
    ctx.endAllocScope();
  }

  @override
  PrescanContext? visitMethodDeclaration(MethodDeclaration node) {
    ctx.beginAllocScope();
    super.visitMethodDeclaration(node);
    ctx.endAllocScope();
  }


  @override
  PrescanContext? visitVariableDeclaration(VariableDeclaration node) {
    node.initializer?.accept(this);
    ctx.setLocal(node.name.name, Variable.alloc(ctx, EvalTypes.dynamicType));
  }

  @override
  PrescanContext? visitBlock(Block node) {
    ctx.beginAllocScope();
    node.visitChildren(this);
    ctx.endAllocScope();
  }

  @override
  PrescanContext? visitIfStatement(IfStatement node) {
    ctx.beginAllocScope();
    node.condition.accept(this);
    final _initialState = ctx.saveState();
    ctx.beginAllocScope();
    node.thenStatement.accept(this);
    ctx.endAllocScope();
    ctx.resolveBranchStateDiscontinuity(_initialState);
    if (node.elseStatement != null) {
      ctx.beginAllocScope();
      node.elseStatement!.accept(this);
      ctx.endAllocScope();
      ctx.resolveBranchStateDiscontinuity(_initialState);
    }
    ctx.endAllocScope();
  }

  @override
  PrescanContext? visitFunctionExpression(FunctionExpression node) {
    if (node.parent is Statement || node.parent is Expression) {
      ctx.inClosure = true;
      node.visitChildren(this);
      ctx.inClosure = false;
    }
    return null;
  }

  @override
  PrescanContext? visitSimpleIdentifier(SimpleIdentifier node) {
    if (ctx.inClosure) {
      final l = ctx.lookupLocal(node.name);
      if (l != null) {
        ctx.localsReferencedFromClosure.add(l);
        ctx.closedFrames.add(l.frameIndex!);
      }
    }
    node.visitChildren(this);
  }

}

class PrescanContext with ScopeContext {
  PrescanContext();

  var inClosure = false;
  List<Variable> localsReferencedFromClosure = [];
  Set<int> closedFrames = {};

  @override
  int pushOp(DbcOp op, int length) {
    return 0;
  }
}