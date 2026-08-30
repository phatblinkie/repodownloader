#!/bin/bash
VERSION=1.1.1
echo "VERSION: $VERSION - RHEL 8 only"
sleep 2

if [ $UID != "0" ]; then
    echo "run as root user only"
    exit 1
fi

df -h
echo ""
echo "!!!"
echo "make sure that / has at least 4-6 GB of free space and exit via Ctrl+C if not"
echo "!!!"
sleep 8

# ---------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------
rhel="8"
list_file="all-rpms-rhel${rhel}.txt"
repo_dir="/OGSRepo/rhel${rhel}"
fdte=$(date +%B%Y)
dte=$(date)

# ---------------------------------------------------------------
# Dynamic entitlement certificate detection
# ---------------------------------------------------------------
CERT=$(ls /etc/pki/entitlement/*.pem 2>/dev/null | grep -v -- '-key.pem' | head -1)
KEY=$(ls /etc/pki/entitlement/*-key.pem 2>/dev/null | head -1)

if [[ -z "$CERT" || -z "$KEY" ]]; then
    echo "ERROR: No entitlement certificates found in /etc/pki/entitlement/"
    echo "Register and subscribe the system first (subscription-manager)."
    exit 1
fi

echo "Using certificate : $CERT"
echo "Using key         : $KEY"
echo ""

# ---------------------------------------------------------------
# Helper: download with minimum number of chunks
# ---------------------------------------------------------------
download_with_min_chunks() {
    local list_file="$1"
    local repo_dir="$2"
    local releasever="$3"
    local enablerepos="$4"

    if [[ ! -f "$list_file" ]]; then
        echo "ERROR: $list_file does not exist"
        exit 1
    fi

    echo "=== RHEL ${releasever}: calculating optimal chunk size ==="

    local available=$(( $(getconf ARG_MAX) - $(env | wc -c) - 8192 ))
    local fixed_cmd="yumdownloader --resolve --alldeps --downloadonly --releasever=${releasever} --setopt=module_platform_id=platform:el${releasever} --disablerepo=* ${enablerepos} --destdir ${repo_dir} "
    local fixed_len=${#fixed_cmd}
    local pkg_space=$(( available - fixed_len ))

    if [[ $pkg_space -lt 10000 ]]; then
        echo "ERROR: almost no space left for packages"
        exit 1
    fi

    local total_pkg_bytes=$(wc -c < "$list_file")
    echo "Package list size      : $total_pkg_bytes bytes"
    echo "Space available for pkgs: $pkg_space bytes"

    local chunks=$(( (total_pkg_bytes + pkg_space - 1) / pkg_space ))
    [[ $chunks -lt 1 ]] && chunks=1
    echo "Will split into $chunks chunk(s)"

    mapfile -t all_pkgs < "$list_file"
    local total=${#all_pkgs[@]}
    local chunk_size=$(( (total + chunks - 1) / chunks ))

    for ((i=0; i<chunks; i++)); do
        local start=$(( i * chunk_size ))
        local end=$(( start + chunk_size - 1 ))
        [[ $end -ge $total ]] && end=$(( total - 1 ))

        local chunk=( "${all_pkgs[@]:$start:$((end - start + 1))}" )
        echo -e "\n--- Chunk $((i+1))/$chunks  (${#chunk[@]} packages) ---"

        yumdownloader --resolve --alldeps --downloadonly \
            --releasever="${releasever}" \
            --setopt=module_platform_id=platform:el${releasever} \
            --disablerepo=* \
            ${enablerepos} \
            --destdir "${repo_dir}" \
            "${chunk[@]}"
    done
}

# ---------------------------------------------------------------
# Create directories
# ---------------------------------------------------------------
mkdir -p "$repo_dir"

# ---------------------------------------------------------------
# Create temporary custom repository file
# ---------------------------------------------------------------
echo "Creating custom repository file /etc/yum.repos.d/rhel${rhel}-custom.repo"

cat > /etc/yum.repos.d/rhel${rhel}-custom.repo <<EOF
[custom-rhel-${rhel}-for-x86_64-appstream-rpms]
name = Red Hat Enterprise Linux ${rhel} for x86_64 - AppStream (RPMs)
baseurl = https://cdn.redhat.com/content/dist/rhel${rhel}/${rhel}/x86_64/appstream/os
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
sslverify = 1
sslcacert = /etc/rhsm/ca/redhat-uep.pem
sslclientkey = ${KEY}
sslclientcert = ${CERT}
sslverifystatus = 1
metadata_expire = 86400
enabled_metadata = 1

[custom-rhel-${rhel}-for-x86_64-baseos-rpms]
name = Red Hat Enterprise Linux ${rhel} for x86_64 - BaseOS (RPMs)
baseurl = https://cdn.redhat.com/content/dist/rhel${rhel}/${rhel}/x86_64/baseos/os
enabled = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
sslverify = 1
sslcacert = /etc/rhsm/ca/redhat-uep.pem
sslclientkey = ${KEY}
sslclientcert = ${CERT}
sslverifystatus = 1
metadata_expire = 86400
enabled_metadata = 1
EOF

echo "Cleaning yum/dnf cache"
#yum clean all

echo "Ready to download. This will take a while..."
sleep 3

# ---------------------------------------------------------------
# Download
# ---------------------------------------------------------------
download_with_min_chunks \
    "$list_file" \
    "$repo_dir" \
    "$rhel" \
    "--enablerepo=custom-rhel-${rhel}-for-x86_64-baseos-rpms --enablerepo=custom-rhel-${rhel}-for-x86_64-appstream-rpms"

if [ "$?" -ne "0" ]
then
        echo "an error occurred, make sure all files in the list are actually on the remote repository"
        exit 1
fi

# ---------------------------------------------------------------
# Create repository and tarball
# ---------------------------------------------------------------
echo ""
echo "Download finished at $dte – creating repository and tarball"

cd "$repo_dir"

echo "Cleaning old package versions..."
repomanage --keep=1 --old . 2>/dev/null | xargs -r rm -f

echo "Creating repository metadata..."
rm -rf .repodata 2>/dev/null || true
createrepo_c -v .

echo "Creating tarball..."
tar -cvzf "/${fdte}rhel${rhel}repo.tar.gz" ./*
chmod 777 "/${fdte}rhel${rhel}repo.tar.gz"


# ---------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------
echo "Removing temporary repo file"
rm -fv /etc/yum.repos.d/rhel${rhel}-custom.repo

echo ""
echo "All finished!"
echo "Your exportable file is:"
echo "/${fdte}rhel${rhel}repo.tar.gz"
echo ""

exit 0
