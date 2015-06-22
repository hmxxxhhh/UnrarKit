//
//  ExtractFilesTests.m
//  UnrarKit
//
//  Created by Dov Frankel on 6/22/15.
//
//

#import <Cocoa/Cocoa.h>
#import "URKArchiveTestCase.h"

@interface ExtractFilesTests : URKArchiveTestCase

@end

@implementation ExtractFilesTests

- (void)testExtractFiles
{
    NSArray *testArchives = @[@"Test Archive.rar",
                              @"Test Archive (Password).rar",
                              @"Test Archive (Header Password).rar"];
    
    NSSet *expectedFileSet = [self.testFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"rar"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *testArchiveName in testArchives) {
        NSLog(@"Testing extraction of archive %@", testArchiveName);
        NSURL *testArchiveURL = self.testFileURLs[testArchiveName];
        NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                      [testArchiveName stringByDeletingPathExtension]];
        NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
        
        NSString *password = ([testArchiveName rangeOfString:@"Password"].location != NSNotFound
                              ? @"password"
                              : nil);
        URKArchive *archive = [URKArchive rarArchiveAtURL:testArchiveURL password:password];
        
        NSError *error = nil;
        BOOL success = [archive extractFilesTo:extractURL.path
                                     overwrite:NO
                                      progress:^(URKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                          NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                      }
                                         error:&error];
        
        XCTAssertNil(error, @"Error returned by unrarFileTo:overWrite:error:");
        XCTAssertTrue(success, @"Unrar failed to extract %@ to %@", testArchiveName, extractURL);
        
        error = nil;
        NSArray *extractedFiles = [fm contentsOfDirectoryAtPath:extractURL.path
                                                          error:&error];
        
        XCTAssertNil(error, @"Failed to list contents of extract directory: %@", extractURL);
        
        XCTAssertNotNil(extractedFiles, @"No list of files returned");
        XCTAssertEqual(extractedFiles.count, expectedFileSet.count,
                       @"Incorrect number of files listed in archive");
        
        for (NSInteger i = 0; i < extractedFiles.count; i++) {
            NSString *extractedFilename = extractedFiles[i];
            NSString *expectedFilename = expectedFiles[i];
            
            XCTAssertEqualObjects(extractedFilename, expectedFilename, @"Incorrect filename listed");
            
            NSURL *extractedFileURL = [extractURL URLByAppendingPathComponent:extractedFilename];
            NSURL *expectedFileURL = self.testFileURLs[expectedFilename];
            
            NSData *extractedFileData = [NSData dataWithContentsOfURL:extractedFileURL];
            NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedFileURL];
            
            XCTAssertTrue([expectedFileData isEqualToData:extractedFileData], @"Data in file doesn't match source");
        }
    }
}

- (void)testExtractFiles_Unicode
{
    NSSet *expectedFileSet = [self.unicodeFileURLs keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop) {
        return ![key hasSuffix:@"rar"];
    }];
    
    NSArray *expectedFiles = [[expectedFileSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *testArchiveName = @"Ⓣest Ⓐrchive.rar";
    NSURL *testArchiveURL = self.unicodeFileURLs[testArchiveName];
    NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                  [testArchiveName stringByDeletingPathExtension]];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    URKArchive *archive = [URKArchive rarArchiveAtURL:testArchiveURL];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(URKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    
    XCTAssertNil(error, @"Error returned by unrarFileTo:overWrite:error:");
    XCTAssertTrue(success, @"Unrar failed to extract %@ to %@", testArchiveName, extractURL);
    
    error = nil;
    NSArray *extractedFiles = [fm contentsOfDirectoryAtPath:extractURL.path
                                                      error:&error];
    
    XCTAssertNil(error, @"Failed to list contents of extract directory: %@", extractURL);
    
    XCTAssertNotNil(extractedFiles, @"No list of files returned");
    XCTAssertEqual(extractedFiles.count, expectedFileSet.count,
                   @"Incorrect number of files listed in archive");
    
    for (NSInteger i = 0; i < extractedFiles.count; i++) {
        NSString *extractedFilename = extractedFiles[i];
        NSString *expectedFilename = expectedFiles[i];
        
        XCTAssertEqualObjects(extractedFilename, expectedFilename, @"Incorrect filename listed");
        
        NSURL *extractedFileURL = [extractURL URLByAppendingPathComponent:extractedFilename];
        NSURL *expectedFileURL = self.unicodeFileURLs[expectedFilename];
        
        NSData *extractedFileData = [NSData dataWithContentsOfURL:extractedFileURL];
        NSData *expectedFileData = [NSData dataWithContentsOfURL:expectedFileURL];
        
        XCTAssertTrue([expectedFileData isEqualToData:extractedFileData], @"Data in file doesn't match source");
    }
}

- (void)testExtractFiles_NoPasswordGiven
{
    NSArray *testArchives = @[@"Test Archive (Password).rar",
                              @"Test Archive (Header Password).rar"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *testArchiveName in testArchives) {
        NSLog(@"Testing extraction archive (no password given): %@", testArchiveName);
        URKArchive *archive = [URKArchive rarArchiveAtURL:self.testFileURLs[testArchiveName]];
        
        NSString *extractDirectory = [self randomDirectoryWithPrefix:
                                      [testArchiveName stringByDeletingPathExtension]];
        NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
        
        
        NSError *error = nil;
        BOOL success = [archive extractFilesTo:extractURL.path
                                     overwrite:NO
                                      progress:^(URKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                          NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                      }
                                         error:&error];
        BOOL dirExists = [fm fileExistsAtPath:extractURL.path];
        
        XCTAssertFalse(success, @"Extract without password succeeded");
        XCTAssertEqual(error.code, URKErrorCodeMissingPassword, @"Unexpected error code returned");
        XCTAssertFalse(dirExists, @"Directory successfully created without password");
    }
}

- (void)testExtractFiles_InvalidArchive
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    URKArchive *archive = [URKArchive rarArchiveAtURL:self.testFileURLs[@"Test File A.txt"]];
    
    NSString *extractDirectory = [self randomDirectoryWithPrefix:@"ExtractInvalidArchive"];
    NSURL *extractURL = [self.tempDirectory URLByAppendingPathComponent:extractDirectory];
    
    NSError *error = nil;
    BOOL success = [archive extractFilesTo:extractURL.path
                                 overwrite:NO
                                  progress:^(URKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
#if DEBUG
                                      NSLog(@"Extracting %@: %f%% complete", currentFile.filename, percentArchiveDecompressed);
#endif
                                  }
                                     error:&error];
    BOOL dirExists = [fm fileExistsAtPath:extractURL.path];
    
    XCTAssertFalse(success, @"Extract invalid archive succeeded");
    XCTAssertEqual(error.code, URKErrorCodeBadArchive, @"Unexpected error code returned");
    XCTAssertFalse(dirExists, @"Directory successfully created for invalid archive");
}

@end
