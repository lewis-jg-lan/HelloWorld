//
//  IADevice_CB.m
//  Izual_Lu
//
//  Created by Lu Izual on 11-5-5.
//  Copyright 2011�?PEGATRON. All rights reserved.
//

#import "IADevice_CB.h"
#import "CB_TestBase.h"

#include <CommonCrypto/CommonDigest.h>

// UUID for the stations, update at Tanz p1
#define kFZ_GRP_MINUS1_UUID               @"2CB9AA6603DA3FF7BC994A76E3CAC4471BD022D9"
#define kFZ_IPAD1_UUID                    @"7F2DAC9F86AC033145529DB90C77D36105BAA006"
#define kFZ_GROUNDING_UUID                @"F6D6D792461C240A350DD7C14668329DC426B482"
#define kFZ_QT0_UUID                      @"6EE6A0C00D37566330F4350E0585729724590F26"
#define kFZ_QT0b_UUID                     @"62C401E98DDBB6D325180698280FF034747FDD82"
#define kFZ_QT1_UUID                      @"160F34E183BA352C7A99A9EF6527113A8A6D1AFE"
#define kFZ_CONNECTIVITY_UUID             @"7E04C11B2B8863932B739D3646EB0325AA80E62D"
#define kFZ_PROXCAL_UUID                  @"214161629C5AB6A7972B2F99C10C85E1A7DEF99F"
#define kFZ_PROXSUS_UUID                  @"26B28C891789BD35789BEBE7A4993C36ABF6564B"
#define kFZ_MAGNET_COVER_UUID             @"50029B86ED5265F0C7C764B888F066FFF8A863D1"
#define kFZ_MAGNET_SPINE_UUID             @"E5862CADD7006612681B00006605FF548C700272"
#define kFZ_HALL_EFFECT_UUID              @"BCA0B4CDFAAA94F820057BF843E473973BFC7075"
#define KFZ_GRAPE_OFFSET_UUID             @"A63CCF9D2B3A5DE15342336E89DE9622BF51E1AC"
#define kFZ_CONNECTIVITY2_UUID            @"1D27A2B87F363397D40844CBB3D7DF094F86329C"
#define KFZ_CURRENT_POSTBURN_UUID         @"85A642236E25BFf64CCAB30d13795A04A8C83F33"
#define KFZ_FOS_UUID                      @"A3B30E718B0B20528C541BF3F11A70478094B37C"
#define kFZ_PRESSURE_UUID                 @"BEA698553453CEF866E3871C59FC42803076258B"
#define kFZ_MAGRET_MAP_UUID               @"355728AC75724CF57C6EACBC4D01F9C23106AB3E"


@implementation TestProgress (IADevice_CB)

//Description : get write pass control bit password
//Param	:
//  NSDictionary	*dicSubTestItem : sub item for some setting params
//  char			*secureInput    : address for save password
//  NSMutableString	*szReturnValue  : return value
//Return result:
//  bool type : not use
- (bool)calculateSecuerControlBitPassword:(NSDictionary *)dicSubTestItem SecureInput:(char*)secureInput ReturnValue:(NSMutableString*)szReturnValue
{
	NSNumber *retValue;    
    char *cPasswordOutput = malloc(32);
    memset(cPasswordOutput, 0, 32);
    char *pBufferForNonce = malloc(20);//new char[20];
    
    /*/------------------------------------------------------------------
     Send command "getnonce"
     recevie nonce number by byte
     ------------------------------------------------------------------*/
    NSDictionary *dicSendGetnonce = [dicSubTestItem objectForKey:@"SEND_GETNONCE"];
    retValue = [self SEND_COMMAND:dicSendGetnonce];
    
    NSDictionary *dicReceiveGetnonce = [dicSubTestItem objectForKey:@"RECEIVE_GETNONCE"];
    retValue = [self READ_COMMAND:dicReceiveGetnonce RETURN_VALUE:szReturnValue];
	
    NSData *data = [m_dicMemoryValues objectForKey:kFZ_Script_ReceiveReturnData];
    char *pBuffer_Nonce = malloc(100);
    [data getBytes:pBuffer_Nonce length:[data length]];
    for(int i=0; i< [data length]; i++)//length?Leehua
    {
        if((*(pBuffer_Nonce+i)==0x0a)&&(*(pBuffer_Nonce+i+1)==0x0d))
        {
            memcpy(pBufferForNonce,(pBuffer_Nonce+i+2),20);
            break;
        }
    }
    free(pBuffer_Nonce);
    
    memcpy((secureInput+20),pBufferForNonce,20);
    ATSDebug(@"calculateSecureControlBitPassword : %s",secureInput);
    
    /*/------------------------------------------------------------------
     Caculate password form UUID and nonce
     ------------------------------------------------------------------*/
    CC_SHA1_CTX			context;
    unsigned char		digest[CC_SHA1_DIGEST_LENGTH];
    
    ///* Digest the concatenated string. 
    CC_SHA1_Init(&context);
    CC_SHA1_Update(&context,secureInput,40);
    CC_SHA1_Final(digest, &context);
    //strncpy(m_cPasswordOutput,(const char*)digest,20);
    memcpy(cPasswordOutput,(const char*)digest,20);
    
    /*/------------------------------------------------------------------
     Send password to UART and write control bit
     ------------------------------------------------------------------*/
    retValue = [self SEND_COMMAND:dicSubTestItem];
    
    NSDictionary *dicReceiveForPass = [dicSubTestItem objectForKey:@"RECEIVE_FOR_PASS"];
    retValue = [self READ_COMMAND:dicReceiveForPass RETURN_VALUE:szReturnValue];
    
    NSMutableDictionary *dicSendPassword = [dicSubTestItem objectForKey:@"SEND_PASSWORD"];
    
    //modified the kFZ_Script_CommandData as kFZ_Script_CommandString on 2012 05 12
    [dicSendPassword setObject:[NSData dataWithBytes:cPasswordOutput length:20] forKey:kFZ_Script_CommandString];
    retValue = [self SEND_COMMAND:dicSendPassword];

    NSDictionary *dicReceivePassword = [dicSubTestItem objectForKey:@"RECEIVE_PASSWORD"];
    retValue = [self READ_COMMAND:dicReceivePassword RETURN_VALUE:szReturnValue];
    
    /*/------------------------------------------------------------------
     free buffer
     ------------------------------------------------------------------*/
    free(cPasswordOutput) ;
    free(pBufferForNonce) ;
    
    NSString *szSource = [NSString stringWithString:szReturnValue];
    NSArray * aryExsist = [NSArray arrayWithObjects:@"Pass",@"Fail",@"Incomplete",@"Untested",nil];
    
    // fix a bug: when szSource = RX [] fail:Catch fail key:not found!, write cb will pass. 2014/03/26/Gordon
    NSArray * aryNotExist = [NSArray arrayWithObjects:@"ERROR", @"not found", nil];
	if(![self ExsistObjects:aryExsist AtString:szSource IgnoreCase:YES] || [self ExsistObjects:aryNotExist AtString:szSource IgnoreCase:YES])
	{
        //7.24
        //mark by desikan  fix the bug: upload to PDCA fail but our log show PASS
        //move uploadPDCA out of the loop
//        if(!m_bNoUploadPDCA)
//        {
//            [m_objPudding SetTestItemStatus:@"CB Check"
//                                    SubItem:@"Write" 
//                                  TestValue:szSource
//                                   LowLimit:@"" 
//                                  HighLimit:@""
//                                  TestUnits:@"" 
//                                    ErrDesc:@"CB Write Fail"
//                                   Priority:0
//                                 TestResult:NO];
//        }
//		[szReturnValue setString:@"CB Write Fail!"];
		return NO;
	}
	else
	{
		return YES;
	}
}

