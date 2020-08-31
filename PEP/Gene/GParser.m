//
//  GParser.m
//  PEP
//
//  Created by Aaron Elkins on 8/27/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GParser.h"
#import "GObjects.h"

@implementation GParser

+ (id)parser {
    GParser *p = [[GParser alloc] init];
    GLexer *l = [GLexer lexer];
    [p setLexer:l];
    return p;
}

- (void)setLexer:(GLexer*)l {
    lexer = l;
}

- (GLexer*)lexer {
    return lexer;
}

- (void)setStream:(NSData*)s {
    [lexer setStream:s];
    objects = [NSMutableArray array];
}

- (NSMutableArray*)objects {
    return objects;
}

- (NSMutableArray*)parseWithTokens:(NSMutableArray*)tokens {
    NSMutableArray *array = [NSMutableArray array];
    NSUInteger i = 0;
    for (i = 0; i < [tokens count]; i++) {
        GToken *token = [tokens objectAtIndex:i];
        TokenType type = [token type];
        switch (type) {
            case kBooleanToken:
            {
                GBooleanObject *o = [GBooleanObject create];
                [o setType:kBooleanObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            
            case kNumberToken:
            {
                GNumberObject *o = [GNumberObject create];
                [o setType:kNumberObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            
            case kLiteralStringsToken:
            {
                GLiteralStringsObject *o = [GLiteralStringsObject create];
                [o setType:kLiteralStringsObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
                
            case kHexadecimalStringsToken:
            {
                GHexStringsObject *o = [GHexStringsObject create];
                [o setType:kHexStringsObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kNameObjectToken:
            {
                GNameObject *o = [GNameObject create];
                [o setType:kNameObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kArrayObjectToken:
            {
                GArrayObject *o = [GArrayObject create];
                [o setType:kArrayObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kDictionaryObjectToken:
            {
                if (i+1 <= [tokens count] - 1){
                    GToken *token2 = [tokens objectAtIndex:i+1];
                    TokenType type2 = [token2 type];
                    if (type2 == kStreamContentToken) {
                        GDictionaryObject *o = [GDictionaryObject create];
                        [o setType:kDictionaryObject];
                        [o setRawContent:[token content]];
                        [o parse];
                        
                        GStreamObject *s = [GStreamObject create];
                        [s setType:kStreamObject];
                        [s setDictionaryObject:o];
                        [s setStreamContent:[token2 content]];
                        [s parse];
                        [array addObject:s];
                        i++;
                    }
                    break;
                }
                GDictionaryObject *o = [GDictionaryObject create];
                [o setType:kDictionaryObject];
                [o setRawContent:[token content]];
                [o parse];
                [array addObject:o];
                break;
            }
            case kEndToken:
            {
                break;
            }
            default:
                break;
        }
    }
    return array;
}

- (void)parse {
    NSMutableArray *tokens = [NSMutableArray array];
    GToken *t = [lexer nextToken];
    while([t type] != kEndToken) {
        [tokens addObject:t];
        t = [lexer nextToken];
    }
    objects = [self parseWithTokens:tokens];
}
@end
