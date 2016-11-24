//
//  IdentifyUSBMassStorage.h
//  Pods
//
//  Created by brianliu on 2016/9/8.
//
//

#import <Foundation/Foundation.h>

//VendorID should be an NSNumber object
extern const NSString * __nonnull const kDiskDevicePropertyVendorID;
//ProductID should be an NSNumber object
extern const NSString * __nonnull const kDiskDevicePropertyProductID;

@protocol IdentifyUSBMassStorageEvent<NSObject>
@optional
/**
 Works only for plugin event.
 
 option keys:
 extern const NSString * __nonnull const kDiskDevicePropertyVendorID;
 extern const NSString * __nonnull const kDiskDevicePropertyProductID;
 */
-(NSDictionary* __nullable)matchingDict;

/**
  Specify matchingDict to the plugin event of your desired vid,pid.
 */
-(void)massStorageDeviceDidPlugIn:(DADiskRef __nonnull)disk;

/**
 All events will be sent. matchingDict has nothing to do with this event.
 Note: After usb mass storage has been plugout, the vid,pid and mounted volume path will all be nil if you try to get them from utility functions.
 */
-(void)massStorageDeviceDidPlugOut:(DADiskRef __nonnull)disk;

@end


@interface IdentifyUSBMassStorage : NSObject

//Get shared singlton manager object.
+(IdentifyUSBMassStorage * __nonnull)sharedManager;

//Utility: Get USB pid (if any) from a DADiskRef. May be 0.
+(int)getPid:(DADiskRef __nonnull)disk;

//Utility: Get USB vid (if any) from a DADiskRef. May be 0.
+(int)getVid:(DADiskRef __nonnull)disk;

//Utility: Get mounted volume path (if any) from a DADiskRef. Nullable.
+(NSString* __nullable)getVolumePath:(DADiskRef __nonnull)disk;

@property (nonatomic, nullable) dispatch_queue_t callbackQueue;

-(void)addMassStorageDeviceEventListener:(id<IdentifyUSBMassStorageEvent> __nonnull )listener;

-(void)removeMassStorageDeviceEventListener:(id<IdentifyUSBMassStorageEvent> __nonnull)listener;

@end
