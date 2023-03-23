#!/bin/bash
# The command 'op' reads items from a 1password vault. If you have access to the 4sweep 1password vault, and you have installed
# '1password-cli' (on Mac: `brew install 1password-cli`), this script will automatically populate these fields for you and start
# the app. If you have access to the vault but not the 1password-cli utility, you can manually populate the keys listed here in
# the docker-compose.yml file, after which this script will be able to start the app.

if [[ $(command -v op) == "" ]]; then
    docker-compose -f docker-compose.yml up
else
    KEYS="FOURSQUARE_CLIENT_ID FOURSQUARE_CLIENT_SECRET GOOGLE_MAPS_KEY APP_SECRET" 
    DCCONFIG=$(cat docker-compose.yml)

    SOURCE=( $(op item get "4sweep prod app env" --format json | jq '.fields[] | "\(.label)=\(.value)"' | tr -d '"') )
    for value in ${SOURCE[@]}; do
        ENV_KEY="${value%=*}"
        ENV_VAL="${value#*=}"
        if [[ $KEYS == *"$ENV_KEY"* ]]; then
            DCCONFIG=$(sed "s/$ENV_KEY:.*/$ENV_KEY: $ENV_VAL/" <<< "$DCCONFIG")
        fi
    done

    docker-compose -f - <<<"$DCCONFIG" up 
fi
