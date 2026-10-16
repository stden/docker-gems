---
name: crossplane-troubleshooting
description: >-
  Use when a Crossplane package, provider, composite resource, or managed resource
  is not healthy, not synced, or not ready. Also use when one of them is stuck in
  deletion, or when the user asks why Crossplane does not create a cloud resource.
  The skill gives the commands to find the cause, and the known causes with their
  fixes.
---

# Find why Crossplane does not work

Run the commands in the `stden/crossplane` toolbox. The `crossplane-install` skill shows how
to start it.

## Look first

```sh
kubectl get providers.pkg.crossplane.io,providerrevisions.pkg.crossplane.io
kubectl get functions.pkg.crossplane.io,configurations.pkg.crossplane.io
kubectl get managed -A                    # managed resources: SYNCED and READY
crossplane resource trace <kind>/<name> -n <namespace> -o wide
kubectl describe <kind>/<name> -n <namespace>
kubectl -n crossplane-system get events --sort-by=.lastTimestamp | tail -20
kubectl -n crossplane-system get pods
kubectl -n crossplane-system logs <provider-pod>
```

The `managed` category comes from the provider CRDs, so `kubectl get managed` works only
after you install a provider. `SYNCED False` means that the provider cannot apply the
resource. The condition message gives the error from the cloud API. `READY False` with
`SYNCED True` means that the cloud API still creates the resource.

## Known causes

| Symptom | Cause | Fix |
| --- | --- | --- |
| No provider is healthy: `node xpkg.crossplane.io/... already exists` | Two providers have the same package, for example a family provider that has a different name from the dependency. | Name the family provider `crossplane-contrib-provider-family-aws`. Delete the extra copy. |
| There is no pod, and the events show `violates PodSecurity` | The pods do not meet the restricted level. | Use `crossplane/kubernetes/helm-values.yaml`, and a `DeploymentRuntimeConfig` for each provider. |
| `no matches for kind "ClusterProviderConfig"` | The provider that owns the type is not healthy yet. | Run `kubectl wait provider.pkg.crossplane.io --all --for=condition=Healthy`. Then apply again. |
| `SYNCED False` with an AWS access error | The provider service account has no IAM role, or an action is missing from the role. | Run `aws eks list-pod-identity-associations --cluster-name <name>`. Fix the role. Then restart the provider pod. |
| A composite resource has no resources | The Composition does not match, or a function failed. | Run `crossplane resource trace` and `kubectl get functions.pkg.crossplane.io`. Render the Composition locally. |
| A managed resource stays in deletion | The provider does not exist any more, so nothing removes the finalizer. | Install the provider again. Let it delete the resource. Delete managed resources before providers. |

## Rules

- Do not remove a finalizer by hand without the consent of the user. The cloud resource
  then stays and costs money.
- After a fix, check `SYNCED` and `READY` again with `crossplane resource trace`.
