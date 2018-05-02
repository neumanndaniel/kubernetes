#!/bin/bash
globalpath=$(find /hana -name global.ini | awk -F global.ini '{ print $1 }') \
    && cd $globalpath \
    && chmod 777 global.ini \
    && chmod 777 . \
    && sed -i 's/^use_default_route=ip/use_default_route=no/g' ./global.ini \
    && cd /usr/sap/HXE/HDB90 \
    && HDB restart
