//
//  IdentifyUSBMassStorage.m
//  Pods
//
//  Created by brianliu on 2016/9/8.
//
//

#import "IdentifyUSBMassStorage.h"
@import IOKit;
@import DiskArbitration;

const NSString * const kDiskDevicePropertyVendorID = @"kDiskDevicePropertyVendorID";
const NSString * const kDiskDevicePropertyProductID = @"kDiskDevicePropertyProductID";

#define err_get_system(err)     (((err)>>26)&0x3f)
#define err_get_sub(err)        (((err)>>14)&0xfff)
#define err_get_code(err)       ((err)&0x3fff)


//Private
@interface IdentifyUSBMassStorage ()

-(void)diskGotVolumePath:(DADiskRef __nonnull)disk;

-(void)diskGotRemoved:(DADiskRef __nonnull)disk;

@end

static io_service_t findUSBDeviceForMedia(io_service_t media);
static bool getVidAndPid(io_service_t device, int *vid, int *pid);

void showError(kern_return_t err){
    NSLog(@"[kern_return_t] system 0x%x, sub 0x%x, code 0x%x", err_get_system(err), err_get_sub(err), err_get_code(err));
}

void got_Volumed(DADiskRef disk, CFArrayRef keys, void *context)
{
    CFDictionaryRef dict = DADiskCopyDescription(disk);
    CFURLRef fspath = CFDictionaryGetValue(dict, kDADiskDescriptionVolumePathKey);
    
    char buf[MAXPATHLEN];
    if (CFURLGetFileSystemRepresentation(fspath, false, (UInt8 *)buf, sizeof(buf))) {
        //        printf("Disk %s is now at %s\nChanged keys:\n", DADiskGetBSDName(disk), buf);
        IdentifyUSBMassStorage * manager = (__bridge IdentifyUSBMassStorage*)context;
        [manager diskGotVolumePath:disk];
        
    } else {
        /* Something is *really* wrong. */
    }
}

void got_disk_removal(DADiskRef disk, void *context)
{
    //    printf("Disk removed: %s\n", DADiskGetBSDName(disk));
    IdentifyUSBMassStorage * manager = (__bridge IdentifyUSBMassStorage*)context;
    [manager diskGotRemoved:disk];
}

//Once you get the io_service_t from DADiskCopyIOMedia,
//you can call this function to get the IOUSBDevice
//object:
static io_service_t findUSBDeviceForMedia(io_service_t media)
{
    IOReturn status = kIOReturnSuccess;
    
    io_iterator_t		iterator = 0;
    io_service_t 		retService = 0;
    
    if (media == 0)
        return retService;
    
    status = IORegistryEntryCreateIterator(media,
                                           kIOServicePlane, (kIORegistryIterateParents |
                                                             kIORegistryIterateRecursively), &iterator);
    if (iterator == 0) {
        status = kIOReturnError;
    }
    
    if (status == kIOReturnSuccess)
    {
        io_service_t service = IOIteratorNext(iterator);
        while (service)
        {
            io_name_t serviceName;
            kern_return_t kr =
            IORegistryEntryGetNameInPlane(service,
                                          kIOServicePlane, serviceName);
            if ((kr == 0) && (IOObjectConformsTo(service,
                                                 "IOUSBDevice"))) {
                retService = service;
                break;
            }
            service = IOIteratorNext(iterator);
        }
    }
    return retService;
}
//http://lists.apple.com/archives/usb/2007/Nov/msg00038.html
//Once you get the IOUSBDevice object, you get the
//vendor ID and product ID by calling this function:

static bool getVidAndPid(io_service_t device, int *vid, int *pid)
{
    bool success = false;
    
    CFNumberRef	cfVendorId =
    (CFNumberRef)IORegistryEntryCreateCFProperty(device,
                                                 CFSTR("idVendor"), kCFAllocatorDefault, 0);
    if (cfVendorId && (CFGetTypeID(cfVendorId) ==
                       CFNumberGetTypeID()))
    {
        Boolean result;
        result = CFNumberGetValue(cfVendorId,
                                  kCFNumberSInt32Type, vid);
        CFRelease(cfVendorId);
        if (result)
        {
            CFNumberRef	cfProductId =
            (CFNumberRef)IORegistryEntryCreateCFProperty(device,
                                                         CFSTR("idProduct"), kCFAllocatorDefault, 0);
            if (cfProductId && (CFGetTypeID(cfProductId) ==
                                CFNumberGetTypeID()))
            {
                Boolean result;
                result = CFNumberGetValue(cfProductId,
                                          kCFNumberSInt32Type, pid);
                CFRelease(cfProductId);
                if (result)
                {
                    success = true;
                }
            }
        }
    }
    
    return (success);
}


