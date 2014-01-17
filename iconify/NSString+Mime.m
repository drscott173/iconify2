//
//  NSString+Mime.m
//  files
//
//  Created by Scott Penberthy on 4/12/13.
//  Copyright (c) 2013 Scott Penberthy. All rights reserved.
//

#import "NSString+Mime.h"

@implementation NSDictionary (RKRequestSerialization)

- (void)URLEncodePart:(NSMutableArray*)parts path:(NSString*)path value:(id)value {
    NSString *encodedPart = [[value description] stringByAddingURLEncoding];
    [parts addObject:[NSString stringWithFormat: @"%@=%@", path, encodedPart]];
}

- (void)URLEncodeParts:(NSMutableArray*)parts path:(NSString*)inPath {
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *encodedKey = [[key description] stringByAddingURLEncoding];
        NSString *path = inPath ? [inPath stringByAppendingFormat:@"[%@]", encodedKey] : encodedKey;
        
        if ([value isKindOfClass:[NSArray class]]) {
            for (id item in value) {
                if ([item isKindOfClass:[NSDictionary class]] || [item isKindOfClass:[NSMutableDictionary class]]) {
                    [item URLEncodeParts:parts path:[path stringByAppendingString:@"[]"]];
                } else {
                    [self URLEncodePart:parts path:[path stringByAppendingString:@"[]"] value:item];
                }
                
            }
        } else if([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]]) {
            [value URLEncodeParts:parts path:path];
        }
        else {
            [self URLEncodePart:parts path:path value:value];
        }
    }];
}

- (NSString *)stringWithURLEncodedEntries {
    NSMutableArray* parts = [NSMutableArray array];
    [self URLEncodeParts:parts path:nil];
    return [parts componentsJoinedByString:@"&"];
}

- (NSString *)URLEncodedString {
    return [self stringWithURLEncodedEntries];
}

- (NSString *)HTTPHeaderValueForContentType {
    return @"application/x-www-form-urlencoded";
}

- (NSData*)HTTPBody {
    return [[self URLEncodedString] dataUsingEncoding:NSUTF8StringEncoding];
}

@end


@implementation NSString (Mime)

+ (NSString *) stringShowingTimeLeft: (long) msec
{
    int secs = (int) msec/1000;
    int days = secs/(60*60*24);
    int hours = secs/(60*60);
    int mins = secs/(60);
    
    NSString *caption;
    if (days > 1) {
        caption = [NSString stringWithFormat: @"About %d days left ", days];
    }
    else if (days == 1) {
        caption = @"About a day left ";
    }
    else if (hours > 1) {
        caption = [NSString stringWithFormat: @"%d hours to go ", hours];
    }
    else if (hours == 1) {
        caption = @"About an hour left ";
    }
    else if (mins > 5) {
        caption = [NSString stringWithFormat: @"%d mins to go ", mins];
    }
    else if (mins >= 1) {
        caption = @"A few minutes left ";
    }
    else if (secs > 10) {
        caption = @"Under a minute left ";
    }
    else if (secs < 10) {
        caption = @"A few seconds more ";
    }
    else {
        caption = @"Finishing ";
    }
    return caption;
}

- (NSString *)mimeTypeForPath
{
    BOOL isDir = NO;
    NSString *mime;
	NSFileManager *mgr = [NSFileManager defaultManager];
    
    if ([mgr fileExistsAtPath:self isDirectory:&isDir] && isDir)
	{
		mime = @"application/x-directory";
	}
    else {
        // Use the linux 'file' command to test the magic bits of the file
        NSTask *task = [NSTask new];
        NSString *magicPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"magic.mgc"];
        [task setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"file"]];
        [task setArguments: [NSArray arrayWithObjects: @"-m", magicPath, @"-b", @"--mime-type", self, nil]];
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
    
        [task launch];
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        
        mime = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
    }
    if ([mime isEqualToString: @"regular file"] || [mime length] < 3) {
        mime = @"application/octet-stream";
    }
    
    // We force videos to mpeg on upload
    if ([mime rangeOfString: @"video"].location != NSNotFound)
        mime = @"video/mp4"; // FIXME ?
    
    return mime;
}


// RKAdditions

- (NSString *)stringByAppendingQueryParameters:(NSDictionary *)queryParameters {
    if ([queryParameters count] > 0) {
        return [NSString stringWithFormat:@"%@?%@", self, [queryParameters stringWithURLEncodedEntries]];
    }
    return [NSString stringWithString:self];
}

- (NSString *)stringByAddingURLEncoding {
    CFStringRef legalURLCharactersToBeEscaped = CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`\n\r");
    CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                        (__bridge CFStringRef)self,
                                                                        NULL,
                                                                        legalURLCharactersToBeEscaped,
                                                                        kCFStringEncodingUTF8);
    
    if (encodedString) {
       // NSString *result = [NSString stringWithString: (__bridge NSString *) encodedString];
         NSString *result = [NSString stringWithString: CFBridgingRelease(encodedString)];
       // CFRelease(encodedString);
        return result;
    }
    
    // TODO: Log a warning?
    return @"";
}

- (NSString *)stringByReplacingURLEncoding {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
