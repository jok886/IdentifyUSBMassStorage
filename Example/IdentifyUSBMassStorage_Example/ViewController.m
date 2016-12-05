//
//  ViewController.m
//  IdentifyUSBMassStorage_Example
//
//  Created by brianliu on 2016/9/8.
//  Copyright © 2016年 raxcat liu. All rights reserved.
//

#import "ViewController.h"
@import IdentifyUSBMassStorage;

@interface ViewController () <IdentifyUSBMassStorageEvent>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[IdentifyUSBMassStorage sharedManager] addMassStorageDeviceEventListener:self];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


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

-(void)massStorageDeviceDidPlugOut:(NSString*)path{
    
}

@end
