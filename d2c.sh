#!/bin/bash

config_file_dir="/etc/d2c/"
cloudflare_base="https://api.cloudflare.com/client/v4"

# print usage text and exit
print_usage() {
    echo '
    d2c (Dynamic DNS Cloudflare): Update Cloudflare DNS 'A' and 'AAAA' records for your dynamic IP.

    Usage: d2c.sh

    `d2c` UPDATES existing records. Please, create them in Cloudflare Dashboard before running this script.

    The configuration is done in `/etc/d2c/*.toml` files in TOML format.
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

    [[dns]]
    name = "test-ipv6.example.com"
    proxy = false
    ipv6 = true # Optional, for 'AAAA' records
    ```
'
}

send_notification() {
    if [[ "${APPRISE_SIDECAR_URL}" != "" ]]; then
        status=$(curl --no-progress-meter -X POST -H "Content-Type: application/json" \
            --data "{\"title\": \"$1\", \"body\": \"$2\", \"type\": \"$3\"}" "${APPRISE_SIDECAR_URL}")
        echo "Sending notification: $status"
    fi
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
    
    echo "Created ${config_file_dir}. Please, fill the configuration files."
    exit 0
fi

# get my public IP
public_ipv4=$(curl --silent https://checkip.amazonaws.com/)
public_ipv6=$(curl --silent https://api64.ipify.org/)

# process each config file in sorted order
for config_file in $(ls ${config_file_dir}*.toml 2>/dev/null | sort -V); do
    echo "[d2c.sh] Processing ${config_file}..."

    # read zone-id and api-key from config file
    zone_id=$(yq '.api.zone-id' ${config_file})
    api_key=$(yq '.api.api-key' ${config_file})

    # get records from Cloudflare
    existing_records_raw=$(curl --silent --request GET \
        --url ${cloudflare_base}/zones/${zone_id}/dns_records \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer ${api_key}" \
        | yq -oj -I=0 '.result[] | select(.type == "A" or .type == "AAAA") | [.id, .name, .ttl, .content, .type]'
    )

    # get records defined in config file
    readarray config_records < <(yq -oj -I=0 '.dns[]' ${config_file})

    # iterate Cloudflare records
    # for each record, check if it exists in config file
    # if it does, update the record
    for record in ${existing_records_raw[@]}; do
        id=$(yq '.[0]' <<< "${record}")
        name=$(yq '.[1]' <<< "${record}")
        ttl=$(yq '.[2]' <<< "${record}")
        content=$(yq '.[3]' <<< "${record}")
        type=$(yq '.[4]' <<< "${record}")

        for c_record in ${config_records[@]}; do
            c_name=$(yq '.name' <<< ${c_record})
            c_proxy=$(yq '.proxy' <<< ${c_record})
            c_ipv6=$(yq '.ipv6' <<< ${c_record})
            if [ "$c_ipv6" = true ]; then
                c_type="AAAA"
                public_ip=$public_ipv6
            else
                c_type="A"
                public_ip=$public_ipv4
            fi

            if [ "$name" = "$c_name" ] && [ "$type" = "$c_type" ]; then
                if [ "$public_ip" != "$content" ]; then
                    # update DNS
                    result_json=$(curl --no-progress-meter --request PATCH \
                    --url "${cloudflare_base}/zones/${zone_id}/dns_records/${id}" \
                    --header 'Content-Type: application/json' \
                    --header "Authorization: Bearer ${api_key}" \
                    --data '{
                        "content": "'${public_ip}'",
                        "name": "'${name}'",
                        "proxied": '${c_proxy}',
                        "type": "'${c_type}'",
                        "comment": "Managed by d2c.sh",
                        "ttl": '${ttl}'
                    }')
                    update_successful=$(echo "$result_json" | grep -o '"success": *[^,}]*' | awk -F':' '{print $2}')

                    if [ "$update_successful" == "true" ]; then
                        echo "[d2c.sh] OK: ${name}"
                        send_notification "[d2c.sh] DNS updated" "Updated successfully: ${name}" "success"
                    else
                        echo "[d2c.sh] Failure: ${name}"
                        echo $result_json
                        send_notification "[d2c.sh] DNS update error" "Failed to update: ${name}" "failure"
                    fi
                else
                    echo "[d2c.sh] ${name} did not change"
                fi
            fi
        done
    done
done

echo "All files processed."
