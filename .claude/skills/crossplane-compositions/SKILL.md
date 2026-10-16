---
name: crossplane-compositions
description: >-
  Use when the user asks to design a Crossplane API, or to write or change an XRD
  or a Composition. Also use when the user asks to use composition functions such
  as patch-and-transform, or to test a Composition without a cluster with validate
  and render. The skill covers the namespaced composite resources of Crossplane v2.
---

# Write and test XRDs and Compositions

An XRD defines a new API, for example `ImageRepository`. A Composition says which managed
resources Crossplane makes for it. In Crossplane v2, an XRD uses
`apiextensions.crossplane.io/v2` and its composite resources are namespaced by default.
A Composition uses `mode: Pipeline` with composition functions. The smoke test
`crossplane/smoke-test.sh` has a complete example.

## Rules for a good API

- Expose only the fields that are necessary for users. Use `enum` and `required` in the schema.
- Put company settings, for example scan on push, in the Composition, not in the API.
- Version the API (`v1alpha1`, then `v1beta1`). Do not break a served version.

## Test without a cluster

Validate the example against the XRD. A wrong value must fail:

```sh
docker run --rm -v "$PWD":/workspace stden/crossplane:latest \
  crossplane resource validate --error-on-missing-schemas definition.yaml example.yaml
```

Render the managed resources that the Composition makes. Functions run as Docker
containers, so give the toolbox the Docker socket and the host network:

```sh
docker run --rm --network host -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD":/workspace stden/crossplane:latest \
  crossplane composition render example.yaml composition.yaml functions.yaml
```

`functions.yaml` lists the `Function` packages with their versions, for example
`xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:<version>`. The
`metadata.name` of each Function must be the same as the `functionRef.name` in the
Composition. Find the newest version with
`gh api repos/crossplane-contrib/function-patch-and-transform/releases/latest --jq .tag_name`.
Check the rendered resources: the patched fields, the names, and the owner reference.

Convert an XRD to the CRD that Crossplane creates:

```sh
docker run --rm -v "$PWD":/workspace stden/crossplane:latest crossplane xrd convert definition.yaml
```

## Apply

Apply the XRD, the Composition, and the Function objects. Then apply an example:

```sh
kubectl apply -f definition.yaml -f composition.yaml -f functions.yaml
kubectl wait xrd --all --for=condition=Established --timeout=2m
kubectl apply -f example.yaml
crossplane resource trace <kind>/<name> -n <namespace>
```

If you have more than one Composition, put them in a package with the `crossplane-packages`
skill.
