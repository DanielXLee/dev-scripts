# Linux Port 的使用总结

- 查看被打开的端口
  可以通过 `netstat -anp` 来查看哪些端口被打开。
  >**注**：加参数 `-n` 会将应用程序转为端口显示，即数字格式的地址，如：`nfs->2049`, `ftp->21`，因此可以开启两个终端，一一对应一下程序所对应的端口号

- 查看某个端口上的应用
  可以通过 `lsof -i:$PORT` 查看应用该端口的程序(`$PORT` 指对应的端口号), 或者你也可以查看文件`/etc/services`, 从里面可以找出端口所对应的服务.
  >**注**：有些端口通过 `netstat` 查不出来，更可靠的方法是 `sudo nmap -sT -O localhost`

- 关闭某个端口
  若要关闭某个端口，有两种方式可以选择:

  1. 使用 `iptables` 工具
      通过iptables工具将该端口禁掉，如:

      ```bash
      sudo iptables -A INPUT -p tcp --dport $PORT -j DROP
      sudo iptables -A OUTPUT -p tcp --dport $PORT -j DROP
      ```

  2. 关闭对应的应用程序
      关掉对应的应用程序，则端口就自然关闭了，如: `kill -9 $PID (PID：进程号)`, 通过 `netstat` 可以查找具体应用的进程号, 例如要关闭某一个 `ssh` 进程
      通过 `netstat -anp | grep ssh` 查找到进程号
      有显示: `tcp        0      0 9.30.45.242:56034       9.30.116.174:22         ESTABLISHED 32494/ssh`
      使用系统命令`kill` 杀死找到的进程: `kill -9 7546`