- (NSNumber *)SET_GENERAL_PARAM:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString *)szReturnValue
{
    [m_dicMemoryValues setObject:[NSNumber numberWithBool:YES] forKey:kFZ_SetCBFlag];
    m_bFinalResult = YES;
    return [NSNumber numberWithBool:YES];
}

/* set pass or fail control bit
 * Param:
 *		NSDictionary*		dicSubTestItem	:
 *			STRING				-> NSString*	: command to write cb
 *			TARGET				-> NSString*	: the target to send command to
 *			RECEIVE_FOR_FAIL	->NSDictionary*	: read command when test failed
 *			RECEIVE_FOR_PASS	->NSDictionary*	: read command when test passed
 *			SEND_PASSWORD		->NSDictionary* : send password command for write cb
 *			RECEIVE_PASSWORD	->NSDictionary* : read password command
 *			SEND_GETNONCE		->NSDictionary* : send getnonce command 
 *			RECEIVE_GETNONCE	->NSDictionary* : read getnonce command
 *      NSMutableString*	szReturnValue   : return value
 * Relate:
 *		NSMutableDictionary	*dicMemoryValues : Save memory values with given key
 */
- (NSNumber*)WRITE_CONTROL_BIT:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString*)szReturnValue
{
    NSNumber *numSetFlag = [m_dicMemoryValues objectForKey:kFZ_SetCBFlag];
    if (![numSetFlag boolValue])	
	{
		// no need to set control bit
        [szReturnValue setString:@"UnNeed to set CB!"];
        return [NSNumber numberWithBool:YES];
    }
    // set control bit
    NSNumber *retValue = [NSNumber numberWithBool:NO];;
    NSString *szCommand = [dicSubTestItem valueForKey:kFZ_Script_CommandString];
    if(!m_bFinalResult)
    {
        //test fail
        [m_dicMemoryValues setObject:kFZ_TestFail forKey:kFZ_TestResult];
        retValue = [self SEND_COMMAND:dicSubTestItem];
        NSDictionary *dicReceiveForFail = [dicSubTestItem objectForKey:@"RECEIVE_FOR_FAIL"];
        retValue = [self READ_COMMAND:dicReceiveForFail RETURN_VALUE:szReturnValue];
    }
    else
    {
        //test pass
        NSString *szUUID = @"";
        [m_dicMemoryValues setObject:kFZ_TestPass forKey:kFZ_TestResult];

        //set fixed UUID
        NSRange range = [szCommand rangeOfString:kFZ_IPAD1_ID];
        if(range.location != NSNotFound &&range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_IPAD1_UUID;
        }
        range = [szCommand rangeOfString:kFZ_GRP_MINUS1_ID];
        if(range.location != NSNotFound &&range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_GRP_MINUS1_UUID;
        }
        range = [szCommand rangeOfString:kFZ_GROUNDING_ID];
        if(range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length] )
        {
            szUUID = kFZ_GROUNDING_UUID;
        }
        range = [szCommand rangeOfString:kFZ_QT0_ID];
        if(range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_QT0_UUID;
        }
        range = [szCommand rangeOfString:kFZ_QT0b_ID];
        if(range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_QT0b_UUID;
        }
        range = [szCommand rangeOfString:kFZ_CONNECTIVITY_ID];
        if(range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_CONNECTIVITY_UUID;
        }
        range = [szCommand rangeOfString:kFZ_QT1_ID];
        if(range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_QT1_UUID;
        }
        range = [szCommand rangeOfString:kFZ_PROXCAL_ID];
        if(range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_PROXCAL_UUID;
        }
        range = [szCommand rangeOfString:kFZ_PROXSUS_ID];
        if(range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_PROXSUS_UUID;
        }
        range = [szCommand rangeOfString:kFZ_HALL_EFFECT_ID];
        if (range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length]) 
        {
            szUUID = kFZ_HALL_EFFECT_UUID;
        }
        range = [szCommand rangeOfString:kFZ_MAGNET_COVER_ID];
        if (range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length]) 
        {
            szUUID = kFZ_MAGNET_COVER_UUID;
        }
        range = [szCommand rangeOfString:kFZ_MAGNET_SPINE_ID];
        if (range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length]) 
        {
            szUUID = kFZ_MAGNET_SPINE_UUID;
        }
        range = [szCommand rangeOfString:kFZ_MAGRET_MAP_ID];
        if(range.location != NSNotFound &&range.length >0 && (range.length+range.location) <= [szCommand length])
        {
            szUUID = kFZ_MAGRET_MAP_UUID;
        }
        range = [szCommand rangeOfString:KFZ_GRAPE_OFFSET_ID];
        if (range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length]) 
        {
            szUUID = KFZ_GRAPE_OFFSET_UUID;
        }
        range = [szCommand rangeOfString: kFZ_CONNECTIVITY2_ID];
        if (range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length]) 
        {
            szUUID = kFZ_CONNECTIVITY2_UUID;
        }
        range = [szCommand rangeOfString:kFZ_CurrentPostBurn_ID];
        if (range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length]) 
        {
            szUUID = KFZ_CURRENT_POSTBURN_UUID;
        }
        range = [szCommand rangeOfString:kFZ_FOS_ID];
        if (range.location != NSNotFound && range.length >0 && (range.length+range.location) <= [szCommand length]) 
        {
            szUUID = KFZ_FOS_UUID;
        }
        
        //copy fixed UUID to first 20 bytes of password area
        char *cSecureUUID = malloc(40);
		memset(cSecureUUID ,0x00,40);
		for(int i=0,j=0;i<20;i++)
		{
			unsigned int	nHex = 0;
			NSRange	range;
			range.location	= j;
			range.length	= 2;            
			NSString *temp	= @"";
            if ([szUUID length] >= range.location + range.length)
			{
                temp = [szUUID substringWithRange:range];
            }
			[[NSScanner scannerWithString:temp ]scanHexInt:&nHex];
			*(cSecureUUID+i) = nHex;
			j+=2;
		}
		ATSDebug(@"WRITE_CONTROL_BIT => szSecureUUID = %s",cSecureUUID);
        
        BOOL bRetFromCal = YES;
        //calculate late 20 bytes of password
        for(int iCount = 0; iCount < 10; iCount++)
		{
            //call function to calculate
			bRetFromCal = [self calculateSecuerControlBitPassword:dicSubTestItem SecureInput:cSecureUUID ReturnValue:szReturnValue];
			ATSDebug(@"WRITE_CONTROL_BIT => calculateSecuerControlBit return value:[%@],iCount=[%d]",szReturnValue,iCount);
			if(bRetFromCal)
			{
                //if pass , jump out , not to repeat
				retValue = [NSNumber numberWithBool:YES];
                break;
			}
		}
        //7.24
        //mark by desikan  fix the bug: upload to PDCA fail but our log show PASS
        //move uploadPDCA out of the loop
        if(!m_bNoUploadPDCA && ![retValue boolValue])
        {
            [m_objPudding SetTestItemStatus:@"CB Check"
                                    SubItem:@"Write" 
                                  TestValue:szReturnValue
                                   LowLimit:@"" 
                                  HighLimit:@""
                                  TestUnits:@"" 
                                    ErrDesc:@"CB Write Fail"
                                   Priority:0
                                 TestResult:NO];
        }
		free(cSecureUUID);
    }
    return retValue;
}

