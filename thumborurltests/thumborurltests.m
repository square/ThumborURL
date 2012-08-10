//
//  thumborurltests.m
//  thumborurltests
//
//  Created by Mike Lewis on 4/16/12.
//  Copyright (c) 2012 Square Inc. All rights reserved.
//

#import "thumborurltests.h"
#import "ThumborURL.h"


@implementation thumborurltests

- (void)testSimpleURL;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/qcQJp6JpxvDT799fxzjPYxt9A0ooZSeV_NOo-nC0-GN5kvKkWcTfpqwLE5PgFouD/http://twitter.com/foo.png";
    
    STAssertEqualObjects(expectedURL, u.relativeString, @"Should work");
}

- (void)testOpts;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    opts.targetSize = CGSizeMake(20.0f, 20.0f);
    opts.smart = YES;
    opts.fitIn = TUFitInNormal;
    opts.vflip = YES;
    
    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/VN-DQqsh6mSk4bb6biPlIj-IHwbA2IGyC7bPtNuPS4RvyMFh4I76UuuV6dNIjG9fV6FDVsTGF5sD23qD7sMwEg==/http://twitter.com/foo.png";
    
    STAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");
}

- (void)testScale;
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
    
    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/VN-DQqsh6mSk4bb6biPlIj-IHwbA2IGyC7bPtNuPS4RvyMFh4I76UuuV6dNIjG9fV6FDVsTGF5sD23qD7sMwEg==/http://twitter.com/foo.png";
    
    STAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");
}

- (void)testCopy;
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
    
    TUOptions *newOpts = [opts copy];
    
    // Now change opts to make sure the newOpts is unique.
    opts.scale = 1.0f;
    opts.vflip = NO;
    
    NSURL *u = [NSURL TU_secureURLWithOptions:newOpts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/VN-DQqsh6mSk4bb6biPlIj-IHwbA2IGyC7bPtNuPS4RvyMFh4I76UuuV6dNIjG9fV6FDVsTGF5sD23qD7sMwEg==/http://twitter.com/foo.png";
    
    STAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");
}

- (void)testFilters;
{
    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    NSMutableArray *filters = [[NSMutableArray alloc] init];
    [filters addObject:[TUFilter filterWithName:@"watermark" arguments:@"blah.png", @"10", @"20", @"30", nil]];
    [filters addObject:[TUFilter filterWithName:@"watermark" arguments:@"baz.png", @"4", @"8", @"15", nil]];
    
    opts.filters = filters;

    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/ntizt-ZKGa7YNJLoTH7ie6wGXkyJxdzrcqOrtGvhyMQI12qTMRWYGqAki7QTt6miJKiCzgSScrlxGoN_U7tbp_3TNgOmlJUfeoXtwnxQ26RxMT6HzFjuLShitTZ4u015/http://twitter.com/foo.png";
    
    STAssertEqualObjects(expectedURL, u.relativeString, @"Should be equal to command line generated version");    
}

@end
