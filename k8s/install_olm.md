# 在原生kubernetes平台上部署OLM以及OperatorHub

## 安装OLM

### 通过脚本安装OLM

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/install.sh)" -- v0.17.0
```

### 手动安装OLM

```bash
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.17.0/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.17.0/olm.yaml
```

## 安装OperatorHub

> 安装依赖工具 `kubectl`, `kustomize`

1. 配置 Kubeconfig

    具体参见集群的基本信息页面

2. 部署Operatorhub

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/kubernetes-app/operatorhub.io/develop/deploy.sh)" -- prod
    ```
