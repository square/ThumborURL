//
//  TUThumborURL.h
//  thumborurl
//
//  Created by Mike Lewis on 4/16/12.
//  Copyright (c) 2012 Square, Inc. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>


@class TUFilter;
@class TUOptions;


typedef enum {
    TUFitInNone = 0,
    TUFitInNormal,
    TUFitInAdaptive
} TUFitInMode;

typedef enum {
    TUVerticalAlignMiddle = 0,
    TUVerticalAlignTop,
    TUVerticalAlignBottom,
} TUVerticalAlignment;

typedef enum {
    TUHorizontalAlignCenter = 0,
    TUHorizontalAlignLeft,
    TUHorizontalAlignRight,
} TUHorizontalAlignment;


// TUEndpoints represent a thumbor endpoint
// An endpoint can either have a global key or a key per image
// If no key is specified, a key per image is required
@interface TUEndpointConfiguration : NSObject

- (id)initWithBaseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;
- (id)initWithBaseURL:(NSURL *)baseURL;

@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic, copy) NSString *globalSecurityKey;

// globalSecurityKey must be set
- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options;

// This one can be used with a per-image security key
- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options securityKey:(NSString *)securityKey;

@end


@interface TUOptions : NSObject <NSCopying>

// Make a copy of options and assign a new size
- (TUOptions *)optionsWithSize:(CGSize)newSize;

@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, assign) BOOL smart;
@property (nonatomic, assign) BOOL debug;
@property (nonatomic, assign) BOOL meta;
@property (nonatomic, assign) CGRect crop;

@property (nonatomic, assign) TUFitInMode fitIn;

@property (nonatomic, assign) TUVerticalAlignment valign;
@property (nonatomic, assign) TUHorizontalAlignment halign;

@property (nonatomic, assign) BOOL vflip;
@property (nonatomic, assign) BOOL hflip;

@property (nonatomic, copy) NSArray *filters;

@property (nonatomic, assign) CGFloat scale;

@end


@interface TUFilter : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *arguments;

+ (id)filterWithName:(NSString *)name argumentsArray:(NSArray *)arguments;
+ (id)filterWithName:(NSString *)name arguments:(id)firstArg, ... NS_REQUIRES_NIL_TERMINATION;

@end


@interface NSURL (ThumborURL)

+ (id)TU_secureURLWithOptions:(TUOptions *)options imageURL:(NSURL *)imageURL baseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;

@end

