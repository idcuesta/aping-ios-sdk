// Copyright (c) 2013 - 2014 The Sporting Exchange Limited
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
// 3. All advertising materials mentioning features or use of this software
// must display the following acknowledgement:
// This product includes software developed by The Sporting Exchange Limited.
// 4. Neither the name of The Sporting Exchange Limited nor the
// names of its contributors may be used to endorse or promote products
// derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE SPORTING EXCHANGE LIMITED ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE SPORTING EXCHANGE LIMITED BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <XCTest/XCTest.h>

#import "APING.h"
#import "BNGMarketBook.h"
#import "BNGRunner.h"
#import "BNGPriceProjection.h"
#import "BNGURLProtocolResourceLoader.h"
#import "BNGTestUtilities.h"
#import "BNGMarketProfitAndLoss.h"
#import "BNGRunnerProfitAndLoss.h"

@interface BNGMarketBookTest : XCTestCase

@end

@implementation BNGMarketBookTest

- (void)testMarketBookApiCall
{
    [NSURLProtocol registerClass:[BNGURLProtocolResourceLoader class]];
    
    [[APING sharedInstance] registerApplicationKey:BNGTestUtilitiesApplicationKey ssoKey:BNGTestUtilitiesSSOKey];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    BNGPriceProjection *priceProjection = [[BNGPriceProjection alloc] init];
    priceProjection.priceData = @[[BNGPriceProjection stringFromPriceData:BNGPriceDataExTraded],
                                  [BNGPriceProjection stringFromPriceData:BNGPriceDataExAllOffers],
                                  [BNGPriceProjection stringFromPriceData:BNGPriceDataExBestOffers],
                                  [BNGPriceProjection stringFromPriceData:BNGPriceDataSPAvailable],
                                  [BNGPriceProjection stringFromPriceData:BNGPriceDataSPTraded]];
    
    [BNGMarketBook listMarketBooksForMarketIds:@[@"1.110709341"]
                               priceProjection:priceProjection
                               orderProjection:BNGOrderProjectionUnknown
                               matchProjection:BNGMatchProjectionUnknown
                               completionBlock:^(NSArray *results, NSError *connectionError, BNGAPIError *apiError) {
        
        BNGMarketBook *marketBook = results[0];
        XCTAssertTrue(results.count == 1, @"There should be only one BNGMarketBook");
        XCTAssertTrue([marketBook.marketId isEqualToString:@"1.109449486"], @"The market id should be '1.109814036'");
        XCTAssertFalse(marketBook.isMarketDataDelayed, @"The isMarketDataDelayed flag should be false");
        XCTAssertTrue(marketBook.status == BNGMarketStatusOpen, @"The market should be marked as open");
        XCTAssertTrue(marketBook.betDelay == 0, @"The bet delay should be 0 seconds");
        XCTAssertFalse(marketBook.inplay, @"The market should be marked as being in play");
        XCTAssertTrue(marketBook.numberOfWinners == 1, @"There should be only one runner for this market");
        XCTAssertTrue(marketBook.numberOfRunners == 20, @"There should 20 runners altogether for this market");
        XCTAssertTrue(marketBook.numberOfActiveRunners == 20, @"There should 20 active runners for this market");
        XCTAssertTrue([marketBook.totalMatched isEqual:[NSDecimalNumber decimalNumberWithString:@"78962.61"]], @"The total amount matched on this market should be 78962.61");
        XCTAssertTrue([marketBook.totalAvailable isEqual:[NSDecimalNumber decimalNumberWithString:@"4879.74"]], @"The total amount availiable on this market should be 4879.74");
        XCTAssertTrue(marketBook.runners.count == 20, @"There should be 20 runners in the market");
        
        for (BNGRunner *runner in marketBook.runners) {
            if (runner.selectionId == 7448571) {
                XCTAssertTrue(runner.status == BNGRunnerStatusActive, @"The runner with selectionId 7448571 should be marked as active in the market");
                XCTAssertTrue([runner.lastPriceTraded isEqual:[NSDecimalNumber decimalNumberWithString:@"18.5"]], @"The runner with selectionId 7448571 should have a last price traded value of 18.5");
                XCTAssertTrue([runner.totalMatched isEqual:[NSDecimalNumber decimalNumberWithString:@"7252.43"]], @"The runner with selectionId 7448571 should have a last price traded value of 7252.43");
            }
        }
        
        dispatch_semaphore_signal(semaphore);
        
    }];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
}

- (void)testMarketProfitAndLossApiCall
{
    [NSURLProtocol registerClass:[BNGURLProtocolResourceLoader class]];
    
    [[APING sharedInstance] registerApplicationKey:BNGTestUtilitiesApplicationKey ssoKey:BNGTestUtilitiesSSOKey];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [BNGMarketBook listMarketProfitAndLossForMarketIds:[[NSSet alloc] initWithArray:@[@"1.114084208"]] includeSettledBets:NO includeBspBets:NO netOfCommission:NO completionBlock:^(NSArray *results, NSError *connectionError, BNGAPIError *apiError) {
        
        XCTAssertTrue(results.count == 1, @"Only one record should be returned from the listMarketProfitAndLoss API call");
        BNGMarketProfitAndLoss *marketProfitAndLoss = results[0];
        
        XCTAssertTrue([marketProfitAndLoss.marketId isEqualToString:@"1.114084208"], @"The marketId string should be parsed correctly");
        XCTAssertTrue(marketProfitAndLoss.profitAndLosses.count == 20, @"There should be 20 pnls in the response");
        
        for (BNGRunnerProfitAndLoss *runnerProfitAndLoss in marketProfitAndLoss.profitAndLosses) {
            if (runnerProfitAndLoss.selectionId == 48351) {
                XCTAssertTrue([runnerProfitAndLoss.ifWin isEqualToNumber:[NSNumber numberWithInt:40]], @"The ifWin parameter should be parsed correctly");
                XCTAssertTrue([runnerProfitAndLoss.ifLose isEqualToNumber:[NSNumber numberWithInt:10]], @"The ifLose parameter should be parsed correctly");
            }
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
}

- (void)testBNGMarketBookTransformers
{
    XCTAssertTrue([BNGMarketBook marketStatusFromString:@"INVALID_STRING"] == BNGMarketStatusUnknown, @"A string of 'INVALID_STRING' should return an unknown market status from marketStatusFromString");
    XCTAssertTrue([BNGMarketBook marketStatusFromString:@"INACTIVE"] == BNGMarketStatusInactive, @"A string of 'INACTIVE' should return an inactive market status from marketStatusFromString");
}

- (void)testStringFromMatchProjection
{
    XCTAssertTrue([[BNGMarketBook stringFromMatchProjection:BNGMatchProjectionNoRollup] isEqualToString:@"NO_ROLLUP"], @"stringFromMatchProjection should return the appropriate value for NO_ROLLUP");
    XCTAssertTrue([[BNGMarketBook stringFromMatchProjection:BNGMatchProjectionRolledUpByAvgPrice] isEqualToString:@"ROLLED_UP_BY_AVG_PRICE"], @"stringFromMatchProjection should return the appropriate value for ROLLED_UP_BY_AVG_PRICE");
    XCTAssertTrue([[BNGMarketBook stringFromMatchProjection:BNGMatchProjectionRolledUpByPrice] isEqualToString:@"ROLLED_UP_BY_PRICE"], @"stringFromMatchProjection should return the appropriate value for ROLLED_UP_BY_PRICE");
}

@end
