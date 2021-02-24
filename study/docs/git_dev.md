# git 常用的一些操作

## 为fork的项目添加上游源

1. 输出当前repo的remote源

    ```bash
    # git remote -v
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (fetch)
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (push)
    ```

    使用`zsh`

    ```zsh
    # grv
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (fetch)
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (push)
    ```

1. 增加上游源

    ```bash
    # git remote add upstream https://github.com/operator-framework/operator-lifecycle-manager.git
    # git remote -v
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (fetch)
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (push)
    upstream        https://github.com/operator-framework/operator-lifecycle-manager.git (fetch)
    upstream        https://github.com/operator-framework/operator-lifecycle-manager.git (push)
    ```

    使用`zsh`

    ```zsh
    # gra upstream https://github.com/operator-framework/operator-lifecycle-manager.git
    # grv
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (fetch)
    origin  https://github.com/DanielXLee/operator-lifecycle-manager.git (push)
    upstream        https://github.com/operator-framework/operator-lifecycle-manager.git (fetch)
    upstream        https://github.com/operator-framework/operator-lifecycle-manager.git (push)
    ```

## 同步上游repo的代码

1. 拉取最新的上游源码

    ```bash
    # git fetch upstream
    ```

    使用`zsh`

    ```zsh
    # gf upstream
    ```

1. 将本地源码切换到主分支

    ```bash
    # git checkout master
    ```

    使用`zsh`

    ```zsh
    # gcm
    ```

1. 将上游源码主分支的源码merge到本地主分支

    ```bash
    # git merge upstream/master
    ```

    使用`zsh`

    ```zsh
    # gmum
    ```

1. 将本地同步后的源码push到远程github

    ```bash
    # git push origin master
    ```

    使用`zsh`

    ```zsh
    # ggpush
    ```

如果本地使用了`zsh`, 可以配置更简单的一键同步

```bash
echo "alias gs='gf upstream && gcm && gmum && ggpush'" >> ~/.zshrc
source ~/.zshrc
```

更多`git`和`github`相关的使用可以参考[Github Docs](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/syncing-a-fork)

## 其它的问题

1. 如果开发机器的默认的 ssh 端口被修改了，为了免密 push code，我们需要在`~/.ssh/config`中添加一些配置

    ```bash
    Host git.woa.com
    User git
    HostName git.woa.com
    Port 22
    PreferredAuthentications publickey
    IdentityFile /root/.ssh/id_rsa
    Host github.com
    User git
    Hostname github.com
    Port 22
    PreferredAuthentications publickey
    IdentityFile /root/.ssh/id_rsa
    ```

1. 克隆带有子模块的项目

    ```bash
    git clone --recurse-submodules <your-project>
    ```

    使用`zsh`

    ```zsh
    gcl <your-project>
    ```