/*  
 2012-04-17 Add remark by Stephen
 Function	:	Check control bits of some stations.
 Description:	Get the cb value from unit by sending cbread "StationID", upload the result to PDCA.
 Para:
	NSDictionary*		dicSubTestItem	:	A dictionary contains the array commands to send, maybe cbread "StationID1", cbread "StationID2" and so on.
		NO_WRITE_INCOMPLETE			->Boolean		:	The local station has cb or not,need write incomplete or not
		NO_CHECK_FAIL_COUNT			->Boolean		:	need check GH fail count or not
		NEW_CBAuth_API				->NSString*		:	new API or old API
		1.SEND_COMMAND:				->NSDictionary*	:	send command to set now time
		1.READ_COMMAND:RETURN_VALUE ->NSDictionary*	:	read command to set now time
		2.SEND_COMMAND:				->NSDictionary*	:	send command to write incomplete
		2.READ_COMMAND:RETURN_VALUE ->NSDictionary*	:	read command to write incomplete
		SEND_COMMAND:				->NSDictionary*	:	send command to check cb
		READ_COMMAND:RETURN_VALUE	->NSDictionary*	:	read command to check cb
	NSMutableString*	szReturnValue	:	Value to show on UI and write in csv
 Return		:	If all the cb value from unit are PASS return YES, else return NO.
 */