@interface IdentifyUSBMassStorage ()
{
    DASessionRef _session;
    NSMutableArray * _listeners;
}
@end


@implementation IdentifyUSBMassStorage

+(IdentifyUSBMassStorage*)sharedManager{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(id)init{
    self = [super init];
    if(self){
        _listeners = [NSMutableArray new];
        _session = DASessionCreate(kCFAllocatorDefault);
        
        CFMutableArrayRef keys = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
        
        //Watch for disks that got new volume path
        CFArrayAppendValue(keys, kDADiskDescriptionVolumePathKey);
        DARegisterDiskDescriptionChangedCallback(_session,
                                                 NULL, /* match all disks */
                                                 keys, /* match the keys specified above */
                                                 got_Volumed,
                                                 (__bridge void *)(self));
        
        DARegisterDiskDisappearedCallback(_session,
                                          NULL,
                                          got_disk_removal,
                                          (__bridge void *)(self));
        
        DASessionSetDispatchQueue(_session, dispatch_get_main_queue());
        
    }
    return self;
}

-(void)dealloc{
    if(_session){
        CFRelease(_session);
    }
}

-(dispatch_queue_t)callbackQueue{
    if(_callbackQueue==nil){
        return dispatch_get_main_queue();
    }
    return _callbackQueue;
}

-(void)addMassStorageDeviceEventListener:(id<IdentifyUSBMassStorageEvent> __nonnull)listener{
    [_listeners addObject:[NSValue valueWithNonretainedObject:listener]];
    
    NSArray<NSURL*>* currentList = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:@[NSURLVolumeNameKey, NSURLVolumeIsRemovableKey, NSURLVolumeIsEjectableKey] options:nil];
    
    for (NSURL * url in currentList) {
        //        NSLog(@"%@", url.path);
        if(url.path.length > 0 ){
            DADiskRef disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, _session, (__bridge CFURLRef) url);
            //            NSLog(@"%p", disk);
            [self diskGotVolumePath:disk];
        }
    }
    
    //    NSLog(@"%@", currentList);
    
    
}

-(void)removeMassStorageDeviceEventListener:(id<IdentifyUSBMassStorageEvent> __nonnull)listener{
    [_listeners removeObject:[NSValue valueWithNonretainedObject:listener]];
}

-(void)diskGotRemoved:(DADiskRef __nonnull)disk{
    int vid = [[self class] getVid:disk];
    int pid = [[self class] getPid:disk];
    NSString * volumePath = [[self class] getVolumePath:disk];
    //    NSLog(@"removed ----> vid: 0x%x, pid:0x%x, volume path:%@", vid, pid, volumePath);
    for (NSValue * value in _listeners) {
        id<IdentifyUSBMassStorageEvent> listener = [value nonretainedObjectValue];
        NSDictionary * matchingDict = nil;
        if([listener respondsToSelector:@selector(matchingDict)]){
            matchingDict = [listener matchingDict];
        }
        if(matchingDict.allKeys.count == 0){    //matching all
            dispatch_async(self.callbackQueue, ^{
                [listener massStorageDeviceDidPlugOut:volumePath];
            });
        }else if(matchingDict.allKeys.count == 1){
            if(matchingDict[kDiskDevicePropertyProductID] != nil ){
                int matchingPid = ((NSNumber*)matchingDict[kDiskDevicePropertyProductID]).intValue;
                if (matchingPid == pid) {
                    dispatch_async(self.callbackQueue, ^{
                        [listener massStorageDeviceDidPlugOut:volumePath];
                    });
                }
            }
            else if(matchingDict[kDiskDevicePropertyVendorID] != nil ){
                int matchingVid = ((NSNumber*)matchingDict[kDiskDevicePropertyVendorID]).intValue;
                if(matchingVid == vid){
                    dispatch_async(self.callbackQueue, ^{
                        [listener massStorageDeviceDidPlugOut:volumePath];
                    });
                }
            }
        }else{
            int matchingPid = ((NSNumber*)matchingDict[kDiskDevicePropertyProductID]).intValue;
            int matchingVid = ((NSNumber*)matchingDict[kDiskDevicePropertyVendorID]).intValue;
            
            if(matchingVid == vid && matchingPid == pid){
                dispatch_async(self.callbackQueue, ^{
                    [listener massStorageDeviceDidPlugOut:volumePath];
                });
            }
        }
        
    }
    
}

