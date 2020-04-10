//
//  NSData+Compression.h
//  VideoEditKit
//
//  Created by 黄世平 on 2019/3/4.
//  Copyright © 2019 hsp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Compression)
+ (NSData *) dataWithUncompressedContentsOfFile:(NSString *)aFile;


// ================================================================================================
//  base64.h
//  ViewTransitions
//
//  Created by Neo on 5/11/08.
//  Copyright 2008 Kaliware, LLC. All rights reserved.
//
// FOUND HERE http://idevkit.com/forums/tutorials-code-samples-sdk/8-nsdata-base64-extension.html
// ================================================================================================
+ (NSData *) newDataWithBase64EncodedString:(NSString *) string;
- (id) initWithBase64EncodedString:(NSString *) string;

- (NSString *) base64Encoding;
- (NSString *) base64EncodingWithLineLength:(unsigned int) lineLength;



// ================================================================================================
//  NSData+gzip.h
//  Drip
//
//  Created by Nur Monson on 8/21/07.
//  Copyright 2007 theidiotproject. All rights reserved.
//
// FOUND HERE http://code.google.com/p/drop-osx/source/browse/trunk/Source/NSData%2Bgzip.h
// ================================================================================================
- (NSData *)gzipDeflate;
- (NSData *)gzipInflate;
@end
