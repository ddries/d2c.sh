#! /bin/bash

config_file_dir="/etc/d2c/"
config_file_name="d2c.toml"
config_file="${config_file_dir}${config_file_name}"

cloudflare_base="https://api.cloudflare.com/client/v4"

# print usage text and exit
print_usage() {
    echo '
    d2c (Dynamic DNS Cloudflare): Update Cloudflare DNS 'A' records for your dynamic IP.

    Usage: d2c.sh

    `d2c` UPDATES existing records. Please, create them in Cloudflare Dashboard before running this script.

    The configuration is done in `/etc/d2c/d2c.toml` in TOML format.
    Configuration file structure:

    ```
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
'
}

# print usage if requested
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    print_usage
    exit
fi

# ensure yq is installed
if ! command -v yq > /dev/null 2>&1; then
    echo "Error: 'yq' required and not found."
    echo "Please install: https://github.com/mikefarah/yq."
    exit 1
fi

# ensure curl is installed
if ! command -v curl > /dev/null 2>&1; then
    echo "Error: 'curl' required and not found."
    echo "Please install: https://curl.se/download.html or through your package manager."
    exit 1
fi

# create config dir if not exists
if [ ! -d $config_file_dir ]; then
    echo "Directory: ${config_file_dir} does not exist."
    echo "Creating..."
    sudo mkdir $config_file_dir
    
    echo "Created ${config_file_dir}. Please, fill ${config_file}."
    exit 0
fi

# get my public ip
public_ip=`curl --silent https://checkip.amazonaws.com/`

# read zone-id and api-key from config file
zone_id=`yq '.api.zone-id' ${config_file}`
api_key=`yq '.api.api-key' ${config_file}`

# get records from cloudflare
existing_records_raw=`curl --silent --request GET \
    --url ${cloudflare_base}/zones/${zone_id}/dns_records \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer ${api_key}" \
    | yq -oj -I=0 '.result[] | select(.type == "A") | [.id, .name, .ttl]'
`

# get records defined in config file
readarray config_records < <(yq -oj -I=0 '.dns[]' ${config_file})

# iterate cloudflare records
# for each record, check if it exists in config file
# if it does, update record
for record in ${existing_records_raw[@]}; do
    id=`yq '.[0]' <<< "${record}"`
    name=`yq '.[1]' <<< "${record}"`
    ttl=`yq '.[2]' <<< "${record}"`

    for c_record in ${config_records[@]}; do
        c_name=`yq '.name' <<< ${c_record}`
        c_proxy=`yq '.proxy' <<< ${c_record}`

        if [ "$name" = "$c_name" ]; then
            # update dns
            curl --silent --request PATCH \
            --url "${cloudflare_base}/zones/${zone_id}/dns_records/${id}" \
            --header 'Content-Type: application/json' \
            --header "Authorization: Bearer ${api_key}" \
            --data '{
                "content": "'${public_ip}'",
                "name": "'${name}'",
                "proxied": '${c_proxy}',
                "type": "A",
                "comment": "Managed by d2c.sh",
                "ttl": '${ttl}'
            }' > /dev/null

            echo "[d2c.sh] OK: ${name}"
        fi
    done
done