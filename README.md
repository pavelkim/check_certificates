# check_certificates

Use this script to automate HTTPS SSL Certificate monitoring. It curl's remote server on 443 port and then checks remote SSL Certificate expiration date.

# Releases

Latest release: [Download](https://github.com/pavelkim/check_certificates/releases/latest/download/check_certificates.sh)

# Usage

The script takes on input a file with a list of hostnames:
```bash
./check_certificates.sh [-h] [-v] [-l] [-n] [-A n] -i input_filename

	-i, --input-filename 	 Path to the list of domains to check
	-l, --only-alerting  	 Show only alerting domains (expiring soon and erroneous)
	-n, --only-names     	 Show only domain names instead of the full table
	-A, --alert-limit    	 Set threshold of upcoming expiration alert to n days
	-v, --verbose        	 Enable debug output
	-h, --help           	 Enable debug output
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

# Supported platforms

Currently tested on the following platforms:
1. CentOS 8, bash 4.4.19, openssl 1.1.1c
2. Mac OS 10.13.6, bash 3.2.57, openssl 1.1.1d
