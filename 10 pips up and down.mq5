#include <Trade/Trade.mqh>
CTrade trade;

// show line 10 pips above and below AND propfit in pips of current trade 
#property description "T=Place trade M=Buy/Sell P=+5 pips reset at 50"

input int initpips=10; // pips up and down 
input int bars=20; // line length bars
input double lotsize=0; // lotsize or 0
input double riskpercent=0.5; // % risk or 0 
input double cashrisk=0; // cash risk

long chart_id;
bool mode=true; // sell=false buy=true 
int pips;
ulong _ticket=0;
double Ask,Bid;

int OnInit()
{
   chart_id=ChartID();
   Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   
   ObjectCreate(chart_id,"tp",OBJ_TREND,0,TimeCurrent(),Ask+(pips*Point()*10),TimeCurrent()-(bars*PeriodSeconds()),Ask+(pips*Point()*10));
   ObjectSetInteger(chart_id,"tp",OBJPROP_COLOR,clrBlue);
   ObjectSetInteger(chart_id,"tp",OBJPROP_RAY,false);
   ObjectCreate(chart_id,"sl",OBJ_TREND,0,TimeCurrent(),Ask-(pips*Point()*10),TimeCurrent()-(bars*PeriodSeconds()),Ask-(pips*Point()*10));
   ObjectSetInteger(chart_id,"sl",OBJPROP_COLOR,clrRed);
   ObjectSetInteger(chart_id,"sl",OBJPROP_RAY,false);
   ObjectCreate(chart_id,"profit",OBJ_LABEL,0,0,0);
   ObjectSetInteger(chart_id,"profit",OBJPROP_XDISTANCE,ChartGetInteger(chart_id,CHART_WIDTH_IN_PIXELS,0)-300);
   ObjectSetInteger(chart_id,"profit",OBJPROP_YDISTANCE,200);
   ObjectSetInteger(chart_id,"profit",OBJPROP_COLOR,clrGold);
   ObjectSetInteger(chart_id,"profit",OBJPROP_FONTSIZE,14);   
   ObjectSetString(chart_id,"profit",OBJPROP_TEXT,"Buy mode");
   pips=initpips;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectDelete(chart_id,"tp");
   ObjectDelete(chart_id,"sl");
   ObjectDelete(chart_id,"profit");
}

void OnTick()
{
   double tp,sl,profit;
   Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
 
   if(mode) tp=Ask+(pips*Point()*10); else tp=Bid-(pips*Point()*10);
   ObjectMove(chart_id,"tp",0,TimeCurrent(),tp);
   ObjectMove(chart_id,"tp",1,TimeCurrent()-(bars*PeriodSeconds()),tp);
   
   if(mode) sl=Ask-(pips*Point()*10); else sl=Bid+(pips*Point()*10);
   ObjectMove(chart_id,"sl",0,TimeCurrent(),sl);
   ObjectMove(chart_id,"sl",1,TimeCurrent()-(bars*PeriodSeconds()),sl);
   
   string txt;
   if(mode) txt="Buy mode"; else txt="Sell mode"; 
   
   if(PositionSelectByTicket(_ticket))
   {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) profit=Bid-PositionGetDouble(POSITION_PRICE_OPEN); 
      else profit=PositionGetDouble(POSITION_PRICE_OPEN)-Ask;
      txt=StringFormat("Pips %0.1f",profit/Point()/10);            
   }
   else _ticket=0;
   
   ObjectSetString(chart_id,"profit",OBJPROP_TEXT,txt);
}

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
{
   int ret=0;
   double lots;
   Ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   Bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   if(id==CHARTEVENT_KEYDOWN)
   {
      if(lparam=='M')
      { 
         mode=!mode; 
         if(mode) ObjectSetString(id,"profit",OBJPROP_TEXT,"Buy mode"); else ObjectSetString(id,"profit",OBJPROP_TEXT,"Sell mode"); 
         //WindowRedraw(); 
      }
      if(lparam=='T')
      {
         if(mode) // buy
         {
            lots=Lotsize();
            if(lots!=0)
            if(trade.Buy(lots,Symbol(),Ask,Ask-(pips*Point()*10),Ask+(pips*Point()*10),NULL))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
            }
         }
         else // sell
         {
            lots=Lotsize();
            if(lots!=0)
            if(trade.Sell(lots,Symbol(),Bid,Bid+(pips*Point()*10),Bid-(pips*Point()*10),NULL))
            {
               if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
            }
         }        
      }
      if(lparam=='P')
      {
         pips+=5;
         if(pips>50)pips=initpips;
         Print(pips," Pips sl/tp");
         //WindowRedraw();
      }
   }
}

double Lotsize()
{
   if(lotsize!=0) return lotsize;   
   double risk=0;   
   if(riskpercent!=0) risk=AccountInfoDouble(ACCOUNT_BALANCE)*riskpercent*0.01;
   if(cashrisk!=0) risk=cashrisk;
   if(risk==0){ Alert("Risk size not set"); return 0; }
   
   double tickvalue=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE),ticksize=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE);
   double ticks=((pips*10*Point())/ticksize);
   double ideallotsize=(risk*tickvalue)/ticks; 
   
   double tmp=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);   
   if(ideallotsize<tmp) return 0; // not enough to place minimum trade 
   
   while(true)
   {
      if(tmp+SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP)>ideallotsize) break; 
      if(tmp+SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP)>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; 
      tmp+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   }   
   return tmp;
}
