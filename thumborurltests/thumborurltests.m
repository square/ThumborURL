//
//  thumborurltests.m
//  thumborurltests
//
//  Created by Mike Lewis on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "thumborurltests.h"
#import "ThumborURL.h"

@implementation thumborurltests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{

    TUOptions *opts = [[TUOptions alloc] init];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://twitter.com/foo.png"];
    NSURL *baseURL = [NSURL URLWithString:@"http://images.example.com"];
    NSString *key = @"omg152";
    
    NSURL *u = [NSURL TU_secureURLWithOptions:opts imageURL:imageURL baseURL:baseURL securityKey:key];
    NSString *expectedURL = @"/qcQJp6JpxvDT799fxzjPYxt9A0ooZSeV_NOo-nC0-GN5kvKkWcTfpqwLE5PgFouD/http://twitter.com/foo.png";
    
    STAssertEqualObjects(expectedURL, u.relativeString, @"Should work");
}

@end
