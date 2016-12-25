//  IADevice_Current.m
//  FunnyZone
//
//  Created by Winter on 11/10/11.
//  Copyright 2011 PEGATRON. All rights reserved.



#import "IADevice_Current.h"



@implementation TestProgress (IADevice_Current)

//2011-11-10 add by Winter
// Check bit and change NVc5, if bit[0]="4B" and bit[8]="01", return pass. If bit[0]="4B" and bit[8]="05"/"06", send another command.
// Param:
//      NSDictionary    *dicContents        : Settings in script
//      NSMutableString *strReturnValue     : Return value
// Return:
//      Actions result
-(NSNumber*)JUDGE_NVC5:(NSDictionary*)dicContents
		  RETURN_VALUE:(NSMutableString*)strReturnValue
{
    NSString		*strZeroBit			= [dicContents valueForKey:kFZ_ZeroBit];
    NSString		*strFirstBit		= [dicContents valueForKey:kFZ_FirstBit];
	NSString		*strSecondBit		= [dicContents valueForKey:kFZ_SecondBit];
	NSString		*strThirdBit		= [dicContents valueForKey:kFZ_ThirdBit];
    NSDictionary	*dicSendCommand		= [dicContents objectForKey:
										   @"SEND_COMMAND:"];
    NSDictionary	*dicReceiveCommand	= [dicContents objectForKey:
										   @"READ_COMMAND:RETURN_VALUE:"];
    NSArray			*arrResult			= [strReturnValue componentsSeparatedByString:
										   kFunnyZoneBlank1];
    if([arrResult count] >= 10)
	{
		if ([[arrResult objectAtIndex:1] isEqualToString:strZeroBit]) 
		{
			if ([[arrResult objectAtIndex:9] isEqualToString:strFirstBit]) 
			{
                ATSDebug(@"Bit[8] value is %@",[arrResult objectAtIndex:9]);
				return [NSNumber numberWithBool:YES];
			}
			else if ([[arrResult objectAtIndex:9] isEqualToString:strSecondBit]
					 || [[arrResult objectAtIndex:9] isEqualToString:strThirdBit]) 
			{
                ATSDebug(@"Bit[8] value is %@", [arrResult objectAtIndex:9]);
                [self SEND_COMMAND:dicSendCommand];
                [self READ_COMMAND:dicReceiveCommand
					  RETURN_VALUE:strReturnValue];
				return [NSNumber numberWithBool:YES];
			}
			else
			{
				[strReturnValue setString:@"Get error response"];
				return [NSNumber numberWithBool:NO];
			}
		}
		else
		{
			[strReturnValue setString:@"Get error response"];
			return [NSNumber numberWithBool:NO];
		}
	}
	else
	{
		[strReturnValue setString:@"Get error response"];
		return [NSNumber numberWithBool:NO];
	}
}

//2011-11-10 add by Winter
// Two numbers from Hex to Dec, then exchange the position of two numbers
// Param:
//      NSArray  *SourceAry     : Numbers Source Array
//      int   *iIndex           : The number's index in Array
// Return:
//      Actions result
-(unsigned short)PULL_SHORT:(NSArray *)SourceAry
					  INDEX:(int)iIndex
{
    if ([SourceAry count] < iIndex)
        return -1;
    NSString		*strValue1	= [SourceAry objectAtIndex:iIndex];
    NSString		*strValue2	= [SourceAry objectAtIndex:iIndex + 1];
    NSString		*szRealValue;
    unsigned int	iTemp;
    if ([strValue1 substringToIndex:1] == 0) 
        szRealValue		= [NSString stringWithFormat:@"%@%@",
						   strValue2, [strValue1 substringFromIndex:1]];
    else
        szRealValue		= [NSString stringWithFormat:@"%@%@",
						   strValue2, strValue1];
    NSScanner	*scan	= [NSScanner scannerWithString:szRealValue];
    [scan scanHexInt:&iTemp];
    return (unsigned short)iTemp;
}

