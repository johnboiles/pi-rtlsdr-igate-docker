#!/bin/bash

CONF_TEMPLATE=sdr-igate.conf.template
CONF=sdr-igate.conf

cp $CONF_TEMPLATE $CONF

if [ -z "$MYCALL" ]; then
	echo "MYCALL environment variable must be set e.g. KK6GIP-7"
	exit 1
fi

echo "MYCALL: $MYCALL"
# Replace spots in config file with passed in environment
# -i edits in place
# -e indicates the expression/command to run
sed -i -e "s/{{MYCALL}}/${MYCALL}/g" $CONF

if [ -z "$APRS_PASSWORD" ]; then
	echo "APRS_PASSWORD environment variable must be set e.g. 123456"
	exit 1
fi

sed -i -e "s/{{APRS_PASSWORD}}/${APRS_PASSWORD}/g" $CONF

if [ -z "$IGSERVER" ]; then
    IGSERVER="noam.aprs2.net"
fi

echo "IGSERVER: $IGSERVER"
sed -i -e "s/{{IGSERVER}}/${IGSERVER}/g" $CONF

# TODO: Also support dynamic PBEACONs via gpsd
if [[ -n "$LATITUDE" ]] && [[ -n "$LONGITUDE" ]]; then
	echo "PBEACON LATITUDE: $LATITUDE"
	echo "PBEACON LONGITUDE: $LONGITUDE"
	sed -i -e "s/{{LATITUDE}}/${LATITUDE}/g" $CONF
	sed -i -e "s/{{LONGITUDE}}/${LONGITUDE}/g" $CONF
	sed -i -e "s/#PBEACON/PBEACON/g" $CONF
	if [ -n "$COMMENT" ]; then
		sed -i -e "s/{{COMMENT}}/\"${COMMENT}\"/g" $CONF
		echo "PBEACON COMMENT: $COMMENT"
	else
		# Strip comment from PBEACON line
		sed -i -e "s/comment={{COMMENT}}//g" $CONF
	fi
fi

if [ -n "$IGFILTER" ]; then
	echo "IGFILTER: $IGFILTER"
	sed -i -e "s|{{IGFILTER}}|${IGFILTER}|g" $CONF
	sed -i -e "s/#IGFILTER/IGFILTER/g" $CONF
fi

echo "Starting Direwolf"
# "-t O" disables colors when logging
rtl_fm -f 144.39M - | direwolf -c $CONF -t 0 -r 24000 -D 1 -
