//
//  TUThumborURL.h
//  thumborurl
//
//  Created by Mike Lewis on 4/16/12.
//  Copyright (c) 2012 Mike Lewis. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.


#import <CoreGraphics/CoreGraphics.h>


@interface TUFilter : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *arguments;

+ (id)filterWithName:(NSString *)name argumentsArray:(NSArray *)arguments;
+ (id)filterWithName:(NSString *)name arguments:(id)firstArg, ... NS_REQUIRES_NIL_TERMINATION;

@end

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

- (NSArray *)options;
- (NSString *)optionsPath;

@end


@interface NSURL (ThumborURL)

+ (id)TU_secureURLWithOptions:(TUOptions *)options imageURL:(NSURL *)imageURL baseURL:(NSURL *)baseURL securityKey:(NSString *)securityKey;

@end