//2011-11-10 add by Winter
// Only get the Hex value from the response
// Param:
//       NSDictionary    *dicContents        : Settings in script
//       NSMutableString *strReturnValue     : Return value
// Return:
//      Actions result
-(NSNumber*)CONNECT_ARRAY_FOR_BAND:(NSDictionary*)dicContents
					  RETURN_VALUE:(NSMutableString*)strReturnValue
{
	NSArray	*arrReturnValue	= [strReturnValue componentsSeparatedByString:
							   kFunnyZoneSeparate2];
	if ([arrReturnValue count] < 2) 
    {
        [strReturnValue setString:@"Can not get the correct response!"];
		return [NSNumber numberWithBool:NO];
	}
    NSMutableString	*strBit	=[[NSMutableString alloc] init];
    //Get the Hex Value from the response.
	for (int i=0; i < [arrReturnValue count]-1; i++)
	{
		NSArray	*arrTemp	= [[arrReturnValue objectAtIndex:i]
							   componentsSeparatedByString:kFunnyZoneBlank2];
		for (int j=0; j < [arrTemp count]-1; j++) 
		{
			NSArray	*arrBit	= [[arrTemp objectAtIndex:j]
							   componentsSeparatedByString:kFunnyZoneColon1];
			if ([arrBit count] >= 2) 
			{
				NSString	*strTemp	= [NSString stringWithFormat:@"%@ ",
										   [arrBit objectAtIndex:1]];
				[strBit appendString:strTemp];
			}
		}
	}
    [strReturnValue setString:strBit];
    ATSDebug(@"The result String is %@", strReturnValue);
	[strBit release];
	return [NSNumber numberWithBool:YES];
}

//2011-11-10 add by Winter
// Use "PULL_SHORT:Index:" function, if the result >= 900, memory this index
// Param:
//       NSMutableString *strReturnValue     : Return value
// Return:
//      Actions result
-(NSNumber*)GET_PULL_SHORT_I:(NSDictionary*)dicContents
				RETURN_VALUE:(NSMutableString*)strReturnValue
{
    if (![[self CONNECT_ARRAY_FOR_BAND:nil
						  RETURN_VALUE:strReturnValue] boolValue])
    {
        ATSDebug(@"Can not get the value");
        [strReturnValue setString:@"Can not get the value"];
        return [NSNumber numberWithBool:NO];
    }
    unsigned short	val;
	NSArray	*arrReturnValue	= [strReturnValue componentsSeparatedByString:
							   kFunnyZoneBlank1];
	if ([arrReturnValue count] < 68) 
	{
        [strReturnValue setString:@"Can not get the correct response!"];
		return [NSNumber numberWithBool:NO];
	}
	for (int i = 0; i < 32; i++) 
	{
        val	= [self PULL_SHORT:arrReturnValue INDEX:i*2 + 3];
		if (val >= 900) 
		{
			[m_dicMemoryValues setValue:[NSNumber numberWithInt:i]
								 forKey:kFZ_GetPullShortI];
			[strReturnValue setString:[NSString stringWithFormat:@"%d", i]];
            ATSDebug(@"The PullShort i is %d",i);
			break;
		}
	}
	return [NSNumber numberWithBool:YES];
}

