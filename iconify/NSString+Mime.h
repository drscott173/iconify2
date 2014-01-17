//
//  NSString+Mime.h
//  files
//
//  Created by Scott Penberthy on 4/12/13.
//  Copyright (c) 2013 Scott Penberthy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Mime)
- (NSString *)mimeTypeForPath;
- (NSString *)stringByAppendingQueryParameters:(NSDictionary *)queryParameters;
- (NSString *)stringByAddingURLEncoding ;
+ (NSString *) stringShowingTimeLeft: (long) msec;
@end

@interface NSDictionary (RKRequestSerialization)
- (NSString *)stringWithURLEncodedEntries;
- (NSString *)HTTPHeaderValueForContentType;
- (NSString *)URLEncodedString;
- (NSData*)HTTPBody;
@end