- (NSNumber*)CHECK_CONTROL_BITS:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString*)szReturnValue
{  
    NSNumber		*numRet	= [NSNumber numberWithBool:YES];
    NSMutableArray	*aryStationIDs = [[NSMutableArray alloc] init];
    NSMutableArray	*aryStationNames = [[NSMutableArray alloc] init];
    NSString		*szErrorMSG = @"CBAuth Error: To Be Design Error";   
    [szReturnValue setString:@"PASS"];
    BOOL bNumRet = YES;
    NSMutableString	*szFailStation = [[NSMutableString alloc] init];
    BOOL bNoWriteIncomplete = [[dicSubTestItem objectForKey:@"NO_WRITE_INCOMPLETE"]boolValue];//The local station no cb, no need write incomplete
    BOOL bNoCheckFailCount = [[dicSubTestItem objectForKey:@"NO_CHECK_FAIL_COUNT"]boolValue];// No need check GH fail count
    BOOL bNewAPI = NO;
    if ([dicSubTestItem objectForKey:@"NEW_CBAuth_API"]) //New API flag
    {
        bNewAPI = [[dicSubTestItem objectForKey:@"NEW_CBAuth_API"]boolValue];
    }

    // Step 1
    // Use the new API with the unit SN
    int iRet = -528; // default error code
    if (bNewAPI)
    {
        // torres mark 2012.7.24
		//NSString *strCheckCBSN = [m_dicMemoryValues objectForKey:kFZ_CheckCB_SN];
        //if (nil == strCheckCBSN || 17 > [strCheckCBSN length]) {
        //    strCheckCBSN = m_szISN;
        //}
		iRet = [m_CB_TestBase ControlBitsToCheckSN:m_szISN stationIDsHex:aryStationIDs stationName:aryStationNames]; 
        if (iRet < 0)
        {
            szErrorMSG = [m_CB_TestBase cbGetErrMsg:iRet];
            [szReturnValue setString:szErrorMSG];
            [aryStationIDs release];
            [aryStationNames release];
            [szFailStation release];
            return [NSNumber numberWithBool:NO];
        }
    }
    else
    {
        BOOL bRet = [m_CB_TestBase ControlBitsToCheck:aryStationIDs stationName:aryStationNames];  // old API, don't have error code function
        if (bRet)// if return yes, return the count of stations need to check similar to the new API
        {
            iRet = [aryStationIDs count];
        }
        else// if return no, return 0, indicate the Network CB don't need to check.
        {
            iRet = 0;
        }

    }

    NSInteger iSize = [aryStationNames count];   
    // check_control_bit return no need 
    if (iRet > 0) 
    {
        // need check_control_bit
        NSDictionary *dicReadCB = [dicSubTestItem objectForKey:@"SEND_COMMAND:"];
        NSDictionary *dicReceiveFromCB = [dicSubTestItem objectForKey:@"READ_COMMAND:RETURN_VALUE:"];
        for(NSInteger i=0; i<iSize; i++)
        {
            NSString *szStationName = [aryStationNames objectAtIndex:i];
            [m_dicMemoryValues setObject:[aryStationIDs objectAtIndex:i] forKey:kFZ_StationId];
            [self SEND_COMMAND:dicReadCB];
            numRet = [self READ_COMMAND:dicReceiveFromCB RETURN_VALUE:szReturnValue];
            bNumRet &= [numRet boolValue];
            if(![numRet boolValue])
            {
                if ([szReturnValue isEqualToString:@""])
				{
                    [szReturnValue setString:@"CB read formart error"];
                }
                if(!m_bNoUploadPDCA)
                {
                    [m_objPudding SetTestItemStatus:@"CB Check Read" 
                                            SubItem:szStationName 
                                          TestValue:[NSString stringWithString:szReturnValue] 
                                           LowLimit:@"" 
                                          HighLimit:@"" 
                                          TestUnits:@"" 
                                            ErrDesc:@"CB Read Fail"
                                           Priority:0 
                                         TestResult:NO];
                }
                [szReturnValue setString:[NSString stringWithFormat:@"Rx Data format [%@] error  at station [%@]", szReturnValue,
                                          szStationName]];
            }
            else
            {
                NSArray *aryValues = [szReturnValue componentsSeparatedByString:@" "];
                NSInteger iValueCount = [aryValues count];
                if(iValueCount < 6)
                {
                    if ([szReturnValue isEqualToString:@""])
					{
                        [szReturnValue setString:@"NoRx"];
                    }
                    if(!m_bNoUploadPDCA)
                    {
                        [m_objPudding SetTestItemStatus:@"CB Check Routing"
                                                SubItem:szStationName
                                              TestValue:[NSString stringWithString:szReturnValue]
                                               LowLimit:@"Passed" 
                                              HighLimit:@"Passed"
                                              TestUnits:@"" 
                                                ErrDesc:[NSString stringWithFormat:@"No pass for %@, go to %@",szStationName,szStationName] 
                                               Priority:0
                                             TestResult:NO];
                    }
                    [szReturnValue setString:[NSString stringWithFormat:@"Rx Data format [%@] error  at station [%@]", szReturnValue,
                                              szStationName]];
                }
                else
                {
                    NSString *szResult = [aryValues objectAtIndex:1];
                    NSString *szSpec = [dicSubTestItem objectForKey:@"SPEC"];
                    if (szSpec == nil)
                    {
                        szSpec = @"Passed";
                    }
                    
                    [m_dicMemoryValues setObject:szSpec forKey:kFZ_TestLimit_KBB];
                    [m_dicMemoryValues setObject:szResult forKey:szStationName];
                    
                    if([[szSpec uppercaseString] ContainString:[szResult uppercaseString]])
                    {
                        [m_dicNetWorkCBStation setObject:@"PASS" forKey:szStationName]; //add for remember network CB

                        continue;
                    }
                    else
                    {
                        [m_dicNetWorkCBStation setObject:szResult forKey:szStationName]; //add for remember network CB
                        
                        if(!m_bNoUploadPDCA)
                        {
                            [m_objPudding SetTestItemStatus:@"CB Check Routing"
                                                    SubItem:szStationName                                                
                                                  TestValue:szResult
                                                   LowLimit:@"Passed" 
                                                  HighLimit:@"Passed"
                                                  TestUnits:@"" 
                                                    ErrDesc:[NSString stringWithFormat:@"No pass for %@, go to %@",szStationName, szStationName] 
                                                   Priority:0
                                                 TestResult:NO];
                        }
                        [szFailStation appendFormat:@"%@ ",szStationName]; 
                    }
                }
            }
            bNumRet = NO;
        }
    }
    // judge check_control_bit result
    if (!bNumRet)
    {
        [szReturnValue setString:[NSString stringWithFormat:@"No pass for %@",szFailStation]];
        [szFailStation release];
        [aryStationIDs release];
        [aryStationNames release];
        return [NSNumber numberWithBool:NO];
    }
    
    // Step 2
    // check self fail count
    int iAllowedFailCount = [m_CB_TestBase getStationFailCountAllowed];
    NSDictionary *dicForAllowed = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:iAllowedFailCount],@"ALLOWED_FAIL_COUNT",
                                   [dicSubTestItem objectForKey:@"SEND_COMMAND:"],@"SEND_COMMAND:",
                                   [dicSubTestItem objectForKey:@"READ_COMMAND:RETURN_VALUE:"],@"READ_COMMAND:RETURN_VALUE:", nil];
    if (!bNoCheckFailCount && iAllowedFailCount>0) 
    {
        //add for check allowed GH fail count
        if (![[self WHETHER_STATION_ALLOWED_TEST:dicForAllowed RETURN_VALUE:szReturnValue]boolValue]) 
        {
            [szFailStation release];
            [aryStationIDs release];
            [aryStationNames release];
            return [NSNumber numberWithBool:NO];
        }
    }
    
    // Step 3
    // write in complete cb value
    if (!bNoWriteIncomplete) 
    {
        if (![[self WRITE_INCOMPLETE_CONTROLBIT:dicSubTestItem RETURN_VALUE:szReturnValue]boolValue]) 
        {
            [szReturnValue setString:@"NetWork CB On and Write CB Incomplete fail"];
            [aryStationIDs release];
            [aryStationNames release];
            [szFailStation release];
            return [NSNumber numberWithBool:NO];
        }
    }
    if (iRet == 0) [szReturnValue setString:@"Network CB Check Return No Need!"];
    [szFailStation release];
    [aryStationIDs release];
    [aryStationNames release];
    return [NSNumber numberWithBool:bNumRet];
}

