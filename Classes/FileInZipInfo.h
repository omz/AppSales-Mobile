//
//  FileInZipInfo.h
//  Objective-Zip v. 0.7.2
//
//  Created by Gianluca Bertani on 27/12/09.
//  Copyright 2009-10 Flying Dolphin Studio. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions 
//  are met:
//
//  * Redistributions of source code must retain the above copyright notice, 
//    this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, 
//    this list of conditions and the following disclaimer in the documentation 
//    and/or other materials provided with the distribution.
//  * Neither the name of Gianluca Bertani nor the names of its contributors 
//    may be used to endorse or promote products derived from this software 
//    without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
//  POSSIBILITY OF SUCH DAMAGE.
//

#import <Foundation/Foundation.h>
#import "ZipFile.h"


@interface FileInZipInfo : NSObject {
	
@private
	NSUInteger _length;
	ZipCompressionLevel _level;
	BOOL _crypted;
	NSUInteger _size;
	NSDate *_date;
	NSUInteger _crc32;
	NSString *_name;
}

- (id) initWithName:(NSString *)name length:(NSUInteger)length level:(ZipCompressionLevel)level crypted:(BOOL)crypted size:(NSUInteger)size date:(NSDate *)date crc32:(NSUInteger)crc32;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSUInteger length;
@property (nonatomic, readonly) ZipCompressionLevel level;
@property (nonatomic, readonly) BOOL crypted;
@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSUInteger crc32;

@end
