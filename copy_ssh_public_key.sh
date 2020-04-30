#!/bin/bash
# bash copy_ssh_public_key.sh 192.168.1.1 192.168.1.2
# 

tempfile=$(mktemp -t temp.XXXXXX)
cat > $tempfile<<EOF
#!/usr/bin/expect

set username root
set password Letmein123
set host [lindex \$argv 0]

spawn ssh-copy-id -i /root/.ssh/id_rsa.pub \$username@\$host
expect {
    "(yes/no)?"
    {send "yes\n";exp_continue}
    "*?assword:"
    {send "\$password\n"}
}
interact
EOF
chmod +x $tempfile

while [ "$#" -ge "1" ];do
    host=$1
    $tempfile $host > /dev/null 2>&1
    shift
done

rm -f $tempfile
