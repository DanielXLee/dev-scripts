# Migrating go operator api to a new version

For the go operator, migrate api to new version, I summire some steps, hope it helps you.

Use the ODLM as an example

1. Add new api with operator-sdk add api, for ODLM, there are 4 apis

    ```bash
    operator-sdk add api --api-version=operator.ibm.com/v1 --kind=OperandBindInfo
    operator-sdk add api --api-version=operator.ibm.com/v1 --kind=OperandRegistry
    operator-sdk add api --api-version=operator.ibm.com/v1 --kind=OperandRequest
    operator-sdk add api --api-version=operator.ibm.com/v1 --kind=OperandConfig
    ```

    When you are generating the api code, if you encounter the following error, ignore it.
    This time the api code has been generated, just CRD not update, you can follow the step 3 to update the CRDs.

    ```console
    INFO[0049] Running CRD generator.
    github.com/IBM/operand-deployment-lifecycle-manager/pkg/apis/operator/v1:-: CRD for OperandBindInfo.operator.ibm.com has no storage version
    FATA[0051] error generating CRDs from APIs in pkg/apis: error generating CRD manifests: error running CRD generator: not all generators ran successfully
    ```

1. Copy `v1alpha1` api code logic into `v1` api

    This step is very simple, just copy all the code logic from the old api `v1alpha1` into the `v1`, and then run command `operator-sdk generate k8s` to update the deep copy files.
    >Notes: To support backward compatibility, we need served 2 api versions in our CRD, see step 3, so don't delete the old api `v1alpha1` form code, the `operator-sdk` required the old api version when generate multiple versions CRDs

1. Add `storageversion` marker comments in the `v1` api

    Add marker comments `// +kubebuilder:storageversion` in your new `v1` api, and then run command `operator-sdk generate crds` to re-generate the crds

    Example, for ODLM OperandConfig, add the [marker comments for ODLM OperandConfig](https://github.com/IBM/operand-deployment-lifecycle-manager/blob/e98cc5d0e37f045b2486f0178521ad1f1404c172/pkg/apis/operator/v1/operandconfig_types.go#L71):

    ```go
    // OperandConfig is the Schema for the operandconfigs API
    // +k8s:openapi-gen=true
    // +kubebuilder:subresource:status
    // +kubebuilder:storageversion
    ...
    type OperandConfig struct {
    ```

    After the CRDs re-generated, you can find 2 api versions under the CRD `spec.versions`, example:

    ```yaml
    apiVersion: apiextensions.k8s.io/v1beta1
    kind: CustomResourceDefinition
    metadata:
      name: operandconfigs.operator.ibm.com
    spec:
      ...
      versions:
      - name: v1
        served: true
        storage: true
      - name: v1alpha1
        served: true
        storage: false
    ```

    More detail Storage Versions info follow the [kubebuilder book](https://book.kubebuilder.io/multiversion-tutorial/api-changes.html#storage-versions)

1. Update the api imports and references in the all contollers

    This step need search all the controllers code, find all the `v1alpha1` api import and replace them to `v1`, find all the `v1alpha1` api references and replace them to `v1`

1. Last step, run operator local test

    Quick test use the `operator-sdk run --local --watch-namespace=${you_ns}`, after local test no problem, you can re-generate csv(`operator-sdk generate csv --csv-version ${CSV_VERSION} --update-crds`) and upload it to quay.io.

Until here, the migrate work done, following is the ODLM new api code struct

```console
.
├── addtoscheme_operator_v1.go
├── addtoscheme_operator_v1alpha1.go
├── apis.go
└── operator
    ├── group.go
    ├── v1
    │   ├── doc.go
    │   ├── operandbindinfo_types.go
    │   ├── operandconfig_types.go
    │   ├── operandregistry_types.go
    │   ├── operandrequest_types.go
    │   ├── register.go
    │   └── zz_generated.deepcopy.go
    └── v1alpha1
        ├── doc.go
        ├── operandconfig_types.go
        ├── operandregistry_types.go
        ├── operandrequest_types.go
        ├── register.go
        └── zz_generated.deepcopy.go
```

Some references docs:

[1] [Migrating Existing Kubernetes APIs](https://github.com/operator-framework/operator-sdk/blob/master/doc/user/migrating-existing-apis.md)

[2] [Versions in CustomResourceDefinitions](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definition-versioning)

[3] [Example ODLM API Migrate PR](https://github.com/IBM/operand-deployment-lifecycle-manager/pull/371)
