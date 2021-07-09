#!/bin/bash
AIR_PODS_ADDRESS="4c-b9-10-62-54-ee" # Your AirPods MAC address
AIR_PODS_NAME="asonasのAirPods Pro" # Your AirPods name

$(brew --prefix)/bin/bluetoothconnector -c $AIR_PODS_ADDRESS
for ((i=0 ; i<10 ; i++))
do
    if [ "Connected" == $($(brew --prefix)/bin/bluetoothconnector -s $AIR_PODS_ADDRESS) ]; then
        sleep 1
	$(brew --prefix)/Cellar/switchaudio-osx/1.1.0/SwitchAudioSource -s "$AIR_PODS_NAME"
        sleep 1
        say -v samantha Connected
        break
    fi
    sleep 1
done
