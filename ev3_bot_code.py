#!/usr/bin/env python3
from ev3dev.ev3 import *
from time import sleep

import syslog
syslog.syslog(syslog.LOG_INFO, "EV3 Starting NLVMUG ADV project")

import ev3dev.ev3 as ev3
ev3.Sound.speak('Welcome, my name is EV3!').wait()

import urllib.request

from time import sleep
from ev3dev.ev3 import *

# Connect one small motor on output A and two large motors on output ports B and C
tmotor = MediumMotor('outA')
lmotor = LargeMotor('outB')
rmotor = LargeMotor('outC')

# Connect touch sensor on input 1,color sensor on input 2 and a second color sensor on input 3
ts = TouchSensor('in1')
cl1 = ColorSensor('in2')
cl2 = ColorSensor('in3')

# Connect IR sensor to input 4 for remote control
rc = RemoteControl();

# Check that the motors and sensors are actually connected
assert tmotor.connected
assert lmotor.connected
assert rmotor.connected
assert ts.connected
assert cl1.connected
assert cl2.connected
assert rc.connected

# Put the color sensor into COL-COLOR mode.
cl1.mode='COL-REFLECT'
# colors=('unknown','black','blue','green','yellow','red','white','brown')
cl2.mode='COL-REFLECT'

# Turn leds off
Leds.all_off()

def roll(motor, led_group, direction):
    """
    Generate remote control event handler. It rolls given motor into given
    direction (1 for forward, -1 for backward). When motor rolls forward, the
    given led group flashes green, when backward -- red. When motor stops, the
    leds are turned off.

    The on_press function has signature required by RemoteControl class.
    It takes boolean state parameter; True when button is pressed, False
    otherwise.
    """
    def on_press(state):
        if state:
            # Roll when button is pressed
            motor.run_forever(speed_sp=500*direction)
            Leds.set_color(led_group, direction > 0 and Leds.GREEN or Leds.RED)
        else:
            # Stop otherwise
            motor.stop(stop_action='brake')
            Leds.set(led_group, brightness_pct=0)
    return on_press

def tilt(motor, direction):
    """
    Generate remote control event handler to tilt the gripper.
    Positive speed value moves gripper up, Negative speed value moves gripper down.
    Up/down determined by touch sensor value.

    The on_press function has signature required by RemoteControl class.
    It takes boolean state parameter; True when button is pressed, False
    otherwise.
    """
    def on_press(state):
        if (state and ts.value()):
            motor.run_timed(time_sp=1400, speed_sp=500*direction)
            # ev3.Sound.speak('Got you!').wait()
        elif (state and not ts.value()):
            motor.run_timed(time_sp=1400, speed_sp=-500*direction)
            if (cl1.value() > 40):
                VM_QUARANTINE = 'Un-Secure zone'
                VM_ZONE = 'red'
            else:
                VM_QUARANTINE = 'Microsegmented zone'
                VM_ZONE = 'green'
            print('zone value={}'.format(cl1.value()))
            print(VM_QUARANTINE)
            if (cl2.value() < 10):
                VM_NAME = 'VM1'
            else:
                VM_NAME = 'VM2'
            print('vm value={}'.format(cl2.value()))
            print(VM_NAME)
            syslog.syslog(syslog.LOG_INFO, "EV3 placed %s in the %s" %(VM_NAME, VM_QUARANTINE))
        else:
            # Stop otherwise
            motor.stop(stop_action='brake')

    return on_press


# Assign event handler to each of the remote buttons
rc.on_red_up    = roll(lmotor, Leds.LEFT,   1)
rc.on_red_down  = roll(lmotor, Leds.LEFT,  -1)
rc.on_blue_up   = roll(rmotor, Leds.RIGHT,  1)
rc.on_blue_down = roll(rmotor, Leds.RIGHT, -1)
rc.on_beacon	= tilt(tmotor, 1)

# Enter event processing loop
while True:
    rc.process()
    sleep(0.01)

# Press Ctrl-C to exit
