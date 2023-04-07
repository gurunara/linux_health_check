#!/bin/bash

# make seperators
P=80
S=$(printf '*%.s' {1..80})
D=$(printf -- '-%.s' {1..80})

function printTitleBox () {
  echo "$S"

  while [ $# -ne 0 ]
  do
    title=$1
    n=$((P / 2 - ${#title} / 2))
    m=$((P - n - ${#title}))

    printf "%-${n}s" "**"
    printf "$title"
    printf "%+${m}s\n" "**"
    shift
  done

  echo "$S"
}

# only print the header of output via pipeline
function printHeaderOnly {
    IFS= read -r header
    printf '%s\n' "$header"
    echo "$D"
    "$@"
}

# get date
NOW=$(date +"%Y-%m-%d")

# create output file name
OUTPUT=$(basename -s .sh $0)
OUTPUT=$(dirname $0)"/${OUTPUT}.$(hostname).log"
if ! [ -f $OUTPUT ]
then
  touch $OUTPUT
fi

# Assign the fd 3 to $OUTPUT file
exec 3> $OUTPUT

printTitleBox "System Info for $(hostname) at ${NOW}" "(Updated by Keewoong Ahn on April 3, 2023)" >&3

echo "" >&3
printTitleBox "Operating System Info" >&3
hostnamectl >&3

echo "" >&3
printTitleBox "NTP and time configuration" >&3
timedatectl >&3

#uncomment if you run this script on a server for the first time
#echo "" >&3
#printTitleBox "Diplay information about the CPU architecture" >&3
#lscpu | grep -i -v "flags" >&3

echo "" >&3
printTitleBox "Amount Of Free And Used Memory"  >&3
echo -e "CPU Usage:\t"`cat /proc/stat | awk '/cpu/{printf("%.2f%\n"), ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}' | head -1` >&3
echo -e "Memory Usage:\t"`free | awk '/Mem/{printf("%.2f%"), $3/$2*100}'` >&3
echo -e "Swap Usage:\t"`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}'` >&3
echo "$D" >&3
lsmem | tail -3 >&3
echo "$D" >&3
free -h >&3
#printf "%+${P}s\n" "(unit: mib)" >&3
#vmstat -S m 3 5 >&3

echo "" >&3
printTitleBox "File System Disk Space Usage" >&3
df -hT -x tmpfs -x devtmpfs -x iso9660 -x nfs | printHeaderOnly sort -nr -k 6 >&3
echo "$D" >&3
df -hT --total -x tmpfs -x devtmpfs -x iso9660 -x nfs | tail -1 >&3

echo "" >&3
printTitleBox "Zombie Process Check" >&3
top -bn 1 | grep zombie >&3
ps -elf | grep defunct | grep -v grep >&3

echo "" >&3
printTitleBox "Top 5 Memory Eating Process" >&3
ps -eo user,pid,ppid,%mem,%cpu,stat,start,time,comm --sort=-%mem | egrep -v top | head -6 >&3

echo "" >&3
printTitleBox "Top 5 CPU Eating Process" >&3
ps -eo user,pid,ppid,%mem,%cpu,stat,start,time,comm --sort=-%cpu | egrep -v top | head -6 >&3

echo "" >&3
#check the status of Jeus which is the famouse WAS solution in Korean
printTitleBox "Jeus and Web2be Process Monitoring" >&3
su - pmmhadm -c "wsadmin -C si | tail -9" >&3
echo "+-------+---------+-----+-----+-----+------------+--------+-----------+--------+" >&3
su - pmmhadm -c "jeusadmin -host 58.54.160.110:9936 -u administrator -p jeusadmin si | tail -37 | grep -i running" >&3
echo "+-------+---------+-----+-----+-----+------------+--------+-----------+--------+" >&3

#check the status of Weblogc which is the popular WAS solution over the world
#printTitleBox "Weblogic and OHS Process Monitoring" >&3
#su - weblogic -c "/usr/local/weblogic/12.1.3/domains/scpuser_domain/status.sh | tail -7" >&3
#su - webtier -c "/usr/local/webtier/12.2.1.4/domains/scpuser_domain/status.sh | head -11 | tail -4" >&3

#check the status of background processes and listener of Oracle database
#printTitleBox "Orace Process and Instances Monitoring" >&3
#ps -elf | grep -P "PID|_pmon_|_smon_|_dbw0_|_ckpt_|_lgwr_" | grep -v "grep" | printHeaderOnly cat >&3
#echo "$D" >&3
#su - oracle -c "lsnrctl status" >&3

echo "" >&3
printTitleBox "User Login History(Recent 5)" >&3
last -5 -F >&3

echo "" >&3
printTitleBox "Users Failed to log in" >&3
lastb -5 -F >&3

echo "" >&3
printTitleBox "Diagnostic Message" >&3
dmesg -T -l emerg,alert,crit,err |  tail -n 20 >&3

exec 3>&-
