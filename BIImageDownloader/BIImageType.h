#ifndef Beatrobo_BIImageType_h
#define Beatrobo_BIImageType_h

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    #define BIImageType UIImage
#elif TARGET_OS_MAC
    #define BIImageType NSImage
#endif

#endif
