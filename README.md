# Tr33 Control

A web interface to control effects on leds strips. It sends UDP packets with the commands to an ESP32 board that controls the leds. The corresponding firmware for the ESP32 can be found [here](https://github.com/xHain-hackspace/tr33).

This app leverages phoenix channels to sync the state between all connected browsers, so everybody sees the same state. The dynamic forms are all rendered in the backend and pushed via a live_html channel to the clients. It is an attempt to create a dynamic web app with almost no javascript.


# ToDo
* color temperature for white
* set single led
* fix first LED
* color palettes
* strip index: all_branches, all_trunk
* export/import presets
* offset for ping_pong
* strip index for rainbow
* revert to sane default
* gravity: scale initial speed