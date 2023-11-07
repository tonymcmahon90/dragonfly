#include <Trade/Trade.mqh> 
CTrade trade;

ulong _ticket;

input int stoploss=200; // stoploss points
input int takeprofit=200; // takeprofit points
input double lotsize=0.1; // lotsize

int OnInit()
{
   MathSrand(GetTickCount()); // seed random number 
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double entry;

   if(_ticket==0)
   {
      if(MathRand()<16384) // half of the time buy 
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         if(trade.Buy(lotsize,NULL,entry,entry-(stoploss*_Point),entry+(takeprofit*_Point),NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
      else
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(trade.Sell(lotsize,NULL,entry,entry+(stoploss*_Point),entry-(takeprofit*_Point),NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
   }
   else
   {
      if(!PositionSelectByTicket(_ticket)) _ticket=0; // assume closed
   }
}