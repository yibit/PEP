//
//  GDocument.m
//  PEP
//
//  Created by Aaron Elkins on 9/9/20.
//  Copyright © 2020 Aaron Elkins. All rights reserved.
//

#import "GDocument.h"
#import "GParser.h"
#import "GDecoders.h"

@implementation GDocument
- (void)awakeFromNib {
    // Resize window
    NSLog(@"View: %@", NSStringFromRect(self.bounds));
    NSRect rect = [[self window] frame];
    rect.size = NSMakeSize(1200, 1024);
    [[self window] setFrame: rect display: YES];
    NSLog(@"View after resizing: %@", NSStringFromRect(self.bounds));
    
    GParser *p = [GParser parser];
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *path = [mainBundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:path];
    [p setStream:d];
       
    GStreamObject *stream = [p getObjectByRef:@"19-0"];
    NSData *decodedFontData = [stream getDecodedStreamContent];
    
    CGDataProviderRef cgdata = CGDataProviderCreateWithCFData((CFDataRef)decodedFontData);
    CGFontRef font = CGFontCreateWithDataProvider(cgdata);
    NSFont *f = (NSFont*)CFBridgingRelease(CTFontCreateWithGraphicsFont(font, 144, nil, nil));
    
    // change font size
    // f = [NSFont fontWithDescriptor:[f fontDescriptor] size:144];
    
    s = [[NSMutableAttributedString alloc] initWithString:@"PEPB"];
    [s addAttribute:NSFontAttributeName value:f range:NSMakeRange(0, 4)];
    [s addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, 4)];
    
    CFRelease(font);
    CFRelease(cgdata);
    
    // Test parsePages
    [self parsePages];
    
    // parse Content of first page
    [[pages firstObject] parsePageContent];
}

- (void)parsePages {
    parser = [GParser parser];
    NSBundle *mainBundle = [NSBundle mainBundle];
    // TODO: Use test_xref.pdf by default without ability to custom file, will
    // do it later
    file = [mainBundle pathForResource:@"test_xref" ofType:@"pdf"];
    NSData *d = [NSData dataWithContentsOfFile:file];
    [parser setStream:d];
    
    // Get trailer
    GDictionaryObject *trailer = [parser getTrailer];
    
    // Get Root ref
    GRefObject *root = [[trailer value] objectForKey:@"Root"];
    NSString *catalogRef = [NSString stringWithFormat:@"%d-%d",
                            [root objectNumber], [root generationNumber]];
    // Get catalog dictionary object
    GDictionaryObject *catalogObject = [parser getObjectByRef:catalogRef];
    GRefObject *pagesRef = [[catalogObject value] objectForKey:@"Pages"];
    // Get pages dictionary object
    GDictionaryObject *pagesObject = [parser getObjectByRef:
                                       [NSString stringWithFormat:@"%d-%d",
                                       [pagesRef objectNumber], [pagesRef generationNumber]]];
    GArrayObject *kids = [[pagesObject value] objectForKey:@"Kids"];
    
    // Get GPage array
    pages = [NSMutableArray array];
    NSArray *array = [kids value];
    NSUInteger i;
    for (i = 0; i < [array count]; i++) {
        GRefObject *ref = (GRefObject*)[array objectAtIndex:i];
        NSString *refString = [NSString stringWithFormat:@"%d-%d",
                               [ref objectNumber], [ref generationNumber]];
        GDictionaryObject *pageDict = [parser getObjectByRef:refString];
        GPage *page = [GPage create];
        [page setPageDictionary:pageDict];
        [page setParser:parser];
        [page setDocument:self];
        [pages addObject:page];
    }
    NSLog(@"[GDocument parsePages] pages: %ld", [pages count]);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSColor *bgColor = [NSColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
    [bgColor set];
    NSRectFill([self bounds]);
    
    [[NSColor whiteColor] set];
    NSRect rect = NSMakeRect(100, 100, 100, 100);
    rect = [self rectFromFlipped:rect];
    NSRectFill(rect);
    
    [s drawAtPoint:NSMakePoint(0, 0)];
    NSLog(@"drawRect called.");
    // Drawing code here.
}

// GDocument's view coordinate origin is at bottom-left which is not flipped.
// For easy pages layout which would use flipped rect (origin at top-left),
// and we can convert the rect from flipped to no flipped.
- (NSRect)rectFromFlipped:(NSRect)r {
    NSRect bounds = [self bounds];
    float height = bounds.size.height;
    NSPoint newOrigin = NSMakePoint(r.origin.x, height - r.origin.y);
    NSRect ret = NSMakeRect(newOrigin.x, newOrigin.y - r.size.height, r.size.width , r.size.height);
    return ret;
}

- (BOOL)isFlipped {
    return NO;
}
@end
