//
//  ThumborURLTests.m
//  thumborurltests
//
//  Created by Mike Lewis on 4/16/12.
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "ThumborURL.h"

#import <XCTest/XCTest.h>


@interface ThumborURLTests : XCTestCase
@end


@implementation ThumborURLTests

- (void)testSimpleURLAES;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";

    opts.encryption = TUEncryptionModeAES128;
    
    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/qcQJp6JpxvDT799fxzjPYxt9A0ooZSeV_NOo-nC0-GN5kvKkWcTfpqwLE5PgFouD/http://twitter.com/foo.png";
    
    XCTAssertEqualObjects(expectedURL, u.relativeString, @"Should work");
}

- (void)testOptsAES;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    opts.targetSize = CGSizeMake(20.0f, 20.0f);
    opts.smart = YES;
    opts.fitIn = TUFitInNormal;
    opts.vflip = YES;
    opts.encryption = TUEncryptionModeAES128;
    
    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/VN-DQqsh6mSk4bb6biPlIj-IHwbA2IGyC7bPtNuPS4RvyMFh4I76UuuV6dNIjG9fV6FDVsTGF5sD23qD7sMwEg==/http://twitter.com/foo.png";
    
    XCTAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");
}

- (void)testScaleAES;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    opts.targetSize = CGSizeMake(10.0f, 10.0f);
    opts.smart = YES;
    opts.fitIn = TUFitInNormal;
    opts.vflip = YES;
    opts.scale = 2.0f;
    opts.encryption = TUEncryptionModeAES128;
    
    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/VN-DQqsh6mSk4bb6biPlIj-IHwbA2IGyC7bPtNuPS4RvyMFh4I76UuuV6dNIjG9fV6FDVsTGF5sD23qD7sMwEg==/http://twitter.com/foo.png";
    
    XCTAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");
}

- (void)testCopyAES;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];    
    NSString *key = @"omg152";
    
    opts.targetSize = CGSizeMake(10.0f, 10.0f);
    opts.smart = YES;
    opts.fitIn = TUFitInNormal;
    opts.vflip = YES;
    opts.scale = 2.0f;
    opts.encryption = TUEncryptionModeAES128;
    
    TUOptions *newOpts = [opts copy];
    
    // Now change opts to make sure the newOpts is unique.
    opts.scale = 1.0f;
    opts.vflip = NO;
    
    NSURL *u = [NSURL TU_secureURLWithOptions:newOpts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/VN-DQqsh6mSk4bb6biPlIj-IHwbA2IGyC7bPtNuPS4RvyMFh4I76UuuV6dNIjG9fV6FDVsTGF5sD23qD7sMwEg==/http://twitter.com/foo.png";
    
    XCTAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");
}

- (void)testFiltersAES;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    NSMutableArray *filters = [[NSMutableArray alloc] init];
    [filters addObject:[TUFilter filterWithName:@"watermark" arguments:@"blah.png", @"10", @"20", @"30", nil]];
    [filters addObject:[TUFilter filterWithName:@"watermark" arguments:@"baz.png", @"4", @"8", @"15", nil]];
    
    opts.filters = filters;
    opts.encryption = TUEncryptionModeAES128;

    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/ntizt-ZKGa7YNJLoTH7ie6wGXkyJxdzrcqOrtGvhyMQI12qTMRWYGqAki7QTt6miJKiCzgSScrlxGoN_U7tbp_3TNgOmlJUfeoXtwnxQ26RxMT6HzFjuLShitTZ4u015/http://twitter.com/foo.png";
    
    XCTAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");    
}

- (void)testSimpleURLHMAC;
{
    TUOptions *opts = [[TUOptions alloc] init];

    NSURL *imageURL = [NSURL URLWithString:@"twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";

    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/yfI2JhRv0z312pPzm_vE6U4cURM=/twitter.com/foo.png";

    XCTAssertEqualObjects(expectedURL, u.relativeString, @"Should work");
}

- (void)testOptsHMAC;
{
    TUOptions *opts = [[TUOptions alloc] init];

    NSURL *imageURL = [NSURL URLWithString:@"twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";

    opts.crop = CGRectMake(20, 20, 20, 20);
    opts.smart = YES;
    opts.targetSize = CGSizeMake(10, 10);
    opts.fitIn = TUFitInNormal;
    opts.vflip = YES;

    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/aOH7-AuI2kyIb4d9TLbcBdDlGwk=/20x20:40x40/fit-in/10x-10/smart/twitter.com/foo.png";

    XCTAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");
}

- (void)testSizeTruncatesDecimals;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    // Thumbor only supports integer sizes, so these floats should be truncated to 10x10 in the final URL.
    NSURL *urlFromDecimalSize = [NSURL TU_secureURLWithOptions:[opts optionsBySettingSize:CGSizeMake(10.25f, 10.75f)] imageURL:imageURL baseURL:baseURL securityKey:key];
    NSURL *urlFromIntegerSize = [NSURL TU_secureURLWithOptions:[opts optionsBySettingSize:CGSizeMake(10, 10)] imageURL:imageURL baseURL:baseURL securityKey:key];
    
    XCTAssertEqualObjects(urlFromDecimalSize, urlFromIntegerSize, @"Should be equal due to decimal truncation");
}


@end
