# Tr33 Control

A web interface to control effects on leds strips. It sends commands to an ESP32 board that controls the leds. The corresponding firmware for the ESP32 can be found [here](https://github.com/xHain-hackspace/tr33). The commands can be send via UDP and UART.

This app leverages phoenix channels to sync the state between all connected browsers, so everybody sees the same state. The dynamic forms are all rendered in the backend and pushed via a live_html channel to the clients. It is an attempt to create a dynamic web app with almost no javascript.


# Bugs/features

* gravity height relative to strip length
* persistence per led structure
* reverse sawtooth in firmware
* read led_structure from controller
* position 16bit
* ping pong sawtooth, fade out
* modifier for palette 
* random walk for tr33
* joystick plug and play
* diffusion (lava lamp) effect
* move slope, or render in general: color shift effect (or similar) instead of solid color 
* twang
* gravity
* beat detection
* option to configure fade vs set in effects
* slope -> change/shift color effect 
* generally more effects like kaleidoscope
* bug in mapped slope: use perpendicular distance instead of y distance
* mapped 2D bouncing ball
* multiple rain/sparkle in parallel


## Fixed
* move up/down -> no update
* bug: change type when moving command
* type select not working with enabled modifier
* performance with modifiers

## Wont do
* x for disable
* optionally avoid overlap in random transistion