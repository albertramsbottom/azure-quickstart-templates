#!/bin/bash
apt-get -y update
apt-get -y install python-software-properties
add-apt-repository -y ppa:ondrej/php5-oldstable
apt-get -y update

# set up a silent install of MySQL
dbpass=$1
moodleVersion=$2

export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.6 mysql-server/root_password password $dbpass | debconf-set-selections
echo mysql-server-5.6 mysql-server/root_password_again password $dbpass | debconf-set-selections

# install the LAMP stack
apt-get -y install apache2 mysql-client mysql-server php5

# install moodle requirements
apt-get -y install graphviz aspell php5-pspell php5-curl php5-gd php5-intl php5-mysql php5-xmlrpc php5-ldap

# create moodle database
MYSQL=`which mysql`

Q1="CREATE DATABASE moodle DEFAULT CHARACTER SET UTF8 COLLATE utf8_unicode_ci;"
Q2="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'root'@'%' IDENTIFIED BY '$dbpass' WITH GRANT OPTION;"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

$MYSQL -uroot -p$dbpass -e "$SQL"

apt-get install unzip

# install Moodle
cd /var/www
curl -k --max-redirs 10 https://github.com/moodle/moodle/archive/$moodleVersion.zip -L -o moodle.zip
unzip moodle.zip
mv moodle-$moodleVersion moodle

# make the moodle directory writeable for owner
chown -R www-data moodle
chmod -R 770 moodle

#Sort out mounting of additional disk
hdd="/dev/sdc"
for i in $hdd;do
echo "n
p
1
w
"|fdisk $i;mkfs.ext3 $i"1";done

#Create Mountpoint
sudo mkdir /var/www
#Mount on startup
echo "Add /dev/sdc1    /var/www   ext4    defaults     0        2" | sudo tee -a /etc/fstab
#Apply changes
Sudo mount -a

# create moodledata directory
mkdir /var/moodledata
chown -R www-data /var/moodledata
chmod -R 770 /var/moodledata

# create cron entry
# It is scheduled for once per day. It can be changed as needed.
echo '* * * * * php /var/www/moodle/admin/cli/cron.php > /dev/null 2>&1' > cronjob
crontab cronjob

# restart MySQL
service mysql restart

# restart Apache
apachectl restart
