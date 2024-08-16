# d2c.sh

Update Cloudflare DNS 'A' records for your dynamic IP.

---

d2c.sh (Dynamic DNS Cloudflare) is a very simple bash script to automatically update the IP address of A DNS records from Cloudflare.

### Configure

d2c.sh is configured using TOML files located in `/etc/d2c/`. The first time you run d2c.sh from the command-line, it will create the config directory for you. You will then need to manually create one or more TOML configuration files.


**Example configuration files:**


+ The script processes all files in `/etc/d2c/` that start with `d2c` and end with `.toml`.

**`/etc/d2c/d2c.toml`:**
```toml
[api]
zone-id = "aaa" # your DNS zone ID
api-key = "bbb" # your API key with DNS records permissions

[[dns]]
name = "dns1.example.com" # DNS name
proxy = true # Proxied by Cloudflare?

[[dns]]
name = "dns2.example.com"
proxy = false
```

**`/etc/d2c/d2c1.toml`:**
```toml
[api]
zone-id = "ccc" # your second DNS zone ID
api-key = "ddd" # your API key with DNS records permissions

[[dns]]
name = "dns3.example.com" # DNS name
proxy = true # Proxied by Cloudflare?

[[dns]]
name = "dns4.example.com"
proxy = false
```

When d2c.sh is run, it will process each `d2c*.toml TOML` file in the `/etc/d2c/` directory, updating the records configured in each with the current public IP of the machine. The A records should be created from the Cloudflare dashboard first; then d2c.sh will be able to UPDATE them with the server's public IP.

### Usage

```sh
$ d2c.sh --help

d2c (Dynamic Dns Cloudflare): Update the Cloudflare DNS A records for your dynamic IP.

Usage: d2c.sh

`d2c` UPDATES existing records. Please, create them in Cloudflare Dashboard before running this script.

The configuration is done in `/etc/d2c/d2c*.toml` files in TOML format.
Configuration file structure:

[api]
zone-id = "<zone id>"
api-key = "<api key>"

[[dns]]
name = "test.example.com"
proxy = false

[[dns]]
name = "test2.example.com"
proxy = true

```

#### Method 1: Installing d2c.sh

Install d2c.sh using the installation script:

```sh
$ ./install

Successfully installed d2c.sh into /usr/local/bin.
Please, run d2c.sh from command-line before scheduling any cronjob.
Help: `d2c.sh --help` or `d2c.sh -h` or `d2c.sh help`.
```

Then, run d2c.sh from command-line for the first time:

```sh
$ d2c.sh

Directory: /etc/d2c/ does not exist.
Creating...
Created /etc/d2c/. Please, fill /etc/d2c/d2c.toml.
```

Fill `/etc/d2c/d2c*.toml` file or files with your zone id, API key and the desired DNS':

```sh
$ sudo nano /etc/d2c/d2c.toml

[api]
zone-id = "aaa"
api-key = "bbb"
...
```

Finally, you can run manually d2c.sh or set up a cronjob to update periodically:

```sh
$ d2c.sh # manually

Processing /etc/d2c/d2c.toml...
[d2c.sh] dns1.example-1.com did not change
Processing /etc/d2c/d2c-1.toml...
[d2c.sh] OK dns2.example-2.com

$ crontab -e # set cronjob to run d2c.sh periodically
```

#### Method 2: Executing from URL

You can also execute d2c.sh avoiding the installation. Note that you must still have a valid configuration file: `/etc/d2c/d2c.toml`.

Execute from URL:

```sh
$ bash <(curl -s https://raw.githubusercontent.com/ddries/d2c.sh/master/d2c.sh)

Processing /etc/d2c/d2c.toml...
[d2c.sh] dns1.example-1.com did not change
Processing /etc/d2c/d2c-1.toml...
[d2c.sh] OK dns2.example-2.com
```

To run periodically without installing, you can write your own script:

```sh
$ nano run_d2c.sh

#!/bin/bash
bash <(curl -s https://raw.githubusercontent.com/ddries/d2c.sh/master/d2c.sh)

$ crontab -e # set cronjob to run periodically
```