/*  
 2012-04-17 Add remark by Stephen
 Function:       Clear some stations' cb based on the test result.
 Description:    Get the stations' IDs based on the final result, than clear them.
 Para:           
	(NSDictionary *)dicSubTestItem	--> A dictionary contains the arguments of "SEND_COMMAND:" and "READ_COMMAND:RETURN_VALUE:" function.
	(NSMutableString*)szReturnValue --> Value returned from the last function, contains the unit's return value, show on UI and save in csv.
 Return:         If the stations' cb has cleard ok, return YES, else return NO.
 */
- (NSNumber*)CLEAR_RELATIVE_CONTROL_BITS:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString *)szReturnValue
{
    bool bReply = YES;
    NSMutableString *szMuErrorCode = [[NSMutableString alloc] init];
    NSMutableArray *aryToClear = [[NSMutableArray alloc] init];
    if(m_bFinalResult)
    {
        bReply = [m_CB_TestBase ControlBitsToClearOnPass:aryToClear];
    }
    else
    {
        bReply = [m_CB_TestBase ControlBitsToClearOnFail:aryToClear];
    }
    NSNumber *numRet = [NSNumber numberWithBool:bReply];
    if (bReply) 
    {
        NSDictionary *dicSend = [dicSubTestItem objectForKey:@"SEND_COMMAND:"];
        NSDictionary *dicReceive = [dicSubTestItem objectForKey:@"READ_COMMAND:RETURN_VALUE:"];

        for(NSInteger i=0; i<[aryToClear count]; i++)
        {
            [m_dicMemoryValues setObject:[aryToClear objectAtIndex:i] forKey:kFZ_StationId];
            [self SEND_COMMAND:dicSend];
            numRet = [self READ_COMMAND:dicReceive RETURN_VALUE:szReturnValue];
            if(![numRet boolValue])
            {
                if([szReturnValue isEqualToString:@""])
                {
                    [szReturnValue setString:@"CB clear formart error"];
                }
            }
            bReply &= [numRet boolValue];
            [szMuErrorCode appendFormat:@"%@  ",szReturnValue];
            ATSDebug(@"CLEAR_RELATIVE_CONTROL_BITS => Clear station %@",[aryToClear objectAtIndex:i]);
        }
        numRet = [NSNumber numberWithBool:bReply];
    }
    else
    {
        [szReturnValue setString:@"No list for CBCF"];
        ATSDebug(@"CLEAR_RELATIVE_CONTROL_BITS => No stations need to clear !");
        numRet = [NSNumber numberWithBool:YES];
    }
    [szReturnValue setString:szMuErrorCode];
    [aryToClear release];
    [szMuErrorCode release];
    return numRet;
}

/****************************************************************************************************
 Start 2012.4.16 Add note by Yaya 
 Descripton: check the setting file scriptFileName is contain the GH station type. 
 Param:
 NSMutableString *strErr : Return value , if the script file name contain the GH station type , the return value
                           is the GH station type. or the return value is like  "GroundhogInfo [GH station name] vs SettingFile [script file name]"
 ****************************************************************************************************/
