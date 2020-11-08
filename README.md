# Tr33 Control

A web interface to control effects on leds strips. It sends commands to an ESP32 board that controls the leds. The corresponding firmware for the ESP32 can be found [here](https://github.com/xHain-hackspace/tr33). The commands can be send via UDP and UART.

This app leverages phoenix channels to sync the state between all connected browsers, so everybody sees the same state. The dynamic forms are all rendered in the backend and pushed via a live_html channel to the clients. It is an attempt to create a dynamic web app with almost no javascript.


# Bugs/features

* Move modifiers to ESP
  * reverse sawtooth in firmware
* Sync time between ESPs
* Sync random seed betwenn ESPs
* handshake/ack commands and retry
* per command palettes
* add more palettes
* find effect lib
* effects relative to strip height/prixel count
  * gravity height relative to strip length
  * x/per minute relative to pixel count
* multiple instances of rain/sparkle/etc
* fix docs for packet format

## low

* persistence per led structure
* read led_structure from controller
* ping pong sawtooth, fade out
* modifier for palette 
* random walk for tr33
* diffusion (lava lamp) effect
* move slope, or render in general: color shift effect (or similar) instead of solid color 
  * slope -> change/shift color effect 
* bug in mapped slope: use perpendicular distance instead of y distance
* gravity
* beat detection
* option to configure fade vs set in effects
* generally more effects like kaleidoscope
* mapped 2D bouncing ball
* softer sparkle
* fix add ball for gravity


## done
* twang
* joystick plug and play
* move up/down -> no update
* bug: change type when moving command
* type select not working with enabled modifier
* performance with modifiers

## Wont do
* position 16bit
* x for disable
* optionally avoid overlap in random transistion