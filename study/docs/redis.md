# Redis Cluster 扩容收缩

## 集群扩容

1. 添加master节点

    ```bash
    # 注意语法，一个新节点IP:端口 空格 一个旧节点IP:端口，注意点是：
    # 1.不能多个新节点一次性添加
    # 2.新节点后是旧节点
    # 3.如果设置--cluster-slave，新节点挂在旧节点下的一个从节点
    # 4.如果设置 --cluster-master-id <arg> ，arg设置旧节点的id，具体可以使用cluster nodes查看各个节点的id
    # add-node new_host:new_port existing_host:existing_port  --cluster-slave  --cluster-master-id <arg>
    # 此时 192.168.8.124:7979 为一个新的master节点
    redis-cli --cluster add-node 192.168.8.124:7979 192.168.8.124:7379
    ```

<!-- 1. 添加从节点

    ```bash
    # 添加到从节点 此时192.168.8.124:8079 为 192.168.8.124:7979 的从节点
    redis-cli --cluster add-node 192.168.8.124:8079 192.168.8.124:7979 --cluster-slave
    ```

    这里是将节点加入了集群中，但是并没有分配slot，所以这个节点并没有真正的开始分担集群工作，下一步，为master节点分配slot。 -->

1. 分配slot

    ```bash
    # 分配slot
    redis-cli --cluster reshard 192.168.8.124:7979 --cluster-from 2846540d8284538096f111a8ce7cf01c50199237,e0a9c3e60eeb951a154d003b9b28bbdc0be67d5b,692dec0ccd6bdf68ef5d97f145ecfa6d6bca6132 --cluster-to 46f0b68b3f605b3369d3843a89a2b4a164ed21e8 --cluster-slots 1024
    # --cluster-from：表示slot目前所在的节点的node ID，多个ID用逗号分隔
    # --cluster-to：表示需要新分配节点的node ID（貌似每次只能分配一个）
    # --cluster-slots：分配的slot数量
    ```

1. 添加slave节点

    ```bash
    # 添加slave节点
    redis-cli --cluster add-node 127.0.0.1:6386 127.0.0.1:6385 --cluster-slave --cluster-master-id 46f0b68b3f605b3369d3843a89a2b4a164ed21e8
    # add-node: 后面的分别跟着新加入的slave和slave对应的master
    # cluster-slave：表示加入的是slave节点
    # --cluster-master-id：表示slave对应的master的node ID
    ```

## 集群收缩 Cluster shrinkage

1. 收缩集群

    下线节点127.0.0.1:6385（master）/127.0.0.1:6386（slave）

1. 首先删除master对应的slave

    ```bash
    redis-cli --cluster del-node 127.0.0.1:6386 530cf27337c1141ed12268f55ba06c15ca8494fc
    # del-node后面跟着slave节点的 ip:port 和node ID
    ```

1. 清空master的slot

    ```bash
    redis-cli --cluster reshard 127.0.0.1:6385 --cluster-from 46f0b68b3f605b3369d3843a89a2b4a164ed21e8 --cluster-to 2846540d8284538096f111a8ce7cf01c50199237 --cluster-slots 1024 --cluster-yes
    # reshard子命令前面已经介绍过了，这里需要注意的一点是，由于我们的集群一共有四个主节点，而每次reshard只能写一个目的节点，因此以上命令需要执行三次#（--cluster-to对应不同的目的节点）。
    #--cluster-yes：不回显需要迁移的slot，直接迁移。
    ```

1. 下线（删除）节点

    ```bash
    redis-cli --cluster del-node 127.0.0.1:6385 46f0b68b3f605b3369d3843a89a2b4a164ed21e8
    ```

至此就是redis cluster 简单扩容与收缩的操作过程

## 常见问题处理

1. 出现如下错误`slots in importing`

    ```bash
    [WARNING] Node 172.16.0.248:6379 has slots in importing state 5461.
    [WARNING] The following slots are open: 5461.
    ```

    首先可以通过`check` 命令检查详情

    ```bash
    redis-cli --cluster check 172.16.0.248:6379 -a Opstree@1234
    ```

    然后通过`fix`命令解决出问题的slot

    ```bash
    redis-cli --cluster fix 172.16.0.248:6379 -a Opstree@1234
    ```