- (BOOL)GetAndCompareLocalStationName:(NSMutableString *)strErr
{
	BOOL bResult;	
	NSString	*strStationNameGH	= [m_dicMemoryValues objectForKey:kPD_GHInfo_STATION_TYPE];
	// update for changing the script file name location in the setting file
    NSString	*strStationNameIni	= [[self getValueFromXML:kPD_UserDefaults mainKey:kPD_UserDefaults_ScriptFileName,nil] objectForKey:@"DefaultFileName"];
	NSRange		range = [[strStationNameIni uppercaseString] rangeOfString:[strStationNameGH uppercaseString]];
	if (NSNotFound != range.location && range.length >0 && (range.location+range.length) <= [strStationNameIni length])
	{
        [strErr setString:strStationNameGH];
		bResult = YES;
	}
	else
	{
        [strErr setString:[NSString stringWithFormat:@"GroundhogInfo [%@] vs SettingFile [%@]",strStationNameGH,strStationNameIni]];
		bResult = NO;
	}
	return bResult;
}
/****************************************************************************************************
 Start 2012.4.16 Add note by Yaya 
 Descripton: check one station is it over the fail count! 
 Param:
 NSDictionary  *dicSubTestItem : setting in script,the contents about which station you want to check.
 NSMutableString  *szReturnValue : Return value
 ****************************************************************************************************/

- (NSNumber*)WHETHER_STATION_ALLOWED_TEST:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString *)szReturnValue
{
    NSNumber *numRet = [NSNumber numberWithBool:NO];
    //update Mapping Table...
    NSDictionary *dictMappingTable = [NSDictionary dictionaryWithObjectsAndKeys:
                        kFZ_IPAD1_ID,@"IPAD-MINUS-ONE",
                        kFZ_QT0_ID,@"QT0",
                        kFZ_QT0b_ID,@"QT0B",              
                        kFZ_GROUNDING_ID,@"GROUNDING-1",
                        kFZ_CONNECTIVITY_ID,@"CONNECTIVITY-TEST",
                        kFZ_MAGNET_SPINE_ID,@"MAGNET-SPINE",
                        kFZ_MAGNET_COVER_ID,@"MAGNET-COVER",
                        kFZ_HALL_EFFECT_ID,@"HALL-EFFECT",
                        kFZ_QT1_ID,@"QT1",
                        kFZ_PROXCAL_ID,@"PROX-CAL-FINAL",
                        kFZ_PROXSUS_ID,@"PROX-SUS-FINAL",
                        kFZ_FOS_ID,@"FOS",
                        KFZ_GRAPE_OFFSET_ID,@"GRAPE-OFFSET",
                        kFZ_CONNECTIVITY2_ID,@"CONNECTIVITY-TEST2",
                                      kFZ_CurrentPostBurn_ID,@"DEVELOPMENT9",
                        nil];
    if([self GetAndCompareLocalStationName:szReturnValue])
    {
        NSString *szStationID = [dictMappingTable objectForKey:[szReturnValue uppercaseString]];
        if (nil == szStationID)
		{
            [szReturnValue setString:[NSString stringWithFormat:@"NO StationID:%@",szReturnValue]];
            return numRet;
        }
        
        NSDictionary *dicReadCB = [dicSubTestItem objectForKey:@"SEND_COMMAND:"];
        NSDictionary *dicReceiveFromCB = [dicSubTestItem objectForKey:@"READ_COMMAND:RETURN_VALUE:"];
        [m_dicMemoryValues setObject:szStationID forKey:kFZ_StationId];
        [self SEND_COMMAND:dicReadCB];
        numRet = [self READ_COMMAND:dicReceiveFromCB RETURN_VALUE:szReturnValue];
        if(![numRet boolValue])
        {
            if ([szReturnValue isEqualToString:@""])
			{
                [szReturnValue setString:@"CB read formart error"];
            }
            if(!m_bNoUploadPDCA)
            {
                [m_objPudding SetTestItemStatus:@"CB Check" SubItem:@"Read" TestValue:[NSString stringWithString:szReturnValue] LowLimit:@"Passed" HighLimit:@"Passed" TestUnits:@"" ErrDesc:[NSString stringWithFormat:@"CB Read Fail [%@]",szReturnValue] Priority:0 TestResult:NO];
            }
            [szReturnValue setString:[NSString stringWithFormat:@"Rx Data format [%@] error  at station ID [%@]", szReturnValue,
                                      szStationID]];
        }
        else
        {
            NSArray *aryValues = [szReturnValue componentsSeparatedByString:@" "];
            NSInteger iValueCount = [aryValues count];
            if(iValueCount < 4)
            {
                numRet = [NSNumber numberWithBool:NO];
                ATSDebug(@"WHETHER_STATION_ALLOWED_TEST : nil == arrValues || [arrValues count] < 4");
                [szReturnValue setString:[NSString stringWithFormat:@"Read [%@] Control Bit format error",szReturnValue]];
            }
            else
            {
                int iFailCount = [[aryValues objectAtIndex:2] intValue];
                //[szReturnValue setString:[NSString stringWithFormat:@"%d",iFailCount]];
                int iAllowedFailCount = [[dicSubTestItem objectForKey:@"ALLOWED_FAIL_COUNT"] intValue];
                if(iAllowedFailCount > 0 && iFailCount >= iAllowedFailCount)
                {
                    numRet = [NSNumber numberWithBool:NO];
                    [szReturnValue setString:[NSString stringWithFormat:@"Already fail %d times;STATION_FAIL_COUNT_ALLOWED is %d",iFailCount,iAllowedFailCount]];
                    if(!m_bNoUploadPDCA)
                    {
                        [m_objPudding SetTestItemStatus:@"CB Check"//[NSString stringWithFormat:@"%@ CB Check", *szReturnValue]
                                                SubItem:@"Retest"//[NSString stringWithFormat:@"%@ Retest", *szReturnValue]
                                              TestValue:[NSString stringWithFormat:@"%d",iFailCount]
                                               LowLimit:@"0"
                                              HighLimit:[NSString stringWithFormat:@"%d",iAllowedFailCount]
                                              TestUnits:@"" 
                                                ErrDesc:@"Over fail count, go to repair"
                                               Priority:0
                                             TestResult:NO];	
                    }
                }
            }
        }
    }
    else
    {
        ATSDebug(@"WHETHER_STATION_ALLOWED_TEST call function GetAndCompareLocalStationName : %@",szReturnValue);
    }
    return numRet;
}
/****************************************************************************************************
 Start 2012.4.16 Add note by Yaya 
 Descripton: write incomplete control bit. 
 Param:
 NSDictionary  *dicSubTestItem : setting in script.it is mainly about two commmands"rtc" and "cb write"
 NSMutableString  *szReturnValue : Return value
****************************************************************************************************/

