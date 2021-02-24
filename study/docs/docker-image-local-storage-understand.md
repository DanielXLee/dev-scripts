# Docker Image 本地存储的基本知识

显示docker digest和完整的docker image ID

```bash
docker images --no-trunc --digests
REPOSITORY          TAG                 DIGEST                                                                    IMAGE ID                                                                  CREATED             SIZE
mysql               3.12                <none>                                                                    sha256:cfcf9b5e1173184505751bee850eac12b50b2b526a36f74756dd4edf946adf82   23 hours ago        39.7MB
alpine              3.12                sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321   sha256:a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e   4 months ago        5.57MB
```

```bash
image
└── overlay2
    ├── distribution
    │   ├── diffid-by-digest
    │   │   └── sha256
    │   └── v2metadata-by-diffid
    │       └── sha256
    ├── imagedb
    │   ├── content
    │   │   └── sha256 #1 存储所有local的image，每个image对应一个文件夹
    │   └── metadata
    │       └── sha256
    ├── layerdb
    │   ├── mounts
    │   ├── sha256 #2 存储每个image对应的layer，对于有parent的layer，每个文件夹下会有一个parent的文件，里面有parent layer的ID
    │   │   ├── 10babf572aa1cd4bd0a4118e092b4230c3bd39ffad5d8db275ac394c5527c34c
    │   │   ├── 3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b
    │   │   └── 50644c29ef5a27c9a40c393a73ece2479de78325cae7d762ef3cdc19bf42dd0a
    │   └── tmp
    └── repositories.json
```

计算 ChainID, 规则如下

```bash
ChainID(A) = DiffID(A)
ChainID(A|B) = Digest(ChainID(A) + " " + DiffID(B))
ChainID(A|B|C) = Digest(ChainID(A|B) + " " + DiffID(C))
```

```json
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b",
      "sha256:95d78f9b379fbc8883375924a5e8b4008f3372f3fe7faaddbe859633d8c023ca"
    ]
  }
```

```bash
ChainID(A) = DiffID(A) = sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b
ChainID(A|B) = Digest(ChainID(A) + " " + DiffID(B))
ChainID(A) = sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b
DiffID(B) = sha256:95d78f9b379fbc8883375924a5e8b4008f3372f3fe7faaddbe859633d8c023ca
//Calculation:
echo -n "sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b sha256:95d78f9b379fbc8883375924a5e8b4008f3372f3fe7faaddbe859633d8c023ca" | sha256sum -
89697eda7a7ec892a2ca18d0ad46e374b5c2150bf5f5a153879d4b27440fd31b  -
```


# 替换 base image

例如我们基于`alpine:3.7`为base image build了一个image `my-alpine:3.7`

```Dockerfile
FROM alpine:3.7
RUN apk -v add --no-cache curl
```

```bash
# docker build -t my-alpine:3.7 .
```

现在我们想把base image换成`alpine:3.12`， 通常的做法是更改`Dockerfile`, 重新build image，下面我们探索一种直接替换base image的方法，不用重新build image

## Step 1: 生成新的 Image JSON 文件

