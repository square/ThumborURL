//
//  TUThumborURL.h
//  thumborurl
//
//  Created by Mike Lewis on 4/16/12.
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


@class TUFilter;
@class TUOptions;


typedef NS_ENUM(NSUInteger, TUFitInMode) {
    TUFitInNone = 0,
//    TUFitInNormal,
//    TUFitInAdaptive
};

typedef NS_ENUM(NSUInteger, TUVerticalAlignment) {
    TUVerticalAlignMiddle = 0,
//    TUVerticalAlignTop,
//    TUVerticalAlignBottom,
};

typedef NS_ENUM(NSUInteger, TUHorizontalAlignment) {
    TUHorizontalAlignCenter = 0,
//    TUHorizontalAlignLeft,
//    TUHorizontalAlignRight,
};

typedef NS_ENUM(NSUInteger, TUEncryptionMode) {
    TUEncryptionModeHMACSHA1 = 0,
    TUEncryptionModeAES128,
};


/// TUEndpoints represent a thumbor endpoint.
/// An endpoint can either have a global key or a key per image.
/// If no key is specified, a key per image is required.
@interface TUEndpointConfiguration : NSObject

- (id)initWithBaseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;
- (id)initWithBaseURL:(NSURL *)baseURL;

@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic, copy) NSString *globalSecurityKey;

/// Generating secure URLs takes some time, so we cache them in memory.
@property (nonatomic, strong, readonly) NSCache *secureURLCache;

/// For this method, `globalSecurityKey` must be set
- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options;

/// This method can be used with a per-image security key.
- (NSURL *)secureURLWithImageURL:(NSURL *)imageURL options:(TUOptions *)options securityKey:(NSString *)securityKey;

@end


@interface TUOptions : NSObject <NSCopying>

/// Make a copy of options and assign a new size.
- (TUOptions *)optionsBySettingSize:(CGSize)newSize;

@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, assign) BOOL smart;
@property (nonatomic, assign) BOOL trim;
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

@property (nonatomic, assign) TUEncryptionMode encryption;

@end


@interface TUFilter : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *arguments;

+ (id)filterWithName:(NSString *)name argumentsArray:(NSArray *)arguments;
+ (id)filterWithName:(NSString *)name arguments:(id)firstArg, ... NS_REQUIRES_NIL_TERMINATION;

@end


@interface NSURL (ThumborURL)

+ (id)TU_secureURLWithOptions:(TUOptions *)options imageURL:(NSURL *)imageURL baseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;

@property (nonatomic, assign, readonly, getter=isThumborizableURL) BOOL thumborizableURL;
@property (nonatomic, assign, readonly, getter=isThumborizedURL) BOOL thumborizedURL;

@end
