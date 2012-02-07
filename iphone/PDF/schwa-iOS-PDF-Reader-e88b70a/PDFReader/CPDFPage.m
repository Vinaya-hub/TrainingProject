//
//  CPDFPage.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/20/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFPage.h"

#import "CPDFDocument.h"
#import "CPDFDocument_Private.h"
#import "Geometry.h"

@interface CPDFPage ()
@property (readwrite, nonatomic, assign) CPDFDocument *document;
@property (readwrite, nonatomic, assign) NSInteger pageNumber;
@end

#pragma mark -

@implementation CPDFPage

@synthesize document;
@synthesize pageNumber;
@synthesize cg;

- (id)initWithDocument:(CPDFDocument *)inDocument pageNumber:(NSInteger)inPageNumber;
	{
	if ((self = [super init]) != NULL)
		{
        document = inDocument;
        pageNumber = inPageNumber;
		}
	return(self);
	}

- (void)dealloc
    {
    document = NULL;
    
    if (cg != NULL)
        {
        CGPDFPageRelease(cg);
        cg = NULL;
        }
    //
    [super dealloc];
    }

- (CGPDFPageRef)cg
    {
    if (cg == NULL)
        {
        cg = CGPDFPageRetain(CGPDFDocumentGetPage(self.document.cg, self.pageNumber));
        }
    return(cg);
    }

- (UIImage *)image
    {
    UIImage *theImage = [self.document.cache objectForKey:@"image"];
    if (theImage == NULL)
        {
        CGRect theMediaBox = CGPDFPageGetBoxRect(self.cg, kCGPDFMediaBox);
        
        UIGraphicsBeginImageContext(theMediaBox.size);
        
        CGContextRef theContext = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(theContext);

        // Flip the context so that the PDF page is rendered right side up.
        CGContextScaleCTM(theContext, 1.0, -1.0);
        CGContextDrawPDFPage(theContext, self.cg);

        theImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        [self.document.cache setObject:theImage forKey:@"image" cost:(NSUInteger)ceil(theImage.size.width * theImage.size.height)];
        }
    
    return(theImage);
    }
    
- (UIImage *)imageWithSize:(CGSize)inSize
    {
    UIGraphicsBeginImageContext(inSize);

    CGContextRef theContext = UIGraphicsGetCurrentContext();

	CGContextSaveGState(theContext);

	// First fill the background with white.
	CGContextSetRGBFillColor(theContext, 1.0,1.0,1.0,1.0);
    

    const CGRect theMediaBox = CGPDFPageGetBoxRect(self.cg, kCGPDFMediaBox);
    const CGRect theRenderRect = ScaleAndAlignRectToRect(theMediaBox, (CGRect){ .size = inSize }, ImageScaling_Proportionally, ImageAlignment_Center);

	// Flip the context so that the PDF page is rendered right side up.
	CGContextTranslateCTM(theContext, 0.0, inSize.height);
	CGContextScaleCTM(theContext, 1.0, -1.0);
	
	// Scale the context so that the PDF page is rendered at the correct size for the zoom level.
    CGContextTranslateCTM(theContext, -(theMediaBox.origin.x - theRenderRect.origin.x), -(theMediaBox.origin.y - theRenderRect.origin.y));
	CGContextScaleCTM(theContext, theRenderRect.size.width / theMediaBox.size.width, theRenderRect.size.height / theMediaBox.size.height);	


	CGContextDrawPDFPage(theContext, self.cg);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return(theImage);
    }

- (UIImage *)thumbnail
    {
    NSString *theKey = [NSString stringWithFormat:@"page_%d_image_128x128", self.pageNumber];
    UIImage *theImage = [self.document.cache objectForKey:theKey];
    return(theImage);
    }

@end
