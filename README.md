# RHEL Repo Downloader

A simple set of scripts to download RHEL 8 and/or RHEL 9 packages (including all dependencies) and create local repositories that can be easily transferred or mirrored.

The scripts use `yumdownloader` / `dnf download` with intelligent chunking to stay under the system’s command-line argument length limit (`ARG_MAX`).

---

## Features

- Downloads packages + all dependencies
- Automatically splits large package lists into the minimum number of chunks needed
- Uses dynamic entitlement certificate detection
- Creates a ready-to-use local repository (`createrepo`)
- Packages everything into a convenient `.tar.gz` file
- Works with free Red Hat Developer subscriptions (up to 16 systems)

---

## Prerequisites

- A registered RHEL 8 or RHEL 9 system
- Root access
- `yum-utils` (provides `yumdownloader`) and `createrepo` / `createrepo_c`

```bash
dnf install -y yum-utils createrepo_c
```

1. Create a Free Red Hat Developer Activation KeyCreate a free Red Hat Developer account (if you don’t already have one): 
- [https://developers.redhat.com/register](https://developers.redhat.com/register)

- [https://console.redhat.com](https://console.redhat.com) 
  - Go to Services → System Configuration → Activation Keys
  - or directly: [https://console.redhat.com/insights/connector/activation-keys](https://console.redhat.com/insights/connector/activation-keys)
    - Click Create activation key and Give it a clear name (example: jtif-rhel8-rhel9-developer-key)
    - Workload: Latest release
    - Optionally set System Purpose (Role / SLA / Usage)
    - After creation, open the key and add any extra repositories you need under Additional repositories.
Note your **Organization ID** (click your name in the top-right corner of the console).


2. Register the SystemUse the included helper script: "**register-system-using-rhel-key.sh**"
```bash
# Edit the script and set your values
KEYNAME="jtif-rhel8-rhel9-developer-key"
ORGID="16649499"

chmod +x register-system-using-rhel-key.sh
./register-system-using-rhel-key.sh
```
Or register manually

```bash
subscription-manager register \
  --org="YOUR_ORG_ID" \
  --activationkey="YOUR_KEY_NAME"
```
Verify registration

```bash
subscription-manager identity
subscription-manager status
```

3. Generate Package ListsOn each system (or from a system that already has the packages you want)
```bash
# For RHEL 9
rpm -qa --queryformat '%{NAME}.%{ARCH}\n' | sort > all-rpms-rhel9.txt

# For RHEL 8
rpm -qa --queryformat '%{NAME}.%{ARCH}\n' | sort > all-rpms-rhel8.txt
```
Place the .txt files in the same directory as the rest of these scripts.


4. Run the Download Scripts
- RHEL 9

```bash
chmod +x rhel9_repomake.sh
./rhel9_repomake.sh
```
- RHEL 8
```bash
chmod +x rhel8_repomake.sh
./rhel8_repomake.sh
```



## The scripts will
- Detect the correct entitlement certificates
- Create temporary custom repository definitions
- Download all packages + dependencies in optimally sized chunks
- Clean old package versions (repomanage --keep=1)
- Generate repository metadata (createrepo_c)
- Create a compressed archive: /MonthYearrhelXrepo.tar.gz


# Output After the script finishes you will find:
```bash
/August2026rhel9repo.tar.gz
/August2026rhel8repo.tar.gz
```

These tarballs contain a complete local repository that can be extracted and used with a simple .repo file on other systems.
# Notes
- The first run of createrepo may show a harmless warning about missing old repodata. 
- This is normal.
- Make sure the system has several GB of free space (8+ GB recommended).
- The scripts must be run as root.
- Works best with Simple Content Access (SCA) enabled accounts (the modern default).








