# BOMAWI Strategy

This is a forex trading strategy coded in MQL5 that utilizes Bollinger
Bands, MACD, and William's Percent Range (WPR) indicators to identify
potential trade opportunities.

## Strategy Parameters

The strategy has the following parameters that can be customized:

-   `riskPerTrade` - determines the percentage of the account balance to
    risk per trade.
-   `bbPeriod`, `bandStdEntry`, `bandStdProfitExit`, `bandStdLossExit` -
    parameters for the Bollinger Bands indicator.
-   `macdFast`, `macdSlow`, `macdSignal` - parameters for the MACD
    indicator.
-   `willPeriod`, `willLowerLevel`, `willUpperLevel` - parameters for
    the William's Percent Range indicator.

## Trading Rules

The strategy enters a long position if the following conditions are
met: - the current Ask price is below the lower Bollinger Band; - the
previous candle's open price is above the lower Bollinger Band; - the
current William's Percent Range value is lower than `willLowerLevel`; -
the MACD main line is negative.

The strategy enters a short position if the following conditions are
met: - the current Bid price is above the upper Bollinger Band; - the
previous candle's open price is below the upper Bollinger Band; - the
current William's Percent Range value is higher than `willUpperLevel`; -
the MACD main line is positive.

The strategy places a buy limit order at the lower Bollinger Band with
the stop loss at the lower Bollinger Band minus `bandStdLossExit`
standard deviations and the take profit at the upper Bollinger Band plus
`bandStdProfitExit` standard deviations. The lot size is determined
based on the `riskPerTrade` parameter.

The strategy places a sell limit order at the upper Bollinger Band with
the stop loss at the upper Bollinger Band plus `bandStdLossExit`
standard deviations and the take profit at the lower Bollinger Band
minus `bandStdProfitExit` standard deviations. The lot size is
determined based on the `riskPerTrade` parameter.

## Disclaimer

Trading involves risk and past performance is not indicative of future results. The algorithm provided in this repository is for educational purposes only and should not be used for live trading without thorough testing and analysis. The author and publisher of this repository are not responsible for any losses incurred as a result of using this algorithm.
