# hwlib
## Project Description
A MATLAB library providing command-and-control support for various remotely-connected test hardware using the National Instruments "VISA" driver.

## How to Use
This library is intended to be used either directly to communicate to test hardware on an ad hoc basis, or as a submodule to other repositories requiring hardware command-and-control support.

To instantiate a hardware object, the following syntax is used:
```matlab
myDevice = modelNumber(address);
```

The address can be a VISA address of a device using any of the serial, TCP/IP, GPIB, or USB interfaces. A list of available addresses in table form can be obtained by running:
```matlab
hardwareList = visadevlist;
```

A function "initializeInstruments" is provided to easily connect to all available recognized hardware devices connected to the PC and group them into a single object array via the command `hardware = initializeInstruments;`. Note that devices connected over the serial interface will not be recognized by this command (as they do not provide a model number over the serial interface) and need to be added to the object array individually.

## How to Contribute
Support for new hardware can easily be added to the library by creating a class definition for the hardware of interest which inherits from the hwDevice class, i.e. `classdef lakeshore335 < hwDevice`, and implements the required get and set methods for the hardware device.