- (NSNumber*)WRITE_INCOMPLETE_CONTROLBIT:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString *)szReturnValue
{
    if(![m_dicMemoryValues objectForKey:kPD_GHInfo_STATION_ID])
    {
        ATSDebug(@"WRITE_INCOMPLETE_CONTROLBIT => Can't find StationId from m_dicMemoryValues! Check whether WHETHER_STATION_ALLOWED_TEST: has been done.")
        return [NSNumber numberWithBool:NO];
    }
    
    NSDictionary *dicSend_setTime = [dicSubTestItem objectForKey:@"1.SEND_COMMAND:"];
    NSDictionary *dicReceive_setTime = [dicSubTestItem objectForKey:@"1.READ_COMMAND:RETURN_VALUE:"];
    NSDictionary *dicSend_setIncomplete = [dicSubTestItem objectForKey:@"2.SEND_COMMAND:"];
    NSDictionary *dicReceive_setIncomplete = [dicSubTestItem objectForKey:@"2.READ_COMMAND:RETURN_VALUE:"];
    NSString *szNowTime = [[NSDate date] descriptionWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:nil locale:nil];
    [m_dicMemoryValues setObject:szNowTime forKey:kFZ_NowTime];
    [self SEND_COMMAND:dicSend_setTime];
    [self READ_COMMAND:dicReceive_setTime RETURN_VALUE:szReturnValue];
    
    //add for compare rtc time 20140616
    NSMutableDictionary *dicComparison1 = [[NSMutableDictionary alloc]init];
    [dicComparison1 setObject:szNowTime forKey:@"PreBUrn"];
    [dicComparison1 setObject:szReturnValue forKey:@"Burn"];
    NSMutableDictionary *dicCompareItems =[[NSMutableDictionary alloc] initWithObjectsAndKeys:dicComparison1,@"Comparison1", nil];
    NSNumber *numRet = [self COMPARE:dicCompareItems RETURN_VALUE:szReturnValue];
    [dicComparison1 release];
    [dicCompareItems release];
    if (!numRet) {
        return  numRet;
    }
    
    [m_dicMemoryValues setObject:m_szUIVersion forKey:kFZ_SoftVersion];
    [self SEND_COMMAND:dicSend_setIncomplete];
    numRet = [self READ_COMMAND:dicReceive_setIncomplete RETURN_VALUE:szReturnValue];
    if (![numRet boolValue]) {
        if([szReturnValue isEqualToString:@""])
        {
            [szReturnValue setString:@"CB write formart error"];
        }
        if(!m_bNoUploadPDCA)
        {
            [m_objPudding SetTestItemStatus:@"CB Check"
                                    SubItem:@"Write"
                                  TestValue:[NSString stringWithString:szReturnValue]
                                   LowLimit:@"Passed" 
                                  HighLimit:@"Passed"
                                  TestUnits:@"" 
                                    ErrDesc:[NSString stringWithFormat:@"CB Write Fail [%@]",szReturnValue] 
                                   Priority:0
                                 TestResult:NO];
        }
        [szReturnValue setString:[NSString stringWithFormat:@"Write CB error [%@]", szReturnValue]];		
    }
    return  numRet;
}
/****************************************************************************************************
 Start 2012.4.16 Add note by Yaya
 Descripton: Base on the Json to decide if setting control bit or not.
 Param:
	NSDictionary		*dicSubTestItem	: nothing
	NSMutableString		*szReturnValue	: Return value
****************************************************************************************************/

- (NSNumber*)CB_SETORNOT:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString *)szReturnValue
{
    BOOL bSetFlag = [m_CB_TestBase StationSetControlBit];
    if (bSetFlag) {
        [m_dicMemoryValues setObject:[NSNumber numberWithBool:YES] forKey:kFZ_SetCBFlag];
        [szReturnValue setString:@"ON"];
    }
    else
    {
        [m_dicMemoryValues setObject:[NSNumber numberWithBool:NO] forKey:kFZ_SetCBFlag];
        [szReturnValue setString:@"OFF"];
    }
    return [NSNumber numberWithBool:YES];     
}

