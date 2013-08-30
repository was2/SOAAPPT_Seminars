#!/usr/bin/ksh
PATH=$PATH:/usr/local/bin
HOME=/home/hercules
export PATH HOME
ORACLE_SID=PROD
ORAENV_ASK=NO
. /home/hercules/.profile
. oraenv

sqlplus pluto/nine9 @/d07/production/CRON_REPORT_DELIVERY/student/sorappt_populate_reqired_seminars.sql | mailx -s 'SORAPPT Seminar Insert Report' drew.sawyer@mgccc.edu 
