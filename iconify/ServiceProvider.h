//
//  ServiceProvider.h
//  files
//
//  Created by Scott Penberthy on 3/23/13.
//  Copyright (c) 2013 Scott Penberthy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSImage+QuickLook.h"
#import "DDLog.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_ERROR;

@interface ServiceProvider : NSObject
{

}

- (NSString *) createThumb: (NSString *) filePath withOutputFile: (NSString *) outputFile;

@end
