//
//  GLexer.m
//  PEP
//
//  Created by Aaron Elkins on 8/22/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GLexer.h"

BOOL isWhiteSpace(unsigned char ch) {
    switch (ch) {
        case 0x00:
        case 0x09:
        case 0x0A:
        case 0x0C:
        case 0x0D:
        case 0x20:
            return YES;
        default:
            break;
    }
    return NO;
}

@implementation GToken
+ (id)token {
    GToken *t = [[GToken alloc] init];
    return t;
}
- (void)setType:(int)t {
    type = t;
}

- (int)type {
    return type;
}

- (void)setContent:(NSData *)d {
    content = d;
}

- (NSData*)content {
    return content;
}
@end

@implementation GLexer
+ (id)lexer {
    GLexer *l = [[GLexer alloc] init];
    return l;
}

- (unsigned int)pos {
    return pos;
}

- (void)setStream:(NSData*)s {
    stream = s;
    pos = 0;
}

- (NSData*)stream {
    return stream;
}

- (unsigned char)nextChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    unsigned int len = (unsigned int)[stream length];
    if (pos + 1 <= len - 1){
        pos += 1;
    }
    return *(bytes + pos);
}

- (unsigned char)currentChar {
    unsigned char *bytes = (unsigned char*)[stream bytes];
    return *(bytes + pos);
}

- (NSData *)getNumber {
    unsigned char current = [self currentChar];
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    [d appendBytes:(unsigned char*)&current length:1];
    
    unsigned char next = [self nextChar];
    while(!isWhiteSpace(next)) {
        [d appendBytes:(unsigned char*)&next length:1];
        next = [self nextChar];
    }
    return (NSData*)d;
}

- (NSData*)getLiteralStrings {
    NSMutableData *d = [NSMutableData dataWithCapacity:100];
    unsigned char next = [self currentChar];
    int unbalanced = 1;
    [d appendBytes:(unsigned char*)&next length:1];
    next = [self nextChar];
    if (next == '(') {
        unbalanced += 1;
    } else if (next == ')') {
        unbalanced -= 1;
    }
    while(unbalanced != 0) {
        if (next == '(') {
            unbalanced += 1;
        } else if (next == ')') {
            unbalanced -= 1;
        }
        [d appendBytes:(unsigned char*)&next length:1];
        next = [self nextChar];
    }
    return [NSData dataWithBytes:([d bytes]+1) length:[d length] - 2];
}

- (NSData *)getHexadecimalStrings {
    NSMutableData *d = [NSMutableData dataWithCapacity:1024];
    unsigned char next = [self currentChar];
    [d appendBytes:(unsigned char*)&next length:1];
    next = [self nextChar];
    while(next != '>') {
        [d appendBytes:(unsigned char*)&next length:1];
        next = [self nextChar];
    }
    // Append '0' if the length of hexademical strings is not even
    if ([d length] % 2 != 0){
        [d appendBytes:"0" length:1];
    }
    return (NSData*)d;
}

- (GToken *)nextToken {
    // Consume white spaces before parsing token
    while (isWhiteSpace([self currentChar])) {
        [self nextChar];
    }
    unsigned char current = [self currentChar];
    GToken * token = [GToken token];
    unsigned int start = pos;
    switch (current) {
        case 'f': // 'false'
            if ([self nextChar] == 'a' && [self nextChar] == 'l'
               && [self nextChar] == 's'
               && [self nextChar] == 'e' && isWhiteSpace([self nextChar])){
                [token setType:kBooleanToken];
                unsigned char* bytes = (unsigned char*)[stream bytes];
                NSData *d = [NSData dataWithBytes:bytes + start length:5];
                [token setContent:d];
            }
            break;
            
        case 't': // 'true'
            if ([self nextChar] == 'r' && [self nextChar] == 'u'
                && [self nextChar] == 'e'
                && isWhiteSpace([self nextChar])) {
                [token setType:kBooleanToken];
                unsigned char* bytes = (unsigned char*)[stream bytes];
                NSData *d = [NSData dataWithBytes:bytes + start length:4];
                [token setContent:d];
            }
            break;
            
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '+':
        case '-':
        case '.': // number
            [token setType:kNumberToken];
            [token setContent:[self getNumber]];
            break;
        
        case '(': // literal strings
            [token setType:kLiteralStringsToken];
            [token setContent:[self getLiteralStrings]];
            break;
 
        case '<':
            if ([self nextChar] != '<') {
                [token setType:kHexadecimalStringsToken];
                [token setContent:[self getHexadecimalStrings]];
            }
            break;
            
        default:
            break;
    }
    return token;
}
@end