-(void)diskGotVolumePath:(DADiskRef)disk{
    
    int vid = [[self class] getVid:disk];
    int pid = [[self class] getPid:disk];
    
    for (NSValue * value in _listeners) {
        id<IdentifyUSBMassStorageEvent> listener = [value nonretainedObjectValue];
        NSDictionary * matchingDict = nil;
        
        if([listener respondsToSelector:@selector(matchingDict)]){
            matchingDict = [listener matchingDict];
        }
        if(matchingDict.allKeys.count == 0){    //matching all
            CFRetain(disk);
            dispatch_async(self.callbackQueue, ^{
                [listener massStorageDeviceDidPlugIn:disk];
                CFRelease(disk);
            });
        }else if(matchingDict.allKeys.count == 1){    //matching one of them
            
            if(matchingDict[kDiskDevicePropertyProductID] != nil ){
                int matchingPid = ((NSNumber*)matchingDict[kDiskDevicePropertyProductID]).intValue;
                if (matchingPid == pid) {
                    CFRetain(disk);
                    dispatch_async(self.callbackQueue, ^{
                        [listener massStorageDeviceDidPlugIn:disk];
                        CFRelease(disk);
                    });
                }
            }
            else if(matchingDict[kDiskDevicePropertyVendorID] != nil ){
                int matchingVid = ((NSNumber*)matchingDict[kDiskDevicePropertyVendorID]).intValue;
                if(matchingVid == vid){
                    CFRetain(disk);
                    dispatch_async(self.callbackQueue, ^{
                        [listener massStorageDeviceDidPlugIn:disk];
                        CFRelease(disk);
                    });
                }
            }
        }else{
            int matchingPid = ((NSNumber*)matchingDict[kDiskDevicePropertyProductID]).intValue;
            int matchingVid = ((NSNumber*)matchingDict[kDiskDevicePropertyVendorID]).intValue;
            
            if(matchingVid == vid && matchingPid == pid){
                CFRetain(disk);
                dispatch_async(self.callbackQueue, ^{
                    [listener massStorageDeviceDidPlugIn:disk];
                    CFRelease(disk);
                });
            }
        }
    }
    
    
    //    NSString * volumePath = [[self class] getVolumePath:disk];
    //    NSLog(@"vid: 0x%x, pid:0x%x, volume path:%@", vid, pid, volumePath);
    
    
}








+(io_service_t)getUSBDeviceFromDisk:(DADiskRef)disk{
    return findUSBDeviceForMedia(DADiskCopyIOMedia(disk));
}

+(int)getPid:(DADiskRef)disk{
    io_service_t usb = [[self class] getUSBDeviceFromDisk:disk];
    int pid = 0;
    int vid = 0;
    
    getVidAndPid(usb, &vid, &pid);
    return pid;
}

+(int)getVid:(DADiskRef)disk{
    io_service_t usb = [[self class] getUSBDeviceFromDisk:disk];
    int pid = 0;
    int vid = 0;
    
    getVidAndPid(usb, &vid, &pid);
    return vid;
}

+(NSString*__nullable)getVolumePath:(DADiskRef)disk{
    
    
    CFDictionaryRef diskinfo;
    diskinfo = DADiskCopyDescription(disk);
    if (diskinfo == NULL){
        return nil;
    }
    CFURLRef fspath = CFDictionaryGetValue(diskinfo, kDADiskDescriptionVolumePathKey);
    
    char buf[MAXPATHLEN];
    if (CFURLGetFileSystemRepresentation(fspath, false, (UInt8 *)buf, sizeof(buf))) {
        return  [NSString stringWithUTF8String:buf];
        
        /* Print the complete dictionary for debugging. */
        
    } else {
        /* Something is *really* wrong. */
    }
    
    return nil;
    
}

@end