/****************************************************************************************************
 Start 2012.4.16 Add note by Yaya
 Descripton: Self CB check and upload the result to PDCA.
 Param:
	NSDictionary	*dicSubTestItem	: setting in script.
				NoSpec	->Boolean		:include whether there have spec? what the spec?
				SPEC	->NSString*		:the spec
	NSMutableString	*szReturnValue	: Return value(like, 0x80 Passed 0 8 100 46714214 1.0d15
)
****************************************************************************************************/
- (NSNumber*)SELF_CB_CHECK:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString *)szReturnValue
{   
    NSArray * arrValues = [szReturnValue componentsSeparatedByString:@" "];
	if (nil == arrValues || [arrValues count] < 6)
	{	
		ATSDebug(@"SELF_CB_CHECK => nil == arrValues || [arrValues count] < 5");
        if(!m_bNoUploadPDCA)
        {
            [m_objPudding SetTestItemStatus:@"CB Check"
								SubItem:@"Read" 
							  TestValue:[NSString stringWithString:szReturnValue]
							   LowLimit:@"" 
							  HighLimit:@""
							  TestUnits:@"" 
								ErrDesc:@"CB Read Fail" 
							   Priority:0
							 TestResult:NO];
        }
		return [NSNumber numberWithBool:NO];
	}
    
    [szReturnValue setString:[arrValues objectAtIndex:1]];
    
    NSNumber *numRet = [NSNumber numberWithBool:YES];
    BOOL bNoSpec = [[dicSubTestItem objectForKey:@"NoSpec"] boolValue];    
    if (!bNoSpec) 
    {
		// have spec and Judge the spec
        NSString *szSpec = [dicSubTestItem objectForKey:@"SPEC"];
        NSDictionary *dicSpec = [NSDictionary dictionaryWithObjectsAndKeys:szSpec , kFZ_Script_JudgeCommonBlack , nil];
        
        dicSpec = [NSDictionary dictionaryWithObjectsAndKeys:dicSpec , kFZ_Script_JudgeCommonSpec , nil];
        numRet = [self JUDGE_SPEC:dicSpec RETURN_VALUE:szReturnValue];
    }    
    NSString	*szTestItemName	= [m_dicMemoryValues objectForKey:kFunnyZoneCurrentItemName];
    NSArray		*arrayKeys		= [NSArray arrayWithObjects:@"Station id",@"CB result",@"RFC",
						   @"AFC", @"EC",@"Time", @"SW_V",nil];
    NSString	*strErrDes		= [numRet boolValue] ? @"" : [NSString stringWithFormat:@"[%@] FAIL",szTestItemName];
    if(!m_bNoUploadPDCA)
    {
        for (NSUInteger i = 2; i < 5; i++)
        {
            [m_objPudding SetTestItemStatus:[NSString stringWithFormat:@"%@_%@",szTestItemName,[arrayKeys objectAtIndex:i]]
                                    SubItem:@"" 
                                  TestValue:[arrValues objectAtIndex:i] 
                                   LowLimit:@"" 
                                  HighLimit:@""
                                  TestUnits:@"" 
                                    ErrDesc:strErrDes 
                                   Priority:0
                                 TestResult:[numRet boolValue]];
        }
    }
    //show write cb time as one case and upload to parametric data 11.12.15
    [m_dicMemoryValues setObject:[arrValues objectAtIndex:5] forKey:kFZ_Script_CBWtnTime];
    
    NSDictionary * dictMappingTable = [NSDictionary dictionaryWithObjectsAndKeys:@"0",@"Passed",@"1",@"Untested",@"2",@"Failed",@"3",@"Incomplete",nil];	
	NSString * strValueToPDCA = [dictMappingTable objectForKey:szReturnValue];
	if (strValueToPDCA == nil || [strValueToPDCA isEqualToString:@""])
	{
        [szReturnValue setString:@"Upload CB To PDCA fail!"];
		numRet = [NSNumber numberWithBool:NO];
	}
    else
    {
        if(!m_bNoUploadPDCA)
        {
            [m_objPudding SetTestItemStatus:[NSString stringWithFormat:@"%@_CB",szTestItemName]
							SubItem:@"" 
						  TestValue:strValueToPDCA
						   LowLimit:@"" 
						  HighLimit:@""
						  TestUnits:@"" 
							ErrDesc:strErrDes 
						   Priority:0
						 TestResult:[numRet boolValue]];
        }
	}
	return numRet;
}

- (NSNumber*)ClearCB:(NSDictionary *)dicSubTestItem RETURN_VALUE:(NSMutableString *)szReturnValue
{
    NSString *szBoardId = [m_dicMemoryValues objectForKey:@"BOARDID"];
    if (szBoardId == nil)
    {
        [szReturnValue setString:@"BOARDID = nil"];
        return [NSNumber numberWithBool:NO];
    }
    NSDictionary *dicEraseStation   = [dicSubTestItem objectForKey:szBoardId];
    NSArray *aryEraseStationName = [dicEraseStation allKeys];
    BOOL bNumRet = YES;    
    
    NSDictionary *dicSendCommand    = [dicSubTestItem objectForKey:@"SEND_COMMAND:"];
    NSDictionary *dicReadCommand    = [dicSubTestItem objectForKey:@"READ_COMMAND:RETURN_VALUE:"];
    
    for (NSString *szStationName in aryEraseStationName)
    {
        NSDate   *dateStart = [NSDate date];
        NSTimeInterval dTimeSpend = 0.0;
        
        NSString *szStationID = [dicEraseStation objectForKey:szStationName];
        [m_dicMemoryValues setObject:szStationID forKey:kFZ_EraseStationID];
        [self SEND_COMMAND:dicSendCommand];
        NSNumber *numRet = [self READ_COMMAND:dicReadCommand RETURN_VALUE:szReturnValue];
        bNumRet &= [numRet boolValue];
        BOOL bNOWriteToCsv = NO;
        
        dTimeSpend = [[NSDate date] timeIntervalSinceDate:dateStart];
        NSString *szTestInfo = [NSString stringWithFormat:@"CB Erase %@,%i,%@,%@,%@,%0.6fs\n", szStationName, ![numRet boolValue], szReturnValue, @"N/A", @"N/A", dTimeSpend];
        if (nil != [m_dicMemoryValues objectForKey:kFunnyZoneHasSubItemParameterData])
        {
            if (!bNOWriteToCsv)
            {
                [m_dicMemoryValues setObject:[NSString stringWithFormat:@"%@%@",[m_dicMemoryValues objectForKey:kFunnyZoneHasSubItemParameterData],szTestInfo] forKey:kFunnyZoneHasSubItemParameterData];
            }
            
        }else
        {
            if (!bNOWriteToCsv)
            {
                [m_dicMemoryValues setObject:szTestInfo forKey:kFunnyZoneHasSubItemParameterData];
            }
            
        }
    }
    
    return [NSNumber numberWithBool:bNumRet];
}
@end
