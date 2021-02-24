# Push image to new namespace on OCP 4.x

1. Create new namespace

    ```console
    # export NEW_NS=${NEW_NS}
    # oc create namespace $NEW_NS
    namespace/${NEW_NS} created
    ```

2. Add role for user

    ```console
    # oc policy add-role-to-user system:image-puller system:serviceaccount:kube-system:default --namespace=$NEW_NS
    clusterrole.rbac.authorization.k8s.io/system:image-puller added: "system:serviceaccount:kube-system:default"
    ```

3. Create service account

    ```console
    # oc -n ${NEW_NS} create sa image-bot
    serviceaccount/image-bot created
    ```

4. Add user to service account

    ```console
    # oc -n ${NEW_NS} policy add-role-to-user registry-editor system:serviceaccount:${NEW_NS}:image-bot
    clusterrole.rbac.authorization.k8s.io/registry-editor added: "system:serviceaccount:${NEW_NS}:image-bot"
    ```
  
5. Setup defaultRoute as true

    ```console
    # oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
    config.imageregistry.operator.openshift.io/cluster patched
    ```

6. Export required environment variables

    ```console
    # export DOCKER_USERNAME=image-bot
    # export DOCKER_PASSWORD="$(oc -n ${NEW_NS} serviceaccounts get-token image-bot)"
    # export DOCKER_REGISTRY="$(kubectl get route -n openshift-image-registry default-route -o jsonpath='{.spec.host}')"
    ```

7. Create ca for docker

    ```console
    # mkdir -p /etc/docker/certs.d/$DOCKER_REGISTRY
    # echo | openssl s_client -showcerts -servername $DOCKER_REGISTRY -connect $DOCKER_REGISTRY:443 2>/dev/null | openssl x509 -inform pem > /etc/docker/certs.d/$DOCKER_REGISTRY/ca.crt
    ```

8. Docker login and push image

    ```console
    # docker login -u $DOCKER_USERNAME -p "$DOCKER_PASSWORD" $DOCKER_REGISTRY
    WARNING! Using --password via the CLI is insecure. Use --password-stdin.
    WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
    Configure a credential helper to remove this warning. See
    https://docs.docker.com/engine/reference/commandline/login/#credentials-store

    Login Succeeded
    # docker push $DOCKER_REGISTRY/${NEW_NS}/alpine:latest
    The push refers to repository [default-route-openshift-image-registry.apps.nogs.os.fyre.ibm.com/${NEW_NS}/alpine]
    beee9f30bc1f: Pushed
    latest: digest: sha256:cb8a924afdf0229ef7515d9e5b3024e23b3eb03ddbba287f4a19c6ac90b8d221 size: 528
    ```
