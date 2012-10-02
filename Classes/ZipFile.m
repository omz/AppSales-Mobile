//
//  ZipFile.m
//  Objective-Zip v. 0.7.2
//
//  Created by Gianluca Bertani on 25/12/09.
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

#import "ZipFile.h"
#import "ZipException.h"
#import "ZipReadStream.h"
#import "ZipWriteStream.h"
#import "FIleInZipInfo.h"

#define FILE_IN_ZIP_MAX_NAME_LENGTH (256)


@implementation ZipFile


- (id) initWithFileName:(NSString *)fileName mode:(ZipFileMode)mode {
	if (self= [super init]) {
		_fileName= [fileName retain];
		_mode= mode;
		
		switch (mode) {
			case ZipFileModeUnzip:
				_unzFile= unzOpen([_fileName cStringUsingEncoding:NSUTF8StringEncoding]);
				if (_unzFile == NULL) {
					NSString *reason= [NSString stringWithFormat:@"Can't open '%@'", _fileName];
					@throw [[[ZipException alloc] initWithReason:reason] autorelease];
				}
				break;
				
			case ZipFileModeCreate:
				_zipFile= zipOpen([_fileName cStringUsingEncoding:NSUTF8StringEncoding], APPEND_STATUS_CREATE);
				if (_zipFile == NULL) {
					NSString *reason= [NSString stringWithFormat:@"Can't open '%@'", _fileName];
					@throw [[[ZipException alloc] initWithReason:reason] autorelease];
				}
				break;
				
			case ZipFileModeAppend:
				_zipFile= zipOpen([_fileName cStringUsingEncoding:NSUTF8StringEncoding], APPEND_STATUS_ADDINZIP);
				if (_zipFile == NULL) {
					NSString *reason= [NSString stringWithFormat:@"Can't open '%@'", _fileName];
					@throw [[[ZipException alloc] initWithReason:reason] autorelease];
				}
				break;
				
			default: {
				NSString *reason= [NSString stringWithFormat:@"Unknown mode %d", _mode];
				@throw [[[ZipException alloc] initWithReason:reason] autorelease];
			}
		}
	}
	
	return self;
}

- (void) dealloc {
	[_fileName release];
	[super dealloc];
}

