//
//  ServiceProvider.m
//  files
//
//  Created by Scott Penberthy on 3/23/13.
//  Copyright (c) 2013 Scott Penberthy. All rights reserved.
//

#import "ServiceProvider.h"
#import "NSString+Mime.h"

#define kImageFolder @"thumbs"
#define kImageMaxDimension 2048.0

@implementation ServiceProvider

//saving an image
- (NSString *) pathForImage: (NSString *) imageName resized: (BOOL) resized extension: (NSString *) extension
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = [NSTemporaryDirectory() stringByAppendingPathComponent: kImageFolder];
    folder = [folder stringByExpandingTildeInPath];
    NSString *fileName = resized ? [NSString stringWithFormat:@"%@.%@",
                                    [imageName stringByDeletingPathExtension],
                                    extension] : imageName;
    
    if ([fileManager fileExistsAtPath: folder] == NO)
    {
        NSError *error=nil;
        [fileManager createDirectoryAtPath: folder
               withIntermediateDirectories: YES
                                attributes:nil
                                     error: &error];
        if (error) {
            // TODO now what??
            DDLogError(@"Unable to create local directory for screenshots:\n%@",
                  [error localizedDescription]);
        }
    }
    
    return [folder stringByAppendingPathComponent: fileName];
}

- (NSData *) PNGRepresentationOfImage:(NSImage *) image {
    // Create a bitmap representation from the current image
    
    [image lockFocus];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
                                   initWithFocusedViewRect:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [image unlockFocus];
    
    return [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
}

- (NSString *) createThumb: (NSString *) filePath withOutputFile: (NSString *) outputFile
{
    NSSize size = NSMakeSize(256,256);
    NSImage *image = [NSImage imageWithPreviewOfFileAtPath: filePath  ofSize: size asIcon: YES];
    //NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile: filePath];
    //[image setSize:size];
    NSData *imageData = [self PNGRepresentationOfImage: image];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [self pathForImage: [NSString stringWithFormat: @"t_%@", [filePath lastPathComponent]]
                                    resized: YES extension: @"png"];
    if (outputFile == NULL) {
        outputFile = fullPath;
    }
    
    [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
    
    return fullPath;
}

- (NSString *) saveResized: (NSString *) filePath
{
    BOOL resized = NO;
    NSString *ext = NULL;
    NSData *imageData = [self resizedImageDataWithContentsOfPath: filePath resized: &resized extension: &ext];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fullPath = [self pathForImage: [filePath lastPathComponent] resized: resized extension: ext];
    [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
    
    return fullPath;
}


//
// Image resizing
//

- (NSData *) resizedImageDataWithContentsOfPath: (NSString *) path
                                        resized: (BOOL *) resized
                                      extension: (NSString **) extension
{
    *resized = NO;
    
    const CGFloat maxSize = kImageMaxDimension;
    
    // first load the image data from file
    NSURL *pathURL = [NSURL fileURLWithPath: path] ;
    NSData *imageData = [NSData dataWithContentsOfURL: pathURL] ;
        
    // get a bitmap representation of the image data
    NSBitmapImageRep *sourceRep = [[NSBitmapImageRep alloc] initWithData: imageData] ;
    
    CGFloat width = [sourceRep pixelsWide];
    CGFloat height = [sourceRep pixelsHigh];
    
    if ((width <= maxSize) && (height <= maxSize)) {
        return imageData;
    }

    *resized = YES;
    if (width > height) {
        if (width > maxSize) {
            height = (maxSize/width)*height;
            width = maxSize;
        }
    }
    else if (height > maxSize) {
        width = (maxSize/height)*width;
        height = maxSize;
    }
    

    // create a new bitmap representation scaled down
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                                       pixelsWide: (int) floor(width)
                                                                       pixelsHigh: (int) floor(height)
                                                                    bitsPerSample: 8
                                                                  samplesPerPixel: 4
                                                                         hasAlpha: YES
                                                                         isPlanar: NO
                                                                   colorSpaceName: NSCalibratedRGBColorSpace
                                                                      bytesPerRow: 0
                                                                     bitsPerPixel: 0] ;
    
    // save the graphics context, create a bitmap context and set it as current
    [NSGraphicsContext saveGraphicsState] ;
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep: newRep] ;
    
    
    [NSGraphicsContext setCurrentContext: context] ;
    
    // draw the bitmap image representation in it and restore the context
    [sourceRep drawInRect: NSMakeRect(0.0f, 0.0f, (int) floor(width), (int) floor(height))] ;
    [NSGraphicsContext restoreGraphicsState] ;
    
    // set the size of the new bitmap representation
    [newRep setSize: NSMakeSize((int) floor(width), (int) floor(height))];
    
    NSString *mimeType = [[path mimeTypeForPath] lowercaseString];
    if ([mimeType isEqualToString: @"image/jpeg"] ||
        [mimeType isEqualToString: @"image/jpg"]||
        [mimeType isEqualToString: @"image/bmp"]) {
        imageData = [newRep representationUsingType: NSJPEGFileType properties: nil];
        *extension = @"jpg";
    }
    else if ([mimeType isEqualToString: @"image/gif"]) {
         imageData = [newRep representationUsingType: NSGIFFileType properties: nil];
        *extension = @"gif";
    }
    else {
        imageData = [newRep representationUsingType: NSPNGFileType properties: nil];
        *extension = @"png";
    }

    return imageData;
}

- (BOOL) isImagePath: (NSString *) path
{
    NSString *mimeType = [path mimeTypeForPath];
    DDLogInfo(@"Found mime type %@ for %@", mimeType, path);
    return ([mimeType rangeOfString: @"image/"].location == 0);
}


@end
