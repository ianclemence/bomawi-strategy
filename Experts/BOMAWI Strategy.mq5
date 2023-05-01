//+------------------------------------------------------------------+
//|                                              BOMAWI Strategy.mq5 |
//|                                                     Ian Clemence |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Ian Clemence"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include  <CustomFunctions.mqh>

#define EXPERT_MAGIC 55555

input double riskPerTrade = 0.02;

//Bolinger bands
input int bbPeriod = 20;
input int bandStdEntry = 2;
input int bandStdProfitExit = 1;
input int bandStdLossExit = 6;

//MACD
input int macdFast = 12;
input int macdSlow = 26;
input int macdSignal = 9;

//William % R
input int willPeriod = 14;
input int willLowerLevel = -80;
input int willUpperLevel = -20;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Alert("");
   Alert("Starting BOMAWI Strategy");

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Alert("Stopping BOMAWI Strategy");

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
//define Ask, Bid
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

//create an array for Bollinger Bands
   double MiddleBandArray[];
   double UpperBandEntryArray[];
   double LowerBandEntryArray[];

   double UpperBandProfitArray[];
   double LowerBandProfitArray[];

   double UpperBandLossArray[];
   double LowerBandLossArray[];

//sort the price array from the current candle downwards
   ArraySetAsSeries(MiddleBandArray, true);
   ArraySetAsSeries(UpperBandEntryArray, true);
   ArraySetAsSeries(LowerBandEntryArray, true);

   ArraySetAsSeries(UpperBandProfitArray, true);
   ArraySetAsSeries(LowerBandProfitArray, true);

   ArraySetAsSeries(UpperBandLossArray, true);
   ArraySetAsSeries(LowerBandLossArray, true);

//define Bollinger Bands
   int BollingerBands1 = iBands(_Symbol, PERIOD_CURRENT, bbPeriod, 0, bandStdEntry,PRICE_CLOSE);
   int BollingerBands2 = iBands(_Symbol, PERIOD_CURRENT, bbPeriod, 0, bandStdProfitExit, PRICE_CLOSE);
   int BollingerBands3 = iBands(_Symbol, PERIOD_CURRENT, bbPeriod, 0, bandStdLossExit, PRICE_CLOSE);

//copy price info into the array
   CopyBuffer(BollingerBands1,0,0,3,MiddleBandArray);
   CopyBuffer(BollingerBands1,1,0,3,UpperBandEntryArray);
   CopyBuffer(BollingerBands1,2,0,3,LowerBandEntryArray);

   CopyBuffer(BollingerBands2,1,0,3,UpperBandProfitArray);
   CopyBuffer(BollingerBands2,2,0,3,LowerBandProfitArray);

   CopyBuffer(BollingerBands3,1,0,3,UpperBandLossArray);
   CopyBuffer(BollingerBands3,2,0,3,LowerBandLossArray);

//calculate EA for the current candle
   double bbMid = MiddleBandArray[0];
   double bbUpperEntry = UpperBandEntryArray[0];
   double bbLowerEntry = LowerBandEntryArray[0];

   double bbUpperProfitExit = UpperBandProfitArray[0];
   double bbLowerProfitExit = LowerBandProfitArray[0];

   double bbUpperLossExit = UpperBandLossArray[0];
   double bbLowerLossExit = LowerBandLossArray[0];

//cretaing an array for prices for MACD main line, MACD signal line
   double MACDMainLine[];
   double MACDSignalLine[];

//Defining MACD and its parameters
   int MACDDef = iMACD(_Symbol, PERIOD_CURRENT, macdFast, macdSlow, macdSignal, PRICE_CLOSE);
//Sorting price array from current data for MACD main line, MACD signal line
   ArraySetAsSeries(MACDMainLine,true);
//Storing results after defining MA, line, current data for MACD main line
   CopyBuffer(MACDDef,0,0,3,MACDMainLine);
//Get values of current data for MACD main line, MACD signal line
   float MACDMainLineVal = (MACDMainLine[0]);

//create an array for Williams' Percent Range
   double WPArray[];
//sort the price array from the current candle downwards
   ArraySetAsSeries(WPArray,true);
//define Williams' Percent Range
   int WPDef = iWPR(_Symbol, PERIOD_CURRENT, willPeriod);
//copy price info into the array
   CopyBuffer(WPDef,0,0,3,WPArray);
//Get value of current data for Williams' Percent Range
   double WPVal = NormalizeDouble(WPArray[0],2);