- (ZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip compressionLevel:(ZipCompressionLevel)compressionLevel {
	if (_mode == ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted with Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	NSDate *now= [NSDate date];
	NSCalendar *calendar= [NSCalendar currentCalendar];
	NSDateComponents *date= [calendar components:(NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:now];	
	zip_fileinfo zi;
	zi.tmz_date.tm_sec= [date second];
	zi.tmz_date.tm_min= [date minute];
	zi.tmz_date.tm_hour= [date hour];
	zi.tmz_date.tm_mday= [date day];
	zi.tmz_date.tm_mon= [date month] -1;
	zi.tmz_date.tm_year= [date year];
	zi.internal_fa= 0;
	zi.external_fa= 0;
	zi.dosDate= 0;
	
	int err= zipOpenNewFileInZip3(
								  _zipFile,
								  [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding],
								  &zi,
								  NULL, 0, NULL, 0, NULL,
								  (compressionLevel != ZipCompressionLevelNone) ? Z_DEFLATED : 0,
								  compressionLevel, 0,
								  -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
								  NULL, 0);
	if (err != ZIP_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in opening '%@' in zipfile", fileNameInZip];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return [[[ZipWriteStream alloc] initWithZipFileStruct:_zipFile fileNameInZip:fileNameInZip] autorelease];
}

- (ZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip fileDate:(NSDate *)fileDate compressionLevel:(ZipCompressionLevel)compressionLevel {
	if (_mode == ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted with Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	NSCalendar *calendar= [NSCalendar currentCalendar];
	NSDateComponents *date= [calendar components:(NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:fileDate];	
	zip_fileinfo zi;
	zi.tmz_date.tm_sec= [date second];
	zi.tmz_date.tm_min= [date minute];
	zi.tmz_date.tm_hour= [date hour];
	zi.tmz_date.tm_mday= [date day];
	zi.tmz_date.tm_mon= [date month] -1;
	zi.tmz_date.tm_year= [date year];
	zi.internal_fa= 0;
	zi.external_fa= 0;
	zi.dosDate= 0;
	
	int err= zipOpenNewFileInZip3(
								  _zipFile,
								  [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding],
								  &zi,
								  NULL, 0, NULL, 0, NULL,
								  (compressionLevel != ZipCompressionLevelNone) ? Z_DEFLATED : 0,
								  compressionLevel, 0,
								  -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
								  NULL, 0);
	if (err != ZIP_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in opening '%@' in zipfile", fileNameInZip];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return [[[ZipWriteStream alloc] initWithZipFileStruct:_zipFile fileNameInZip:fileNameInZip] autorelease];
}

- (ZipWriteStream *) writeFileInZipWithName:(NSString *)fileNameInZip fileDate:(NSDate *)fileDate compressionLevel:(ZipCompressionLevel)compressionLevel password:(NSString *)password crc32:(NSUInteger)crc32 {
	if (_mode == ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted with Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	NSCalendar *calendar= [NSCalendar currentCalendar];
	NSDateComponents *date= [calendar components:(NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:fileDate];	
	zip_fileinfo zi;
	zi.tmz_date.tm_sec= [date second];
	zi.tmz_date.tm_min= [date minute];
	zi.tmz_date.tm_hour= [date hour];
	zi.tmz_date.tm_mday= [date day];
	zi.tmz_date.tm_mon= [date month] -1;
	zi.tmz_date.tm_year= [date year];
	zi.internal_fa= 0;
	zi.external_fa= 0;
	zi.dosDate= 0;
	
	int err= zipOpenNewFileInZip3(
								  _zipFile,
								  [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding],
								  &zi,
								  NULL, 0, NULL, 0, NULL,
								  (compressionLevel != ZipCompressionLevelNone) ? Z_DEFLATED : 0,
								  compressionLevel, 0,
								  -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
								  [password cStringUsingEncoding:NSUTF8StringEncoding], crc32);
	if (err != ZIP_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in opening '%@' in zipfile", fileNameInZip];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return [[[ZipWriteStream alloc] initWithZipFileStruct:_zipFile fileNameInZip:fileNameInZip] autorelease];
}

- (NSUInteger) numFilesInZip {
	if (_mode != ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted without Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	unz_global_info gi;
	int err= unzGetGlobalInfo(_unzFile, &gi);
	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in getting global info in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return gi.number_entry;
}

- (NSArray *) listFileInZipInfos {
	int num= [self numFilesInZip];
	if (num < 1)
		return [[[NSArray alloc] init] autorelease];
	
	NSMutableArray *files= [[[NSMutableArray alloc] initWithCapacity:num] autorelease];

	[self goToFirstFileInZip];
	for (int i= 0; i < num; i++) {
		FileInZipInfo *info= [self getCurrentFileInZipInfo];
		[files addObject:info];

		if ((i +1) < num)
			[self goToNextFileInZip];
	}

	return files;
}

- (void) goToFirstFileInZip {
	if (_mode != ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted without Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	int err= unzGoToFirstFile(_unzFile);
	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in going to first file in zip in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
}

- (BOOL) goToNextFileInZip {
	if (_mode != ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted without Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	int err= unzGoToNextFile(_unzFile);
	if (err == UNZ_END_OF_LIST_OF_FILE)
		return NO;

	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in going to next file in zip in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return YES;
}

- (BOOL) locateFileInZip:(NSString *)fileNameInZip {
	if (_mode != ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted without Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	int err= unzLocateFile(_unzFile, [fileNameInZip cStringUsingEncoding:NSUTF8StringEncoding], 1);
	if (err == UNZ_END_OF_LIST_OF_FILE)
		return NO;

	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in going to next file in zip in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return YES;
}

- (FileInZipInfo *) getCurrentFileInZipInfo {
	if (_mode != ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted without Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}

	char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
	unz_file_info file_info;
	
	int err= unzGetCurrentFileInfo(_unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in getting current file info in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	NSString *name= [NSString stringWithCString:filename_inzip encoding:NSUTF8StringEncoding];
	
	ZipCompressionLevel level= ZipCompressionLevelNone;
	if (file_info.compression_method != 0) {
		switch ((file_info.flag & 0x6) / 2) {
			case 0:
				level= ZipCompressionLevelDefault;
				break;
				
			case 1:
				level= ZipCompressionLevelBest;
				break;
				
			default:
				level= ZipCompressionLevelFastest;
				break;
		}
	}
	
	BOOL crypted= ((file_info.flag & 1) != 0);
	
	NSDateComponents *components= [[[NSDateComponents alloc] init] autorelease];
	[components setDay:file_info.tmu_date.tm_mday];
	[components setMonth:file_info.tmu_date.tm_mon +1];
	[components setYear:file_info.tmu_date.tm_year];
	[components setHour:file_info.tmu_date.tm_hour];
	[components setMinute:file_info.tmu_date.tm_min];
	[components setSecond:file_info.tmu_date.tm_sec];
	NSCalendar *calendar= [NSCalendar currentCalendar];
	NSDate *date= [calendar dateFromComponents:components];
	
	FileInZipInfo *info= [[FileInZipInfo alloc] initWithName:name length:file_info.uncompressed_size level:level crypted:crypted size:file_info.compressed_size date:date crc32:file_info.crc];
	return [info autorelease];
}

- (ZipReadStream *) readCurrentFileInZip {
	if (_mode != ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted without Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}

	char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
	unz_file_info file_info;
	
	int err= unzGetCurrentFileInfo(_unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in getting current file info in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	NSString *fileNameInZip= [NSString stringWithCString:filename_inzip encoding:NSUTF8StringEncoding];
	
	err= unzOpenCurrentFilePassword(_unzFile, NULL);
	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in opening current file in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return [[[ZipReadStream alloc] initWithUnzFileStruct:_unzFile fileNameInZip:fileNameInZip] autorelease];
}

- (ZipReadStream *) readCurrentFileInZipWithPassword:(NSString *)password {
	if (_mode != ZipFileModeUnzip) {
		NSString *reason= [NSString stringWithFormat:@"Operation not permitted without Unzip mode"];
		@throw [[[ZipException alloc] initWithReason:reason] autorelease];
	}
	
	char filename_inzip[FILE_IN_ZIP_MAX_NAME_LENGTH];
	unz_file_info file_info;
	
	int err= unzGetCurrentFileInfo(_unzFile, &file_info, filename_inzip, sizeof(filename_inzip), NULL, 0, NULL, 0);
	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in getting current file info in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	NSString *fileNameInZip= [NSString stringWithCString:filename_inzip encoding:NSUTF8StringEncoding];

	err= unzOpenCurrentFilePassword(_unzFile, [password cStringUsingEncoding:NSUTF8StringEncoding]);
	if (err != UNZ_OK) {
		NSString *reason= [NSString stringWithFormat:@"Error in opening current file in '%@'", _fileName];
		@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
	}
	
	return [[[ZipReadStream alloc] initWithUnzFileStruct:_unzFile fileNameInZip:fileNameInZip] autorelease];
}

- (void) close {
	switch (_mode) {
		case ZipFileModeUnzip: {
			int err= unzClose(_unzFile);
			if (err != UNZ_OK) {
				NSString *reason= [NSString stringWithFormat:@"Error in closing '%@'", _fileName];
				@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
			}
			break;
		}
			
		case ZipFileModeCreate: {
			int err= zipClose(_zipFile, NULL);
			if (err != ZIP_OK) {
				NSString *reason= [NSString stringWithFormat:@"Error in closing '%@'", _fileName];
				@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
			}
			break;
		}
			
		case ZipFileModeAppend: {
			int err= zipClose(_zipFile, NULL);
			if (err != ZIP_OK) {
				NSString *reason= [NSString stringWithFormat:@"Error in closing '%@'", _fileName];
				@throw [[[ZipException alloc] initWithError:err reason:reason] autorelease];
			}
			break;
		}

		default: {
			NSString *reason= [NSString stringWithFormat:@"Unknown mode %d", _mode];
			@throw [[[ZipException alloc] initWithReason:reason] autorelease];
		}
	}
}


@end
