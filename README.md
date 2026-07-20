# repodownloader
shortened repo downloader. only downloads rhel 8 and rhel 9 files in a txt file, including dependencies

to run, clone repo
put the rpms you want downloaded in the all-rpms-rhel8.txt or all-rpms-rhel9.txt files
# to get the list off your host you can run
rpm -qa --queryformat '%{NAME}.%{ARCH}\n'|sort > all-rpms-rhel8.txt

to run
sudo su - (become root one way or another)
make sure you have have yumdownloader installed

git clone https://github.com/phatblinkie/repodownloader.git
cd repodownloader
(if first time gather rpm lists)
rpm -qa --queryformat '%{NAME}.%{ARCH}\n'|sort > all-rpms-rhel9.txt

#do the same for rhel8 hosts, into the  all-rpms-rhel8.txt file
./rhel8_and_rhel9_repomake.sh
let it roll, it will take a while

