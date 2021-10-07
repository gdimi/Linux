#!/bin/bash
#by George Dimitrakopoulos
#make json ssl list for zabbix ssl check template
#copyright 2021 GNU GPL v2
#ver 1.1

#set initials values
domainsfile="/etc/userdatadomains"
resultsfile="/etc/zabbix/ssl_sites.json"
cpanelsslsettings="/var/cpanel/autossl.json"
cpaneluserdatafolder="/var/cpanel/users/"
others=""
subs=""
exclude=""
excludeFile=""
autosslProvider=""

#parse arguments if any
for i in "$@"
do
case $i in
    -d=*|--domainsfile=*)
    domainsfile="${i#*=}"
    shift
    ;;
    -r=*|--resultsfile=*)
    resultsfile="${i#*=}"
    shift
    ;;
    -o=*|--others=*)
    others="${i#*=}"
    shift
    ;;
    -e=*|--exclude=*)
    exclude="${i#*=}"
    shift
    ;;
    -s=*|--sub=*)
    subs="${i#*=}"
    shift
    ;;
    -x=*|--xfile=*)
    excludeFile="${i#*=}"
    shift
    ;;
    --help)
    echo "Usage options: -d= or --domainsfile=path_to_domains_file
-r= or ==resultsfile=path_to_results_file
-o= or --other=yes (includes anything with an ssl setting eg parked domains)
-s or --sub=yes includes subdomains
-e= or --exclude= something to exclude. It can be a regex
-x= or -xfile= a file with one account per line to exclude(not working)
By default suspended accounts are excluded. Accounts with autossl set to enabled are excluded too.
Example: exclude everything besides main domain and addon domains
make_ssl_file.sh -o=yes -e='parked\|sub'
"
    exit 1
    shift
    ;;
    *)
          # unknown option
    ;;
esac
done

if [ ! -f "$domainsfile" ]; then
    echo "Domains data file not found!"
    exit 1
fi

if [ ! -f "$resultsfile" ]; then
    echo "Results file not fould!"
    exit 1
fi

cp $resultsfile $resultsfile".old"

autosslProvider=$(grep -Po '"provider":.*?[^\\]"' /var/cpanel/autossl.json | awk -F':' '{print $2}' | sed 's/\"//g')

#echo "$autosslProvider"

cat <<EOT > $resultsfile
{
    "data":[
EOT

while IFS= read -r line || [[ -n "$line" ]]; do

        Domain=""
        User=$(echo "${line}" | cut -d ":" -f 2 | cut -d "=" -f 1 | tr -d '[:space:]')
        hasSSLon=""
        if echo "$line" | grep -q '443';
        then
                hasSSLon="yes"
        fi

        if  echo "$line" | grep -q 'main';
        then
            if [ ! -f "/var/cpanel/suspended/$User" ]; then
                Domain=$(echo "${line}" | cut -d ":" -f 1)
            fi;
        else
            if [ "$hasSSLon" = "yes" ];
            then
                if [ "$others" = "yes" ]; then
                        Domain=$(echo "${line}" | cut -d ":" -f 1)
                fi
            else
                Domain=""
            fi
        fi

        if [ ! -z "$exclude" ]; then
                if echo "$line" | grep -q "$exclude"; then
                        Domain=""
                fi
        fi

        if [[ "$autosslProvider" == "cPanel" || "$autosslProvider" == "LetsEncrypt" ]]; then
                if  cat "/var/cpanel/users/$User" | grep -q 'FEATURE-AUTOSSL';then
                        if  cat "/var/cpanel/users/$User" | grep -q 'FEATURE-AUTOSSL=1';
                        then
                                Domain=""
                        fi
                else
                        if [ ! -z "$hasSSLon" ]; then
                                Domain=""
                        fi
                fi
        fi

        [ -n "$Domain" ] &&  echo -e '\t{ "{#SSLNAME}": "'${Domain}'", "{#PORT}":"443"},' >> $resultsfile

done < "$domainsfile"

cat <<EOT >> $resultsfile
    ]
}

EOT