[Image JSON](https://github.com/opencontainers/image-spec/blob/master/config.md#image-json)文件是一个image的配置文件，替换base image我们需要为替换后的image重新生成一个Image JSON

1. 拉取新的base image，并获取新的base image的layerdb id，例如

    ```bash
    # docker pull alpine:3.12
    # docker inspect alpine:3.12 | jq '.[0].RootFS.Layers[0]'
    "sha256:50644c29ef5a27c9a40c393a73ece2479de78325cae7d762ef3cdc19bf42dd0a"
    ```

1. 找到老的image `my-alpine:3.7` 的Image JSON 文件

    Image JSON 文件存放在 `/var/lib/docker/image/overlay2/imagedb/content/sha256/` 目录，文件名字以 image ID 命名，我们可以通过 `docker images --no-trunc` 命令来找到 image 的完整 ID

    ```bash
    # docker images --no-trunc my-alpine:3.7
    REPOSITORY          TAG                 IMAGE ID                                                                  CREATED             SIZE
    my-alpine           3.7                 sha256:d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7   16 minutes ago      5.6MB
    ```

    这里的 `d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7` 就是老 image 的 Image JSON 文件名

1. 创建新的Image JSON文件

    ```bash
    # cd /var/lib/docker/image/overlay2/imagedb/content/sha256
    # cp d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7 d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7-copy
    ```

    打开新的Image JSON文件，替换第一个diff id, 第一个diff id为base image layerdb id
    将`sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b` 替换为 `sha256:50644c29ef5a27c9a40c393a73ece2479de78325cae7d762ef3cdc19bf42dd0a`，更新到下面的文件

    替换前

    ```bash
    # cat d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7-copy | jq '.rootfs'
    {
    "type": "layers",
    "diff_ids": [
        "sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b",
        "sha256:40926ceed598e907a8c5875ff6306da6f562af7b84a49ab935d94f548b1cdfa2"
    ]
    }
    ```

    替换后

    ```bash
    # cat d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7-copy | jq '.rootfs'
    {
    "type": "layers",
    "diff_ids": [
        "sha256:50644c29ef5a27c9a40c393a73ece2479de78325cae7d762ef3cdc19bf42dd0a",
        "sha256:40926ceed598e907a8c5875ff6306da6f562af7b84a49ab935d94f548b1cdfa2"
    ]
    }
    ```

重命名Image JSON文件, Image JSON文件的名字就是image ID

```bash
# sha256sum d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7-copy | awk '{print $1}'
80c1472a2ac92aed8d363e796291774d14a4763397aaa6434eec04d1c9b713a4
# mv d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7-copy 80c1472a2ac92aed8d363e796291774d14a4763397aaa6434eec04d1c9b713a4
```

到这一步，新image的Image JSON文件就创建好了，下一步就是生成新image的layerdb

## Step 2: 生成新image的layerdb

获取老image `my-alpine:3.7` 的layerdb id

```bash
# docker inspect my-alpine:3.7 | jq '.[0].RootFS.Layers'
[
  "sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b",
  "sha256:40926ceed598e907a8c5875ff6306da6f562af7b84a49ab935d94f548b1cdfa2"
]
# echo -n "sha256:3fc64803ca2de7279269048fe2b8b3c73d4536448c87c32375b2639ac168a48b sha256:40926ceed598e907a8c5875ff6306da6f562af7b84a49ab935d94f548b1cdfa2" | sha256sum -
8882f824eaa539f97b120b629e78452615a05c59152a64281d9af6d4d6128448  -
```

生成新image的layerdb id

```bash
# cd /var/lib/docker/image/overlay2/imagedb/content/sha256
# cat 80c1472a2ac92aed8d363e796291774d14a4763397aaa6434eec04d1c9b713a4 | jq '.rootfs.diff_ids'
[
  "sha256:50644c29ef5a27c9a40c393a73ece2479de78325cae7d762ef3cdc19bf42dd0a",
  "sha256:40926ceed598e907a8c5875ff6306da6f562af7b84a49ab935d94f548b1cdfa2"
]
# echo -n "sha256:50644c29ef5a27c9a40c393a73ece2479de78325cae7d762ef3cdc19bf42dd0a sha256:40926ceed598e907a8c5875ff6306da6f562af7b84a49ab935d94f548b1cdfa2" | sha256sum -
e29d21e1ce1026c50813caeb2c801ba9ad354386b79df749963778b95dd3c341  -
```

拷贝老的image layerdb id 目录为新的 image layerdb 目录

```bash
# cd /var/lib/docker/image/overlay2/layerdb/sha256
# cp -r 8882f824eaa539f97b120b629e78452615a05c59152a64281d9af6d4d6128448 e29d21e1ce1026c50813caeb2c801ba9ad354386b79df749963778b95dd3c341
```

更新parent 在新的image layerdb 目录

```bash
cd e29d21e1ce1026c50813caeb2c801ba9ad354386b79df749963778b95dd3c341
# 这里的sha256 id是上面获取到的新的base image的layerdb id
echo "sha256:50644c29ef5a27c9a40c393a73ece2479de78325cae7d762ef3cdc19bf42dd0a" > parent
```

更新image repositories.json，将image `my-alpine` 对应tag `my-alpine:3.7` 的image ID 替换为新的image ID `69078a01a382040c9211dd5962358f0cbff71ac3b3c52edee9323ffe65556732`

更新前

```bash
# cd /var/lib/docker/image/overlay2
# cat repositories.json | jq
{
  "Repositories": {
    "alpine": {
      "alpine:3.12": "sha256:a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e",
      "alpine:3.7": "sha256:6d1ef012b5674ad8a127ecfa9b5e6f5178d171b90ee462846974177fd9bdd39f",
      "alpine@sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321": "sha256:a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e",
      "alpine@sha256:8421d9a84432575381bfabd248f1eb56f3aa21d9d7cd2511583c68c9b7511d10": "sha256:6d1ef012b5674ad8a127ecfa9b5e6f5178d171b90ee462846974177fd9bdd39f"
    },
    "my-alpine": {
      "my-alpine:3.7": "sha256:d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7"
    }
  }
}
```

更新后

```bash
# cd /var/lib/docker/image/overlay2
# cat repositories.json | jq
{
  "Repositories": {
    "alpine": {
      "alpine:3.12": "sha256:a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e",
      "alpine:3.7": "sha256:6d1ef012b5674ad8a127ecfa9b5e6f5178d171b90ee462846974177fd9bdd39f",
      "alpine@sha256:185518070891758909c9f839cf4ca393ee977ac378609f700f60a771a2dfe321": "sha256:a24bb4013296f61e89ba57005a7b3e52274d8edd3ae2077d04395f806b63d83e",
      "alpine@sha256:8421d9a84432575381bfabd248f1eb56f3aa21d9d7cd2511583c68c9b7511d10": "sha256:6d1ef012b5674ad8a127ecfa9b5e6f5178d171b90ee462846974177fd9bdd39f"
    },
    "my-alpine": {
      "my-alpine:3.7": "sha256:80c1472a2ac92aed8d363e796291774d14a4763397aaa6434eec04d1c9b713a4"
    }
  }
}
```

重启docker，查看新的image

```bash
# docker images --no-trunc my-alpine:3.7
REPOSITORY          TAG                 IMAGE ID                                                                  CREATED             SIZE
my-alpine           3.7                 sha256:d0991862e446ee391a9563b910474cb812a5989c556d01ae82954a13e13b01b7   56 minutes ago      5.6MB
# systemctl restart docker
# docker images --no-trunc my-alpine:3.7
REPOSITORY          TAG                 IMAGE ID                                                                  CREATED             SIZE
my-alpine           3.7                 sha256:80c1472a2ac92aed8d363e796291774d14a4763397aaa6434eec04d1c9b713a4   57 minutes ago      6.97MB
# docker run -it sha256:80c1472a2ac92aed8d363e796291774d14a4763397aaa6434eec04d1c9b713a4 sh
/ # curl -h
Usage: curl [options...] <url>
     --abstract-unix-socket <path> Connect via abstract Unix domain socket
     --anyauth       Pick any authentication method
...
```

base image 替换成功


## 找到所有使用的base image 的layerdb