//2011-11-10 add by Winter
// Get the index i from m_dicMemoryValues, then calculate the new two indexs to find the WCDMA_COMMAND from the new Array
// Param:
//       NSDictionary    *dicContents        : Settings in script
//       NSMutableString *strReturnValue     : Return value
// Return:
//      Actions result
-(NSNumber*)GET_COMMAND:(NSDictionary*)dicContents
		   RETURN_VALUE:(NSMutableString*)strReturnValue
{
    if (![[self CONNECT_ARRAY_FOR_BAND:nil
						  RETURN_VALUE:strReturnValue] boolValue])
    {
        ATSDebug(@"Can not get the value");
        [strReturnValue setString:@"Can not get the value"];
        return [NSNumber numberWithBool:NO];
    }
    NSArray	*arrReturnValue	= [strReturnValue componentsSeparatedByString:
							   kFunnyZoneBlank1];
    //Get the "PullShortI" to catch the value from this response.
	int	i	= [[m_dicMemoryValues valueForKey:kFZ_GetPullShortI] intValue];
	if ([arrReturnValue count] < 4 + 2 * i) 
    {
        [strReturnValue setString:@"Can not get the correct response!"];
		return [NSNumber numberWithBool:NO];
	}
	else
	{
        NSString	*szCommand	= [NSString stringWithFormat:@"0x%@ 0x%@",
								   [arrReturnValue objectAtIndex:i*2 + 3],
								   [arrReturnValue objectAtIndex:i*2 + 4]];
        [m_dicMemoryValues setValue:szCommand
							 forKey:kFZ_WCDMA_COMMAND];
        ATSDebug(@"The WCDMA_COMMAND value is %@", szCommand);
        return [NSNumber numberWithBool:YES];
	}
	return [NSNumber numberWithBool:NO];
}


// 2011-11-11 added by lucy
// Descripton: get sleep Dlog3,sleep Dlog2,get sleep Dlog1
// Param:
//      NSDictionary    *dicContents        : Settings
//      NSMutableString *strReturnValue     : Return value 
- (NSNumber*)GETSLEEPDATA:(NSDictionary*)dicContents
			 RETURN_VALUE:(NSMutableString*)strReturnValue
{
    
	NSArray		*arrData	= [strReturnValue componentsSeparatedByString:@" mA"];
	int			i;
	NSString	*strStart	= @"";
	NSRange		rangeStart;
	if ([arrData count] >= 3) 
	{
		for(i = 0; i <= 2; i++)
		{
			rangeStart	= [[arrData objectAtIndex:i] rangeOfString:@", "];
			
			if ((NSNotFound != rangeStart.location)
				&& (rangeStart.length>0)
				&& ((rangeStart.location+rangeStart.length)
					<= [[arrData objectAtIndex:i] length]))
				strStart	=[[arrData objectAtIndex:i] substringFromIndex:
							  (rangeStart.location + rangeStart.length)];
            else
            {
                ATSDebug(@"Haven't found the range,please check it!");
                return [NSNumber numberWithBool:NO];
            }
			[m_dicMemoryValues setObject:strStart
								  forKey:[NSString stringWithFormat:
										  @"SleepDLOG%i", 3 - i]];
            ATSDebug(@"the SleepDLOG%i is %@",3-i,strStart);
		}
		return [NSNumber numberWithBool:YES];
	}
	else
	{
		[strReturnValue setString:[NSString stringWithFormat:
								   @"Don't get Sleep data"]];
		return [NSNumber numberWithBool:NO];
	}
    
}

/****************************************************************************************************
 Start 2012.4.23 Add note by Sky_Ge 
 Descripton:  calculate the temperature.
 Param:
 NSMutableString *strReturnValue : the data need to calculate and return value.
 NSDictionary *dicContents : nothing.
 ****************************************************************************************************/
- (NSNumber*)TEMPERATURE:(NSDictionary*)dicContents
			RETURN_VALUE:(NSMutableString*)strReturnValue
{
	BOOL	bRet		= YES;
	double	dValue		= 0.0;
	double	dInputB		= 3435.0;
	double	dR0			= 10000.0;
	double	dT0			= 298.15;
	double	dResistance	= 0.0;
	double	dRRatio		= 0.0;
	double	dTemp		= 0.0;
	double	dResult		= 0.0;
	bRet	= [[NSScanner scannerWithString:strReturnValue]
			   scanDouble:&dValue];
	if (bRet)
	{
		dResistance	= dValue * 2.5 / 4096.0 / 0.00005;
		dRRatio		= log(dResistance / dR0);
		dTemp		= (dRRatio / dInputB) + (1.0 / dT0);
		dResult		= (1.0 / dTemp) - 273.15;
        [strReturnValue setString:[NSString stringWithFormat:
								   @"%0.3f", dResult]];
		return [NSNumber numberWithBool:YES];
	}
	else
        return [NSNumber numberWithBool:NO];
}


@end




