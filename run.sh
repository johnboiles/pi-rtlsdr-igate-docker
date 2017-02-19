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

configure_beacon () {
	if [ -n "$BEACON_DELAY" ]; then
		echo "BEACON_DELAY: $BEACON_DELAY"
		sed -i -e "s/{{BEACON_DELAY}}/${BEACON_DELAY}/g" $CONF
	else
		sed -i -e "s/{{BEACON_DELAY}}/0:30/g" $CONF
	fi
	if [ -n "$BEACON_EVERY" ]; then
		echo "BEACON_EVERY: $BEACON_EVERY"
		sed -i -e "s/{{BEACON_EVERY}}/${BEACON_EVERY}/g" $CONF
	else
		sed -i -e "s/{{BEACON_EVERY}}/60:00/g" $CONF
	fi
	if [ -n "$BEACON_SYMBOL" ]; then
		echo "BEACON_SYMBOL: $BEACON_SYMBOL"
		sed -i -e "s/{{BEACON_SYMBOL}}/${BEACON_SYMBOL}/g" $CONF
	else
		sed -i -e "s/{{BEACON_SYMBOL}}/igate/g" $CONF
	fi
	if [ -n "$COMMENT" ]; then
		echo "COMMENT: $COMMENT"
		sed -i -e "s/{{COMMENT}}/\"${COMMENT}\"/g" $CONF
	else
		# Strip comment from PBEACON line
		sed -i -e "s/comment={{COMMENT}}//g" $CONF
	fi
}

# Users of this script can either provide LATITUDE & LONGITUDE, NMEA_GPS, or
# GPSD_HOST in order to send position beacons
if [[ -n "$LATITUDE" ]] && [[ -n "$LONGITUDE" ]]; then
	echo "PBEACON LATITUDE: $LATITUDE"
	echo "PBEACON LONGITUDE: $LONGITUDE"
	sed -i -e "s/{{LATITUDE}}/${LATITUDE}/g" $CONF
	sed -i -e "s/{{LONGITUDE}}/${LONGITUDE}/g" $CONF
	sed -i -e "s/#PBEACON/PBEACON/g" $CONF
	configure_beacon
elif [ -n "$NMEA_GPS" ]; then
	echo "NMEA_GPS: $NMEA_GPS"
	# Use % here instead of / since device descriptors typically have / in them
	sed -i -e "s%{{NMEA_GPS}}%${NMEA_GPS}%g" $CONF
	sed -i -e "s/#GPSNMEA/GPSNMEA/g" $CONF
	sed -i -e "s/#TBEACON/TBEACON/g" $CONF
	configure_beacon
elif [ -n "$GPSD_HOST" ]; then
	echo "GPSD_HOST: $GPSD_HOST"
	sed -i -e "s/{{GPSD_HOST}}/${GPSD_HOST}/g" $CONF
	sed -i -e "s/#GPSD/GPSD/g" $CONF
	sed -i -e "s/#TBEACON/TBEACON/g" $CONF
	if [ -n "$GPSD_PORT" ]; then
		echo "GPSD_PORT: $GPSD_PORT"
		sed -i -e "s/{{GPSD_PORT}}/${GPSD_PORT}/g" $CONF
	else
		# Fall back to default gpsd port 2947
		sed -i -e "s/{{GPSD_PORT}}/2947/g" $CONF
	fi
	configure_beacon
fi

if [ -n "$IGFILTER" ]; then
	echo "IGFILTER: $IGFILTER"
	sed -i -e "s|{{IGFILTER}}|${IGFILTER}|g" $CONF
	sed -i -e "s/#IGFILTER/IGFILTER/g" $CONF
fi

echo "Starting Direwolf"
# "-t O" disables colors when logging
rtl_fm -f 144.39M - | direwolf -c $CONF -t 0 -r 24000 -D 1 -
