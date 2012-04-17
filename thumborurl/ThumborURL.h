//
//  TUThumborURL.h
//  thumborurl
//
//  Created by Mike Lewis on 4/16/12.
//  Copyright (c) 2012 Square, Inc. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>


@class TUFilter;


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


@interface TUOptions : NSObject <NSCopying>

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

- (NSArray *)options;
- (NSString *)optionsPath;

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

