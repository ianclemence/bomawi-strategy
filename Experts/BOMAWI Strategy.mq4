//+------------------------------------------------------------------+
//|                                                  BOMAWI Strategy.mq4 |
//|                                                     Ian Clemence |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Ian Clemence"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs
#include  <CustomFunctions.mqh>

input double riskPerTrade = 0.02;

int magicNB = 55555;

int openOrderID;

//Bolinger bands
input int bbPeriod = 20;
input int bandStdEntry = 2;
input int bandStdProfitExit = 1;
input int bandStdLossExit = 6;

//MACD
input int macd_fast = 12;
input int macd_slow = 26;
input int macd_signal = 9;

//William % R
input int willPeriod = 9;
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
   double bbLowerEntry = iBands(NULL,0,bbPeriod,bandStdEntry,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpperEntry = iBands(NULL,0,bbPeriod,bandStdEntry,0,PRICE_CLOSE,MODE_UPPER,0);
   double bbMid = iBands(NULL,0,bbPeriod,bandStdEntry,0,PRICE_CLOSE,0,0);
   
   double bbLowerProfitExit = iBands(NULL,0,bbPeriod,bandStdProfitExit,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpperProfitExit = iBands(NULL,0,bbPeriod,bandStdProfitExit,0,PRICE_CLOSE,MODE_UPPER,0);
   
   double bbLowerLossExit = iBands(NULL,0,bbPeriod,bandStdLossExit,0,PRICE_CLOSE,MODE_LOWER,0);
   double bbUpperLossExit = iBands(NULL,0,bbPeriod,bandStdLossExit,0,PRICE_CLOSE,MODE_UPPER,0);
   
   double macdValue = iMACD(NULL,0,macd_fast,macd_slow,macd_signal,PRICE_CLOSE,MODE_MAIN,0);
   
   double willValue = iWPR(NULL,0,willPeriod,0);
   
   if(!CheckIfOpenOrdersByMagicNB(magicNB))//if no open orders try to enter new position
   {
      if(Ask < bbLowerEntry && Open[0] > bbLowerEntry && willValue < willLowerLevel && macdValue < 0)//buying
      {
         Print("Price is below bbLower, willValue is lower than " + willLowerLevel+ " and macdValue is less than 0, Sending buy order");
         double stopLossPrice = NormalizeDouble(bbLowerLossExit,Digits);
         double takeProfitPrice = NormalizeDouble(bbUpperProfitExit,Digits);;
         Print("Entry Price = " + Ask);
         Print("Stop Loss Price = " + stopLossPrice);
         Print("Take Profit Price = " + takeProfitPrice);
         
         double lotSize = OptimalLotSize(riskPerTrade,Ask,stopLossPrice);
         
         openOrderID = OrderSend(NULL,OP_BUYLIMIT,lotSize,Ask,10,stopLossPrice,takeProfitPrice,NULL,magicNB);
         if(openOrderID < 0) Alert("Order rejected. Order error: " + GetLastError());
      }
      else if(Bid > bbUpperEntry && Open[0] < bbUpperEntry && willValue > willUpperLevel && macdValue > 0)//shorting
      {
         Print("Price is above bbUpper, willValue is above " + willUpperLevel + " and macdValue is less than 0, Sending short order");
         double stopLossPrice = NormalizeDouble(bbUpperLossExit,Digits);
         double takeProfitPrice = NormalizeDouble(bbLowerProfitExit,Digits);
         Print("Entry Price = " + Bid);
         Print("Stop Loss Price = " + stopLossPrice);
         Print("Take Profit Price = " + takeProfitPrice);
   	  
   	  double lotSize = OptimalLotSize(riskPerTrade,Bid,stopLossPrice);

   	  openOrderID = OrderSend(NULL,OP_SELLLIMIT,lotSize,Bid,10,stopLossPrice,takeProfitPrice,NULL,magicNB);
   	  if(openOrderID < 0) Alert("Order rejected. Order error: " + GetLastError());
      }   
   }
   else //else if you already have a position, update orders if need too.
   {
      if(OrderSelect(openOrderID,SELECT_BY_TICKET)==true)
      {
            int orderType = OrderType();// Short = 1, Long = 0

            double optimalTakeProfit;
            
            if(orderType == 0)//long position
            {
               optimalTakeProfit = NormalizeDouble(bbUpperProfitExit,Digits);
               
            }
            else //if short
            {
               optimalTakeProfit = NormalizeDouble(bbLowerProfitExit,Digits);
            }

            double TP = OrderTakeProfit();
            double TPdistance = MathAbs(TP - optimalTakeProfit);
            if(TP != optimalTakeProfit && TPdistance > 0.0001)
            {
               bool Ans = OrderModify(openOrderID,OrderOpenPrice(),OrderStopLoss(),optimalTakeProfit,0);
            
               if (Ans==true)                     
               {
                  Print("Order modified: ",openOrderID);
                  return;                           
               }else
               {
                  Print("Unable to modify order: ",openOrderID);
               }   
            }
         }
      }   
  }
//+------------------------------------------------------------------+
