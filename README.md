# d2c.sh

Update Cloudflare DNS 'A' records for your dynamic IP.

---

d2c.sh (Dynamic DNS Cloudflare) is a very simple bash script to automatically update the IP address of A DNS records from Cloudflare.

### Configure

d2c.sh is configured using a TOML file located in `/etc/d2c/d2c.toml`. The first time you run d2c.sh from the command-line, it will create the config directory for you. You still have to manually create the TOML configuration file.

Syntax:

```toml
[api]
zone-id = "aaa" # your dns zone id
api-key = "bbb" # your api key with dns records permissions

[[dns]]
name = "dns1.example.com" # dns name
proxy = true # proxied by cloudflare?

[[dns]]
name = "dns2.example.com"
proxy = false
```

When d2c.sh is ran, it UPDATES the records configured in `/etc/d2c/d2c.toml` with the current public IP of the machine. The A records be created from the Cloudflare dashboard, then d2c.sh will be able to UPDATE them with the public IP of the server.

### Usage

```sh
$ d2c.sh --help

d2c (Dynamic Dns Cloudflare): Update the Cloudflare DNS A records for your dynamic IP.

Usage: d2c.sh

`d2c` UPDATES existing records. Please, create them in Cloudflare Dashboard before running this script.

The configuration is done in `/etc/d2c/d2c.toml` in TOML format.
Configuration file structure:

[api]
zone-id = <zone id>
api-key = <api key>

[[dns]]
name = test.example.com
proxy = false

[[dns]]
name = test2.example.com
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

Fill `/etc/d2c/d2c.toml` with your zone id, API key and the desired DNS':

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

[d2c.sh] OK: dns1.example.com
[d2c.sh] OK: dns2.example.com

$ crontab -e # set cronjob to run d2c.sh periodically
```

#### Method 2: Executing from URL

You can also execute d2c.sh avoiding the installation. Note that you must still have a valid configuration file: `/etc/d2c/d2c.toml`.

Execute from URL:

```sh
$ bash <(curl -s https://www.driescode.dev/d2c.sh)

[d2c.sh] OK: dns1.example.com
[d2c.sh] OK: dns2.example.com
```

To run periodically without installing, you can write your own script:

```sh
$ nano run_d2c.sh

#!/bin/bash
bash <(curl -s https://www.driescode.dev/d2c.sh)

$ crontab -e # set cronjob to run periodically
```