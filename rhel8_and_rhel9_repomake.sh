#!/bin/bash
VERSION=1.0.0
echo "VERSION: $VERSION"
sleep 2

if [ $UID != "0" ]
then
	echo run as root user only
	exit 1
fi

df -h
echo ""
echo "!!!"
echo "make sure that / has at least 8gb of space left and exit via Ctrl + C if not"
echo "!!!"
sleep 10

#setup some vars
rhel8="8"
rhel9="9"
list8="/root/all-rpms-rhel${rhel8}.txt"
rpms8=$(cat $list8)
count8=$(cat all-rpms-rhel8.txt |wc -l)

list9="/root/all-rpms-rhel${rhel9}.txt"
rpms9=$(cat $list9)
count9=$(cat all-rpms-rhel9.txt |wc -l)

chk=0
dte=$(date)
fdte=$(date +%B%Y)

repo8="/OGSRepo/rhel${rhel8}"
repo9="/OGSRepo/rhel${rhel9}"

echo "Creating directories and custom repo files"
if  ! [[ -d $repo8 ]]; then
	mkdir -p $repo8
	echo "Created directory $repo8"
fi
if  ! [[ -d $repo9 ]]; then
        mkdir -p $repo9
	echo "Created Directory $repo9"
fi

#create the needed repo files temporarily
#clean up after its all done so as not to interfere with the systems normal repositories
for rhelver in `seq 8 9`
do
echo "Creating custom repository file /etc/yum.repos.d/rhel$rhelver-custom.repo"
echo -e "
[custom-rhel-$rhelver-for-x86_64-appstream-rpms]
name = Red Hat Enterprise Linux $rhelver for x86_64 - AppStream (RPMs)
baseurl = https://cdn.redhat.com/content/dist/rhel$rhelver/$rhelver/x86_64/appstream/os
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
sslverify = 1
sslcacert = /etc/rhsm/ca/redhat-uep.pem
sslclientkey = /etc/pki/entitlement/3726693944746684616-key.pem
sslclientcert = /etc/pki/entitlement/3726693944746684616.pem
sslverifystatus = 1
metadata_expire = 86400
enabled_metadata = 1

[custom-rhel-$rhelver-for-x86_64-baseos-rpms]
name = Red Hat Enterprise Linux $rhelver for x86_64 - BaseOS (RPMs)
baseurl = https://cdn.redhat.com/content/dist/rhel$rhelver/$rhelver/x86_64/baseos/os
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
sslverify = 1
sslcacert = /etc/rhsm/ca/redhat-uep.pem
sslclientkey = /etc/pki/entitlement/3726693944746684616-key.pem
sslclientcert = /etc/pki/entitlement/3726693944746684616.pem
sslverifystatus = 1
metadata_expire = 86400
enabled_metadata = 1
" > /etc/yum.repos.d/rhel$rhelver-custom.repo
done

echo "Cleaning up old repo meta data first"
yum clean all

echo "Ready to Download the data. This will take some time, grab a coffee"
sleep 5
#we have the source counts so have some idea how far along things are
#setup start of counters
count8done=0
count9done=0
for i in $rpms8; do
	echo -e "\n\n RHEL8: working on entry $count8done of $count8 : $i \n"
        yumdownloader --resolve --alldeps --downloadonly --releasever=${rhel8} --setopt=module_platform_id=platform:el${rhel8} --disablerepo=* --enablerepo=custom-rhel-8-for-x86_64-baseos-rpms --enablerepo=custom-rhel-8-for-x86_64-appstream-rpms --destdir $repo8 $i
	((count8done++))
done

for j in $rpms9; do
	echo -e "\n\n RHEL9: working on entry $count9done of $count9 : $j \n"
        yumdownloader --resolve --alldeps --downloadonly --releasever=${rhel9} --setopt=module_platform_id=platform:el${rhel9} --disablerepo=* --enablerepo=custom-rhel-9-for-x86_64-baseos-rpms --enablerepo=custom-rhel-9-for-x86_64-appstream-rpms --destdir $repo9 $j
	((count9done++))
done

echo "repo synced completed at $dte now creating tar file of repository"

cd $repo8
repomanage --keep=1 --old $repo8 | xargs rm -f
createrepo -v $repo8
tar -cvzf /${fdte}rhel${rhel8}repo.tar.gz ./*
chmod 777 /${fdte}rhel${rhel8}repo.tar.gz
echo "repo $repo8 has been created"



cd $repo9
repomanage --keep=1 --old $repo9 | xargs rm -f
createrepo -v $repo9
tar -cvzf /${fdte}rhel${rhel9}repo.tar.gz ./*
chmod 777 /${fdte}rhel${rhel9}repo.tar.gz
echo "repo $repo9 has been created"

echo "Cleaning up custom repository files"
for rhelver in `seq 8 9`
do
echo "Removing custom repository file /etc/yum.repos.d/rhel$rhelver-custom.repo"
rm -fv /etc/yum.repos.d/rhel$rhelver-custom.repo
done

echo "All finished, have a nice day :)"
echo "Your exportable files are"
echo -e "\n/${fdte}rhel${rhel8}repo.tar.gz\n/${fdte}rhel${rhel9}repo.tar.gz"
exit 0