//number of decimal places (precision)
   int digits = SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);

   if(CheckIfOpenPositionsByMagicNumber(EXPERT_MAGIC) == false)//if no open orders try to enter new position
     {
      if(Ask < bbLowerEntry && iOpen(NULL,0,0) > bbLowerEntry && WPVal < willLowerLevel && MACDMainLineVal < 0) //buying order
        {
         Comment("Buy signal","\n",
                 "Lower Band Value is ",bbLowerEntry,"\n",
                 "MACD Main Line Value is ",MACDMainLineVal,"\n",
                 "Williams % R Value is ",WPVal);

         double stopLossPrice = NormalizeDouble(bbLowerLossExit, digits);
         double takeProfitPrice = NormalizeDouble(bbUpperProfitExit, digits);

         double lotSize = OptimalLotSize(riskPerTrade, Ask, stopLossPrice);

         int orderID = SendOrder(EXPERT_MAGIC, Symbol(), lotSize, stopLossPrice, takeProfitPrice, ORDER_TYPE_BUY_LIMIT, Ask);
         if(orderID < 0)
           {
            Alert("OrderSend error %d", GetLastError());
           }
        }
      else
         if(Bid > bbUpperEntry && iOpen(NULL,0,0) < bbUpperEntry && WPVal > willUpperLevel && MACDMainLineVal > 0) //selling order
           {
            Comment("Sell signal","\n",
                    "Lower Band Value is ",bbUpperEntry,"\n",
                    "MACD Main Line Value is ",MACDMainLineVal,"\n",
                    "Williams % R Value is ",WPVal);

            double stopLossPrice = NormalizeDouble(bbUpperLossExit, digits);
            double takeProfitPrice = NormalizeDouble(bbLowerProfitExit, digits);

            double lotSize = OptimalLotSize(riskPerTrade, Bid, stopLossPrice);

            int orderID = SendOrder(EXPERT_MAGIC, Symbol(), lotSize, stopLossPrice, takeProfitPrice, ORDER_TYPE_SELL_LIMIT, Bid);
            if(orderID < 0)
              {
               Alert("OrderSend error %d", GetLastError());
              }
           }
     }
   else //else if you already have a position, update the position if you need to.
     {
      MqlTradeRequest request;
      MqlTradeResult  result;
      double optimalTakeProfit;
      double optimalStopLoss;
      double TP;
      double TPdistance;

      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         ulong positionTicket = PositionGetTicket(i);// ticket of the position

         if(PositionSelectByTicket(positionTicket) && POSITION_MAGIC == EXPERT_MAGIC && PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            //--- parameters of the order
            string positionSymbol = PositionGetString(POSITION_SYMBOL); // symbol
            int digits = (int)SymbolInfoInteger(positionSymbol,SYMBOL_DIGITS); // number of decimal places
            ulong magic = PositionGetInteger(POSITION_MAGIC); // MagicNumber of the position
            double volume = PositionGetDouble(POSITION_VOLUME);    // volume of the position
            double stopLoss = PositionGetDouble(POSITION_SL);  // Stop Loss of the position
            double takeProfit = PositionGetDouble(POSITION_TP);  // Take Profit of the position
            double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN); // Position open price
            ENUM_POSITION_TYPE positionType=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);  // type of the position

            if(positionType == POSITION_TYPE_BUY)//long position
              {
               if(iClose(_Symbol,0,1) > (posOpenPrice + 1000 * SymbolInfoDouble(_Symbol,SYMBOL_POINT)))
                 {
                  optimalStopLoss = posOpenPrice;

                  if(optimalStopLoss > stopLoss)
                    {
                     optimalTakeProfit = NormalizeDouble(bbUpperProfitExit, digits);
                    }

                  TP = PositionGetDouble(POSITION_TP);
                  TPdistance = MathAbs(TP - optimalTakeProfit);
                 }
              }
            else
               if(positionType == POSITION_TYPE_SELL) //short position
                 {
                  if(iClose(_Symbol,0,1) < (posOpenPrice - 1000 * SymbolInfoDouble(_Symbol,SYMBOL_POINT)))
                    {
                     optimalStopLoss = posOpenPrice;

                     if(optimalStopLoss < stopLoss)
                       {
                        optimalTakeProfit = NormalizeDouble(bbLowerProfitExit, digits);
                       }

                     TP = PositionGetDouble(POSITION_TP);
                     TPdistance = MathAbs(TP - optimalTakeProfit);
                    }
                 }

            if(TP != optimalTakeProfit && TPdistance > 0.0001)
              {
               // --- zeroing the request and result values
               ZeroMemory(request);
               ZeroMemory(result);
               // --- setting the operation parameters
               request.action = TRADE_ACTION_SLTP ; // type of trade operation
               request.position = positionTicket;   // ticket of the position
               request.symbol = positionSymbol;     // symbol
               request.sl = optimalStopLoss;                // Stop Loss of the position
               request.tp = optimalTakeProfit;                // Take Profit of the position
               request.magic = EXPERT_MAGIC;         // MagicNumber of the position
               // --- output information about the modification
               PrintFormat("Modify #% I64d% s% s", positionTicket, positionSymbol, positionType);
               // --- send the request
               if(!OrderSend(request, result))
                  Alert("OrderSend error %d", + GetLastError());  // if unable to send the request, output the error code
               // --- information about the operation
               PrintFormat("retcode=%u  deal=%I64u  order=%I64u", result.retcode, result.deal, result.order);
              }

           }
        }

     }

  }
//+------------------------------------------------------------------+
