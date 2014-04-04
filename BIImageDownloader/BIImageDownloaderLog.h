#ifndef Beatrobo_BIImageDownloaderLog_h
#define Beatrobo_BIImageDownloaderLog_h

#import "BILog.h"
#import "BILogAdditionalMacros.h"
#import "BIXcodeConsoleLogger.h"

#define BIImageDownloaderLogContext   @"BIImageDownloaderLogContext"

// Alias
#define BIIDLogTrace(format, ...) __BIOLogTrace(BIImageDownloaderLogContext, 0, format, ##__VA_ARGS__)
#define BIIDLogDebug(format, ...) __BIOLogDebug(BIImageDownloaderLogContext, 0, format, ##__VA_ARGS__)
#define BIIDLogInfo(format, ...)  __BIOLogInfo(BIImageDownloaderLogContext,  0, format, ##__VA_ARGS__)
#define BIIDLogWarn(format, ...)  __BIOLogWarn(BIImageDownloaderLogContext,  0, format, ##__VA_ARGS__)
#define BIIDLogError(format, ...) __BIOLogError(BIImageDownloaderLogContext, 0, format, ##__VA_ARGS__)
#define BIIDLogFatal(format, ...) __BIOLogFatal(BIImageDownloaderLogContext, 0, format, ##__VA_ARGS__)
#define BIIDLog(format, ...)      __BIOLog(BIImageDownloaderLogContext,      0, format, ##__VA_ARGS__)

#endif
