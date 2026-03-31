#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

while getopts "hu:x:i:p:" opt; do
  case $opt in
    u)
      xwikiuser=$OPTARG
      ;;
    x)
      url=$OPTARG
      ;;
    i)
      issuer=$OPTARG
      ;;
    p)
      xwikipassword=$OPTARG
      ;;
    h|\?)
      echo "-u    Xwiki Admin Username"
      echo "-x    Xwiki URL"
      echo "-i    OpenID Connect Issuer"
      echo "-p    Xwiki Admin password"
      echo "-h    help"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Deine ursprüngliche, korrekte Logik für set -o nounset
if [ -z ${xwikiuser+x} ]; then
  read -s -r -p "Please enter XWIKI Admin username: " xwikiuser
  echo ""
fi

if [ -z ${xwikipassword+x} ]; then
  read -s -r -p "Please enter XWiki Admin password: " xwikipassword
  echo ""
fi

if [ -z ${url+x} ]; then
  read -s -r -p "Please enter XWiki URL: " url
  echo ""
fi

if [ -z ${issuer+x} ]; then
  read -s -r -p "Please enter OpenID Connect Issuer: " issuer
  echo ""
fi


_get_random_guid(){
  local random1=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 8 | head -n 1)
  local random2=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 4 | head -n 1)
  local random3=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 4 | head -n 1)
  local random4=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 12 | head -n 1)
  echo "${random1}-${random2}-${random3}-${random4}"
}

_get_users_from_rest(){
  users=($(curl --silent --show-error --fail --user "${xwikiuser}:${xwikipassword}" \
               --url "${url}/rest/wikis/xwiki/classes/XWiki.LDAPProfileClass/objects" \
               | grep -oPm1 "(?<=<pageName>)[^<]+"))
}

_get_users_from_rest


# check if there are LDAP user
if [ "${#users[@]}" == 0 ]; then
  echo "0 LDAP Users found"
  exit 2
fi

echo "${#users[@]} LDAP Users found"


for user in "${users[@]}"; do
  subject=${user}

  # check if user is already converted
  isdone=$(curl --show-error --silent --fail --user "${xwikiuser}:${xwikipassword}" \
                --url "${url}/rest/wikis/xwiki/spaces/XWiki/pages/${subject}/objects" | grep "XWiki.OIDC.UserClass" || true)
                
  if [ -n "${isdone}" ]; then
    echo "convert user: ${subject} was already done"

  else
    # if user has to be converted
    random_guid=$(_get_random_guid)

    echo "convert user: ${subject} start"

    xml=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<object xmlns="http://www.xwiki.org">
<link href="${url}/rest/wikis/xwiki/spaces/XWiki/pages/${subject}/objects/XWiki.OIDC.UserClass/0" rel="self"/>
<id>xwiki:XWiki.${subject}:${random_guid}</id>
<guid>${random_guid}</guid>
<pageId>xwiki:XWiki.${subject}</pageId>
<pageVersion>1.1</pageVersion>
<wiki>xwiki</wiki>
<space>XWiki</space>
<pageName>${subject}</pageName>
<pageAuthor>XWiki.superadmin</pageAuthor>
<className>XWiki.OIDC.UserClass</className>
<number>0</number>
<headline>${issuer}</headline>
<property name="issuer" type="String">
<link href="${url}/rest/wikis/xwiki/spaces/XWiki/pages/${subject}/objects/XWiki.OIDC.UserClass/0/properties/issuer" rel="self"/>
<attribute name="name" value="issuer"/>
<attribute name="prettyName" value="Issuer"/>
<attribute name="unmodifiable" value="0"/>
<attribute name="disabled" value="0"/>
<attribute name="size" value="30"/>
<attribute name="number" value="1"/>
<value>${issuer}</value>
</property>
<property name="subject" type="String">
<link href="${url}/rest/wikis/xwiki/spaces/XWiki/pages/${subject}/objects/XWiki.OIDC.UserClass/0/properties/subject" rel="self"/>
<attribute name="name" value="subject"/>
<attribute name="prettyName" value="Subject"/>
<attribute name="unmodifiable" value="0"/>
<attribute name="disabled" value="0"/>
<attribute name="size" value="30"/>
<attribute name="number" value="2"/>
<value>${subject}</value>
</property>
</object>
EOF
)

    curl --silent --show-error --fail --user "${xwikiuser}:${xwikipassword}" \
          -X POST \
          -H "Content-type: application/xml" \
          -H "Accept: application/xml" \
          -d "${xml}"  \
          "${url}/rest/wikis/xwiki/spaces/XWiki/pages/${subject}/objects" -o /dev/null

    if [ $? != 0 ]; then
        exit $?
    fi

    echo "convert user: ${subject} done"

  fi

done
