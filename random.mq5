#include <Trade/Trade.mqh> // Standard Library Trade Class
CTrade trade;

ulong _ticket;

input int stoploss=500; // stoploss points
input int takeprofit=500; // takeprofit points
input double percentrisk=1.5; // % risk 

int OnInit()
{
   MathSrand(GetTickCount()); // seed random number 
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double entry,lotsize;

   if(_ticket==0) // wait for no open positions 
   {
      if(MathRand()<16384) // ~50% of the time buy 
      {
         entry=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         lotsize=CalcLotsize(stoploss*Point());
         if(lotsize!=0)
         {
            if(trade.Buy(lotsize,NULL,entry,entry-(stoploss*Point()),entry+(takeprofit*Point()),NULL))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
            }
         }
      }
      else // sell
      {
         entry=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         lotsize=CalcLotsize(stoploss*Point());
         if(lotsize!=0)
         {
            if(trade.Sell(lotsize,NULL,entry,entry+(stoploss*Point()),entry-(takeprofit*Point()),NULL))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
            }
         }
      }
   }
   else
   {
      if(!PositionSelectByTicket(_ticket)) _ticket=0; // assume closed
   }
}

double CalcLotsize(double pricerisk) // i.e. 0.00100 is risk 100 points = 10 pips
{
   double tmplotsize=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN); // minimum lotsize 0.01
   double calc=tmplotsize; 
   double cashrisk=AccountInfoDouble(ACCOUNT_BALANCE)*percentrisk*0.01; // £10000 * 1% = £100
   double tickrisk=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE)*(pricerisk/SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)); // risk per 1.00 lot
   // tickvalue is 1 tick and 1.00 lot, 1 point/tick of EURUSD=$1/tick or point per 1.0 lot, this value is in account currency 
   
   if((tmplotsize*tickrisk)>cashrisk) return(0); // can't do minimum trade 0.01 > 1%
   
   while(true) // find nearest correct lotsize < 1%
   {
      if((tmplotsize*tickrisk)>cashrisk) break;
      calc=tmplotsize;
      tmplotsize+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
      if(tmplotsize>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; // maximum trade size      
   }
   
   return(calc);
}
