//
//  main.m
//  iconify
//
//  Created by Scott Penberthy on 1/13/14.
//  Copyright (c) 2014 Scott Penberthy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceProvider.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        NSString *path = NULL, *thumb = NULL, *arg = NULL;
        ServiceProvider *sp = [[ServiceProvider alloc] init];
        
        if (argc > 0) {
            arg = [[NSString stringWithFormat: @"%s", argv[1]] lowercaseString];
            if ([arg hasPrefix: @"-h"] || [arg hasPrefix: @"--h"] ||
                [arg hasPrefix: @"-?"] || [arg hasPrefix: @"--?"]) {
                printf("\nUsage: iconify <source filename> <thumb filename>\niconify creates a PNG thumbnail <thumb filename> of <source fielname> using Quicklook.\n\n<thumb filename> is optional.  The resulting thumbnail path is pushed onto the clipboard.\n\n");
                return 0;
            }
            path = arg;
            if (argc > 2) {
                thumb = [NSString stringWithFormat: @"%s", argv[2]];
            }
        }
        
        NSString *returnPath = [sp createThumb: path withOutputFile: thumb];
        
        if (returnPath != NULL) {
            NSPasteboard *pb = [NSPasteboard generalPasteboard];
            NSData *pathData = [returnPath dataUsingEncoding:NSUTF8StringEncoding];
            [pb clearContents];
            [pb setData: pathData forType: NSStringPboardType];
            printf("Thumb: %s", [returnPath cStringUsingEncoding: NSUTF8StringEncoding]);
            return 0;
        }
        else {
            printf("Error: unable to create thumbnail");
            return 1;
        }
    }
}
