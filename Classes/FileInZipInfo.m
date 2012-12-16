//
//  FileInZipInfo.m
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

#import "FileInZipInfo.h"


@implementation FileInZipInfo

- (id) initWithName:(NSString *)name length:(NSUInteger)length level:(ZipCompressionLevel)level crypted:(BOOL)crypted size:(NSUInteger)size date:(NSDate *)date crc32:(NSUInteger)crc32 {
	if (self= [super init]) {
		_name= name;
		_length= length;
		_level= level;
		_crypted= crypted;
		_size= size;
		_date= date;
		_crc32= crc32;
	}
	
	return self;
}


@synthesize name= _name;
@synthesize length= _length;
@synthesize level= _level;
@synthesize crypted= _crypted;
@synthesize size= _size;
@synthesize date= _date;
@synthesize crc32= _crc32;

@end
