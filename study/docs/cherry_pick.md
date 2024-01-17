# Cherry pick 2 commit to new fock branch

将clusternet 主分支上的2个commit提交到新的fock分支上

```shell
rm -rf clusternet
git clone git@github.com:DanielXLee/clusternet.git
cd clusternet
git remote add upstream git@github.com:clusternet/clusternet.git
git pull upstream
git checkout v0.3.0
git checkout -b release-0.3
git cherry-pick 386dbf1 50b2ba0 ab20436
git tag -a v0.3.1 -m v0.3.1
git push origin v0.3.1
```
