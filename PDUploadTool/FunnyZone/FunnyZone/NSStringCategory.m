//
//  NSStringCategory.m
//  FunnyZone
//
//  Created by Kyle Yu on 11-12-28.
//  Copyright 2011年 PEGATRON. All rights reserved.
//

#import "NSStringCategory.h"

@implementation NSString (NSStringCategory)

- (NSInteger)subStringLocation:(NSString *) szStr
{
    NSRange range = [self rangeOfString:szStr];
    
    if ((range.location != NSNotFound) && (range.length > 0) && (range.location+range.length<=[self length])) {
        return range.location;
    }
    else
    {
        return NSNotFound;
    }
}

/*
 * Kyle 2012.12.28
 * method     : ContainString:
 * abstract   : judge whether self include in a string
 * 
 */
- (BOOL)ContainString:(NSString *)szStr
{
    if ([self subStringLocation:szStr] != NSNotFound) 
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(BOOL)beginWith:(NSString*)strBegin
{
	NSRange	range	= [self rangeOfString:strBegin];
	return (NSNotFound != range.location
			&& range.location == 0);
}

-(BOOL)endWith:(NSString*)strEnd
{
	NSRange	range	= [self rangeOfString:strEnd];
	return (NSNotFound != range.location
			&& (range.location + range.length) == [self length]);
}


/*
 * Kyle 2012.12.28
 * method     : SubFrom:include:
 * abstract   : self substring from a string
 * key        : 
 *              include --> result of substring whether include szStr
 */
- (NSString *)SubFrom:(NSString *)szStr include:(BOOL) include
{
    NSInteger iRet = [self subStringLocation:szStr];
    if (NSNotFound != iRet) 
    {
        if (include) 
        {
            return [self substringFromIndex:iRet];
        }
        else
        {
            return [self substringFromIndex:iRet + [szStr length]];
        }
    }
    return self;
}

/*
 * Kyle 2012.12.28
 * method     : SubTo:include:
 * abstract   : self substring to a string
 * key        : 
 *              include --> result of substring whether include szStr
 */
- (NSString *)SubTo:(NSString *)szStr include:(BOOL) include
{
    NSInteger iRet = [self subStringLocation:szStr];
    if (NSNotFound != iRet) 
    {
        if (include) 
        {
            return [self substringToIndex:(iRet + [szStr length])];
        }
        else
        {
            return [self substringToIndex:iRet];
        }
    }
    return self;
}

// add regular expression function, 2014/03/27
#pragma regular expression
-(NSString*)trim
{
	return [self stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(BOOL)matches:(NSString *)strRegex
{
	NSRegularExpression	*regex	= [NSRegularExpression
								   regularExpressionWithPattern:strRegex
								   options:NSRegularExpressionDotMatchesLineSeparators
								   error:nil];
	if(!regex)
		return NO;
	return [regex numberOfMatchesInString:self
								  options:NSMatchingCompleted
									range:NSMakeRange(0, [self length])];
}
-(id)subByRegex:(NSString *)strRegex
		   name:(id)idName
		  error:(NSError **)error
{
	// Generate regular expression.
	NSRegularExpression	*regex	= [NSRegularExpression
								   regularExpressionWithPattern:strRegex
								   options:NSRegularExpressionDotMatchesLineSeparators
								   error:error];
	if(!regex)
		return nil;
	
	// Get sub strings.
	NSArray	*aryResults	= [regex matchesInString:self
										 options:NSMatchingCompleted
										   range:NSMakeRange(0, [self length])];
	NSMutableArray	*arySubs	= [NSMutableArray array];
	for(NSTextCheckingResult *result in aryResults)
		for(NSUInteger i=1; i<[result numberOfRanges]; i++)
		{
			NSRange		range	= [result rangeAtIndex:i];
			NSString	*strSub	= [self substringWithRange:range];
			[arySubs addObject:strSub];
		}
	
	// Generate return value.
	if(![arySubs count])
	{
		if(error)
			*error	= [NSError errorWithDomain:@"com.PEGATRON.J85"
										 code:__LINE__
									 userInfo:[NSDictionary
											   dictionaryWithObject:@"Sub string not found. "
											   forKey:NSLocalizedDescriptionKey]];
		return nil;
	}
	if(!idName)
		return [arySubs objectAtIndex:0];
	if([idName isKindOfClass:[NSArray class]]
	   && ![(NSArray*)idName count])
		return arySubs;
	if([idName isKindOfClass:[NSArray class]]
	   && [(NSArray*)idName count])
	{
		NSMutableDictionary	*dictSubs	= [NSMutableDictionary dictionary];
		for(int i=0; i<[(NSArray*)idName count]; i++)
		{
			if(i >= [arySubs count])
				break;
			NSString	*strKey		= [(NSArray*)idName objectAtIndex:i];
			NSString	*strValue	= [arySubs objectAtIndex:i];
			[dictSubs setObject:strValue forKey:strKey];
		}
		return dictSubs;
	}
	if(error)
		*error	= [NSError errorWithDomain:@"com.PEGATRON.J85M"
									 code:__LINE__
								 userInfo:[NSDictionary
										   dictionaryWithObject:@"Invalid name. "
										   forKey:NSLocalizedDescriptionKey]];
	return nil;
}



@end
