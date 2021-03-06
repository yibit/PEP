//
//  GPage.h
//  PEP
//
//  Created by Aaron Elkins on 9/17/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GObjects.h"
#import "GParser.h"

@class GDocument;

NS_ASSUME_NONNULL_BEGIN

@interface GPage : NSObject {
    GDictionaryObject *pageDictionary;
    GParser *parser;
    NSData *pageContent;
    GDocument *doc;
}

+ (id)create;
- (void)setPageDictionary:(GDictionaryObject*)d;
- (GDictionaryObject*)pageDictionary;
- (void)setParser:(GParser*)p;
- (void)setDocument:(GDocument*)d;
- (void)parsePageContent;
@end

NS_ASSUME_NONNULL_END
