# Tr33 Control

A web interface to control effects on leds strips. It sends commands to an ESP32 board that controls the leds. The corresponding firmware for the ESP32 can be found [here](https://github.com/xHain-hackspace/tr33). The commands can be send via UDP and UART.

This app leverages phoenix channels to sync the state between all connected browsers, so everybody sees the same state. The dynamic forms are all rendered in the backend and pushed via a live_html channel to the clients. It is an attempt to create a dynamic web app with almost no javascript.

# currents
* mapped shape/slope/... broken? (Tr33 only, strip index 0)
* gravity not working
* select command when last is deleted 
* white color palette
* render position max to 65... (custom params on sliders)
* ping pong count
* mapped ping_pong
* modifier
* color palettes (steal some from wled)
* UART not working for some reason, might be the cable
* using cursors for UI selects
* ping pong period @ 0 crashes
* order branch and trunk indices/PINs
* debounce issues when slider is at the bottom
* Tr33 rainbow broken at trunk/branches crossing

# Bugs/features
* disable button for Commands
* resync button
* Sync time between ESPs
* Sync random seed betwenn ESPs
* find effect lib
* effects relative to strip height/prixel count
  * gravity height relative to strip length
* multiple instances of rain/sparkle/etc
* fix docs for packet format
* modifier_incresae events
* kill uart when there is no connection
* more scaling for bigger structures
* batch UDP commands
* transitions for changes in modifier period (hard)
* Rotate effect, rotate over strips

## low
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

## doing

## done
* wolken index
* rainbow_width and size @ 0 (Tr33 only, strip index 0)
* Wolken -> one structure, multiple strip indexes

* Tr33: fix extended LedStructure functions
* single color always overwrites (Tr33 only, strip index 0)
* fix wifi status overlay
* Strip index -> 0 == all
* per command palettes
* fix max validations => inputs/data as proper data structures?
* render effect: position 2 bytes
* add more palettes
* strip index select does not work
* send sync request on boot
* discard live view sessions on restart/reconnect
* Move modifiers to ESP
  * reverse sawtooth in firmware
* twang
* joystick plug and play
* move up/down -> no update
* bug: change type when moving command
* type select not working with enabled modifier
* performance with modifiers
  * x/per minute relative to pixel count
* double check modifier migration
* fix strip_index


## Wont do
* cleanup: get rid of pub_sub rate limit (maybe not?)
* handshake/ack commands and retry
* position 16bit
* x for disable
* optionally avoid overlap in random transistion
* persistence per led structure