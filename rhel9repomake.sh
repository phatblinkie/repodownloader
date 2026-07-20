#!/bin/bash

if [ $UID != "0" ]
then
	echo run as root user only
	exit 1
fi

df -h
echo ""
echo "!!!"
echo "make sure that / has at least 4gb of space left and exit via Ctrl + C if not"
echo "!!!"
sleep 10
rhel="9"
log="/root/rhel${rhel}repoPull.log"
list="/root/all-rpms-rhel${rhel}.txt"
rpms=$(cat $list)
chk=0
dte=$(date)
fdte=$(date +%B%Y)

if [[ -f $log ]]; then
	echo "host"
else
	touch $log
fi

repo="/OGSRepo/rhel${rhel}"
if  ! [[ -d $repo ]]; then
	mkdir -p $repo
fi
#rm -rvf $repo/*

yum clean all
for i in $rpms; do
        yumdownloader --resolve --alldeps --downloadonly --releasever=${rhel} --setopt=module_platform_id=platform:el${rhel} --disablerepo=* --enablerepo=rhel-${rhel}-for-x86_64-baseos-rpms --enablerepo=rhel-${rhel}-for-x86_64-appstream-rpms --destdir $repo $i

done
echo "repo synced completed at $dte now creating tar file of repository"

cd $repo
repomanage --keep=1 --old $repo | xargs rm -f
createrepo -v $repo
tar -cvzf /${fdte}rhel${rhel}repo.tar.gz ./*
chmod 777 /${fdte}rhel${rhel}repo.tar.gz

echo "repo $repo has been created"
exit 0
