# Tr33 Control

A web interface to control the led tree in the xhain hackerspace. It sends UDP packets with the commands to an ESP32 board that controls the leds. The corresponding firmware can be found [here](https://github.com/xHain-hackspace/tr33).

This app leverages phoenix channels to sync the state between all connected browsers, so everybody sees the same state. The dynamic forms are all rendered in the backend and pushed via a live_html channel to the clients. It is an attempt to create a dynamic web app with almost no javascript.
