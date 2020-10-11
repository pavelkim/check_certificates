# check_certificates

Use this script to automate HTTPS SSL Certificate monitoring. It curl's remote server on 443 port and then checks remote SSL Certificate expiration date. You can use it with Zabbix, Nagios/Icinga or other.

# Releases

Latest release: [Download](https://github.com/pavelkim/check_certificates/releases/latest/download/check_certificates.sh)

# Usage

The script takes on input a file with a list of hostnames:
```bash
Usage: check_certificates.sh [-h] [-v] [-s] [-l] [-n] [-A n] -i input_filename -d domain_name -b backend_name

   -b, --backend-name       Domain list backend name (pastebin, gcs, etc.)
   -i, --input-filename     Path to the list of domains to check
   -d, --domain             Domain name to check
   -s, --sensor-mode        Exit with non-zero if there was something to print out
   -l, --only-alerting      Show only alerting domains (expiring soon and erroneous)
   -n, --only-names         Show only domain names instead of the full table
   -A, --alert-limit        Set threshold of upcoming expiration alert to n days
   -v, --verbose            Enable debug output
   -h, --help               Enable debug output
```

# Supported domain list backends

Domain list backends allow you to manage configuration in a centralised manner.

## PasteBin

You can use a PasteBin paste as a source of domain names to be checked. We encorage you to register on PasteBin and create all your pastes related to `check_certificates` as Private or at least as Unlisted.

1. Create a paste with a valid structure [example](https://pastebin.com/FJFvdiPg)
1. Obtain devkey and userkey ([documentation](https://pastebin.com/doc_api#7))
1. Fill out variables in `.config` file

### Paste structure

```json
{ 
  "check_ssl": [ 
    "example.com",
    "google.com",
    "mail.com",
    "imaginary-domain-9000.com"
  ]
}
```

### .config file variables

```bash
PASTEBIN_USERKEY=youruserkey
PASTEBIN_DEVKEY=yourdevkey
PASTEBIN_PASTEID=pasteid
```

# Input file format

Example of an input file contents:
```
example.com
google.com
mail.com
imaginary-domain-9000.com
```

# Output data format

Output fields: 
```
Hostname    Valid Not Before    Valid Not After    Expires in N Days
```

Full output (default) example:
```
imaginary-domain-9000.com  error                error                -1
google.com                 2020-06-30 20:43:12  2020-09-22 20:43:12  66
example.com                2018-11-28 00:00:00  2020-12-02 12:00:00  136
mail.com                   2018-01-15 00:00:00  2021-01-14 12:00:00  179
```

Domain names only output (with parameters `-n -l -A 90`) example:
```
imaginary-domain-9000.com
google.com
```

# Application examples

## Monitoring in Cron

The following example of a crontab will provide you with email notfications in 14 days prior to SSL certificate expiration (or in case of other errors). Before that you'll receive no emails. Keep in mind that you'll need to have your Cron and MTA configured properly.

/etc/cron.d/check_certificates:
```java
HOME=/opt/check_certificates
MAILTO="john.doe@example.com"

30 11 * * * nobody bash ./check_certificates.sh -l -A 14 -i corp_domains.txt
35 11 * * * nobody bash ./check_certificates.sh -l -A 14 -d "example.com"
```

## Sensor script for Zabbix/Nagios/Icinga etc.

You could use `--sensor-mode` along with other parameters to make the script exit with non-zero code if your remote host has an expiring certificate. 

For Zabbix you can create a simple check to monitor your remote SSL certificate. For Nagios/Icinga you can configure a separate service check.

```bash
./check_certificates.sh --sensor-mode --only-names --only-alerting --alert-limit 14 --domain example.com
```

The script executed as displayed above will return 0 in case if `example.com` has SSL certificate valid for 15 or more days. In case of error (DNS, firewall, etc.) or if certificate will expire in less then 14 days, the script will return 1.

# Supported platforms

Currently tested on the following platforms:
1. CentOS 8, bash 4.4.19, openssl 1.1.1c
2. Mac OS 10.13.6, bash 3.2.57, openssl 1.1.1d
