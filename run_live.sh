#!/bin/bash

#set -o xtrace
set -o errexit
set -o pipefail
set -o errtrace
shopt -s inherit_errexit

trap 'echo "TRAP: script failed!" >&2; for ((;;)); do spd-say -w "script failed"; done' ERR


scriptDir="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
. "$scriptDir/config.sh"


function llmQuery() {
    prompt="Analyze this Live Caption and classify the call status.

LIVE CAPTION:
$1

CLASSIFICATION CRITERIA:
- HOLD: music, \"please wait\" messages, busy signals
- PICKED: Human conversation, agent greeting, or dialogue begins

OUTPUT: Return only \"HOLD\" or \"PICKED\"
"
    #echo $"$prompt" 1>&2 # debug

    escaped_prompt=$(echo "$prompt" | jq -Rs .)
    json_body=$(jq -n --argjson input "$escaped_prompt" '{
        "model": "gpt-5.2",
        "reasoning": {
            "effort": "none",
            "summary": null
        },
        "input": $input
    }')

    response=$(curl -s https://api.openai.com/v1/responses \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$json_body")

    echo "$response" | jq -r '.output[0].content[0].text'
}

function main() {
    local last_md5=""
    local counter=1

    while true; do
        current_dump=$(adb exec-out uiautomator dump /dev/tty | sed 's|UI hierchary dumped to: /dev/tty||')
        current_md5=$(echo "$current_dump" | md5sum | cut -d' ' -f1)

        if [ "$current_md5" != "$last_md5" ]; then
            timestamp=$(date +%Y%m%d_%H%M%S)
            if [ "$output_dump" != "none" ]; then
                mkdir -p "$output_dump"
                filename="${output_dump}/${timestamp}_${counter}.xml"
                echo "$current_dump" > "$filename"
                echo -e "\n[$(date +%H:%M:%S)] Saved: $filename (md5: $current_md5)"
            fi

            captions=$(echo -e $"$current_dump" | xmllint --format - | grep captions_text | grep -oP '(?<=text=")[^"]*')
            echo "XXX" ; echo -e $"$captions" ; echo "XXX"

            llm_response=$(llmQuery "$captions")
            echo "$llm_response"

            if [ "$llm_response" != "HOLD" ]; then
                echo "!!! CHECK CALL !!!"
                echo "Press 'c' to continue monitoring, Ctrl+C to stop the script"
                while true; do
                    spd-say -w "check call"
                    read -t 1 -n 1 key 2>/dev/null && if [ "$key" = "c" ]; then echo "Continuing..."; break; fi
                done
            fi

            last_md5="$current_md5"
            ((counter++))
        else
            echo -ne "\r[$(date +%H:%M:%S)] No change (md5: $current_md5)    "
        fi
        sleep "$sleep_interval"
    done
}

main
