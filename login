#!/bin/sh

client_id='1085144278039-0clfn1ejlnfjdrh5d483cmp2mrssblad.apps.googleusercontent.com'
client_secret='qur3yX-h5b_q-fHlw6Yq7hFm'

# should really use read-only access but this doesn't work, see: http://stackoverflow.com/q/26699062/2153631
#scope='https://www.googleapis.com/auth/contacts.readonly'
scope='https://www.google.com/m8/feeds'

eecho() {
  echo "$@" >&2
}

die() {
  eecho 'fatal:' "$@"
  exit 1
}

f_owndir="$(dirname "$(readlink -f "$0")")"
f_token_access="${f_owndir}/token-access"
f_token_refresh="${f_owndir}/token-refresh"

# ------------------------------------- if already logged in and access token still valid

if [ -e "$f_token_access" ] ; then
  expires_on=$(cat "$f_token_access" | head -n 1)
  if [ "$(date '+%s')" -lt "$expires_on" ] ; then
    cat "$f_token_access" | tail -n 1
    exit 0
  fi
fi

# ------------------------------------- if already logged in and access token expired

if [ -e "$f_token_access" ] ; then
  eecho -n 'Refreshing the access token on Google OAuth2... ' >&2
  refresh_token="$(cat "$f_token_refresh")"

  json=$(curl -sSfLd "client_id=${client_id}&client_secret=${client_secret}&refresh_token=${refresh_token}&grant_type=refresh_token" 'https://accounts.google.com/o/oauth2/token') || die "curl"

  error=$(echo "$json" | grep -E '"error"' | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
  if [ -n "$error" ] ; then
    eecho "\`$error'."
    eecho
    eecho "$json"
    exit 1
  fi

  eecho 'done.'
  eecho

  access_token=$(    echo "$json" | grep -E '"access_token"'     | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
  expires_in=$(      echo "$json" | grep -E '"expires_in"'       | sed -re 's/^.*:\s*([0-9]+).*$/\1/g')

  expires_on=$(echo "$(date '+%s')+${expires_in}-10" | bc)
  echo -ne "${expires_on}\n${access_token}\n" >"$f_token_access"

  echo "$access_token"

  exit 0
fi

# ------------------------------------- else → request new authorization

eecho -n 'Requesting new tokens from Google OAuth2... ' >&2

json=$(curl -sSfLd "client_id=${client_id}&scope=${scope}" 'https://accounts.google.com/o/oauth2/device/code') || die "curl"

error=$(echo "$json" | grep -E '"error"' | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
if [ -n "$error" ] ; then
  eecho "\`$error'."
  eecho
  eecho "$json"
  exit 1
fi

eecho 'done.'
eecho

verification_url=$(echo "$json" | grep -E '"verification_url"' | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
user_code=$(       echo "$json" | grep -E '"user_code"'        | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
device_code=$(     echo "$json" | grep -E '"device_code"'      | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
interval=$(        echo "$json" | grep -E '"interval"'         | sed -re 's/^.*:\s*([0-9]+).*$/\1/g')

eecho "Now, go to \`${verification_url}' and input \`${user_code}'."
eecho

while true ; do
  eecho -n "Polling for the access token... "

  json=$(curl -sSfLd "client_id=${client_id}&client_secret=${client_secret}&code=${device_code}&grant_type=http://oauth.net/grant_type/device/1.0" 'https://accounts.google.com/o/oauth2/token') || die "curl"
  error=$(echo "$json" | grep -E '"error"' | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')

  if [ -z "$error" ] ; then
    eecho

    access_token=$(    echo "$json" | grep -E '"access_token"'     | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
    refresh_token=$(   echo "$json" | grep -E '"refresh_token"'    | sed -re 's/^.*:\s*"([^"]+).*$/\1/g')
    expires_in=$(      echo "$json" | grep -E '"expires_in"'       | sed -re 's/^.*:\s*([0-9]+).*$/\1/g')

    expires_on=$(echo "$(date '+%s')+${expires_in}-10" | bc)
    echo -ne "${expires_on}\n${access_token}\n" >"$f_token_access"
    echo -ne "${refresh_token}\n" >"$f_token_refresh"

    echo "$access_token"

    exit 0
  fi

  eecho "\`$error'."
  eecho -n "Sleeping for ${interval} s... "
  sleep "$interval"
  eecho 'done.'
  eecho
done
