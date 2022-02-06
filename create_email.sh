#!/bin/bash
#create new mail account script
#tested on debian with postfix and roundcube
#license GPL v1.0 George Dimitrakopoulos

# Text color variables
TXT_BLD=$(tput bold)
TXT_RED=$(tput setaf 1)
TXT_GREEN=$(tput setaf 2)
TXT_YLW=$(tput setaf 3)
TXT_BLUE=$(tput setaf 4)
TXT_RESET=$(tput sgr0)


#define vars
error=0
virtual_home="/var/my_domain_system_usr/mail/virtual"
nobackup=0
mysql_user="muser"
mysql_pass="mpass"
mysql_db="maildb"
domain="mydomain.tld"

# the only function in this script so far :P
function die()
{
	echo "$@"
	exit 1
}
		

########## main script #############
#check if we are root
[ $(whoami) == "root" ] || die "You need to run this script as root."
			
#check if a mail username is given
if [ -z $1 ];then
	echo "please give a name for the new mail account!"
	echo "usage: ./create_mail.sh username backupmail"
	exit 1
else
	echo "the name for the new mail account is ${TXT_BLD}$1@$domain${TXT_RESET}"
fi
#check if a backup mail is given and prompt to continue or not
if [ -z $2 ];then
	echo "${TXT_YLW}no backup mail given!${TXT_RESET}"
    read -p "continue without it?? (y/n)?"
	[ "$REPLY" != "n" ] || die "exiting..."
fi
nobackup=1
#check if there is already a maildir with that name
#if not go make one and chown it
if [ -d $virtual_home/$1 ];then 
	echo "${TXT_YLW}there is already a maildir with that name!${TXT_RESET}"
	echo "exiting..."
	exit 1
else
	mkdir $virtual_home/$1
	if [ $? -eq 0 ];then
		chown virtual.virtual $virtual_home/$1
		if [ $? -ne 0 ]; then
			echo "${TXT_RED}cannot chown maildir!!${TXT_RESET}"
			error=1
		fi
	else
		echo "${TXT_RED}cannot create maildir!!${TXT_RESET}"
		error=1
	fi
	if [ $error -ge 1 ]; then
		echo "${TXT_YLW}maildir for ${TXT_BLD}$1${TXT_RESET} created but with errors, please check manually${TXT_RESET}"
	else
		echo "maildir for ${TXT_BLD}$1${TXT_RESET} created in ${TXT_BLD}$virtual_home${TXT_RESET}"
	fi
fi

if [ $error -eq 0 ]; then
 # make password for new mail account (it is stored in PASSWD var)
 echo "making password..."
 PASSWD=$(openssl rand -base64 8 ) 
 
 #call mysql to update database
 echo "creating new user in database..."
 mysql --user=$mysql_user --password=$mysql_pass --database=$mysql_db -e "INSERT INTO users (
id ,name ,uid ,gid ,home ,maildir ,enabled ,change_password ,clear ,crypt ,quota ,procmailrc ,spamassassinrc)
VALUES (
'$1@$domain', '$1', '5000', '5000', '$virtual_home', '$1/', '1', '1', ENCRYPT('$PASSWD'), 'sdtrusfX0Jj66', '52428800', '', ''
);"

#send test mail
 echo "sending user/password email ..."
 if [ $nobackup -eq 1 ]; then
	echo "test mail from $domain\n username: $1 \n password: $PASSWD" | mail -s "testing email" $1@$domain
 else
 	echo "there is no backup mail to sent password so echoing from cli: $PASSWD"
 	echo "test mail from $domain\n username: $1 \n password: $PASSWD" | mail -s "testing email" $1@$domain -c $2
 fi
 if [ $? -ne 0 ]; then
 	echo "${TXT_RED}send mail failed!${TXT_RESET}Please send one manually"
 	error=2
 else
 	echo "${TXT_GREEN}New mail user is created!${TXT_RESET}Stop spamming :P"
 fi	
else
 if [ $error -eq 1 ];then
	echo "${TXT_RED}did not made new mail user!${TXT_RESET}"
 elif [ $error -eq 2 ];then
 	echo "${TXT_YLW} New mail user is created but with errors. Check manually! ${TXT_RESET}"
 fi
fi
