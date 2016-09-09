# IdentifyUSBMassStorage

[![CI Status](http://img.shields.io/travis/raxcat liu/IdentifyUSBMassStorage.svg?style=flat)](https://travis-ci.org/raxcat liu/IdentifyUSBMassStorage)
[![Version](https://img.shields.io/cocoapods/v/IdentifyUSBMassStorage.svg?style=flat)](http://cocoapods.org/pods/IdentifyUSBMassStorage)
[![License](https://img.shields.io/cocoapods/l/IdentifyUSBMassStorage.svg?style=flat)](http://cocoapods.org/pods/IdentifyUSBMassStorage)
[![Platform](https://img.shields.io/cocoapods/p/IdentifyUSBMassStorage.svg?style=flat)](http://cocoapods.org/pods/IdentifyUSBMassStorage)


- [x] Get VID value from DADiskRef 
- [x] Get PID value from DADiskRef
- [x] Get mounted Volume Path from a DADiskRef
- [x] Watch plugin/plugout event for specific mass storage device by pid and vid.
- [x] Simple
- [ ] Integration of IOKit for usb events

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Add this line of code when you need to know about disk events.

```objectivec
[[IdentifyUSBMassStorage shareManager] addMassStorageDeviceEventListener:self];
```

And implement event delegates

```objectivec
#pragma mark - IdentifyUSBMassStorageEvent

-(NSDictionary*)matchingDict{
    
    //Example of matching: Trancend thumbdrive, pid: 0x1000, vid:0x8564
    return @{ kDiskDevicePropertyVendorID:@(0x8564), kDiskDevicePropertyProductID:@(0x1000) };

//    //Example of matching: pid: 0x1000 only.
//    return @{ kDiskDevicePropertyProductID:@(0x1000) };
//    
//    //Example of matching: vid:0x8564 only.
//    return @{ kDiskDevicePropertyVendorID:@(0x8564) };
//    
//    //Example of no restriction. matching all.
//    return nil;
    
}

-(void)massStorageDeviceDidPlugIn:(DADiskRef)disk{
    
}

-(void)massStorageDeviceDidPlugOut:(DADiskRef)disk{
    
}
```

## Requirements

## Installation

IdentifyUSBMassStorage is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "IdentifyUSBMassStorage"
```

## Author

raxcat liu, raxcat@gmail.com

### Reference

 * [Apple mailing list - Re: BSD device to USB Information](http://lists.apple.com/archives/usb/2007/Nov/msg00038.html)
 * [How to detect and identify mounted and unmounted USB device on Mac using Cocoa](http://burnignorance.com/mac-os-programming-tips/how-to-detect-and-identify-mounted-and-unmounted-usb-device-on-mac-using-cocoa/)
 * [Apple DiskArbitration framework](https://developer.apple.com/library/mac/documentation/DriversKernelHardware/Conceptual/DiskArbitrationProgGuide/Introduction/Introduction.html)



## License

IdentifyUSBMassStorage is available under the MIT license. See the LICENSE file for more info.
