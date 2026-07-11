# Authorization Evaluation Runtime

`AuthorizationEvaluationRuntime` is a thin wrapper around `AssetExecutionAuthorizationCoordinator.registerExecutionAuthorizationEvaluation`.

It registers `ExecutionAuthorizationEvaluation` records only. Evaluations are copied review metadata and never approve, reject, route, dispatch, schedule, orchestrate, or execute live work.
