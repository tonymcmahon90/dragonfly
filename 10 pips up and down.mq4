// show line 10 pips above and below AND propfit in pips of current trade 
#property strict
#property description "T=Place trade M=Buy/Sell P=+5 pips reset at 50"

input int initpips=10; // pips up and down 
input int bars=20; // line length bars
input double lotsize=0; // lotsize or 0
input double riskpercent=0.5; // % risk or 0 
input double cashrisk=0; // cash risk

long chart_id;
bool mode=true; // sell=false buy=true 
int order=0,pips;

int OnInit()
{
   chart_id=ChartID();
   ObjectCreate(chart_id,"tp",OBJ_TREND,0,TimeCurrent(),Ask+(pips*Point()*10),TimeCurrent()-(bars*PeriodSeconds()),Ask+(pips*Point()*10));
   ObjectSetInteger(chart_id,"tp",OBJPROP_COLOR,clrBlue);
   ObjectSetInteger(chart_id,"tp",OBJPROP_RAY,false);
   ObjectCreate(chart_id,"sl",OBJ_TREND,0,TimeCurrent(),Ask-(pips*Point()*10),TimeCurrent()-(bars*PeriodSeconds()),Ask-(pips*Point()*10));
   ObjectSetInteger(chart_id,"sl",OBJPROP_COLOR,clrRed);
   ObjectSetInteger(chart_id,"sl",OBJPROP_RAY,false);
   ObjectCreate(chart_id,"profit",OBJ_LABEL,0,0,0);
   ObjectSetInteger(chart_id,"profit",OBJPROP_XDISTANCE,ChartGetInteger(chart_id,CHART_WIDTH_IN_PIXELS,0)-500);
   ObjectSetInteger(chart_id,"profit",OBJPROP_YDISTANCE,200);
   ObjectSetInteger(chart_id,"profit",OBJPROP_COLOR,clrGold);
   ObjectSetInteger(chart_id,"profit",OBJPROP_FONTSIZE,20);   
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

   ObjectSetInteger(chart_id,"tp",OBJPROP_TIME1,TimeCurrent());
   ObjectSetInteger(chart_id,"tp",OBJPROP_TIME2,TimeCurrent()-(bars*PeriodSeconds()));
   if(mode) tp=Ask+(pips*Point()*10); else tp=Bid-(pips*Point()*10);
   ObjectSetDouble(chart_id,"tp",OBJPROP_PRICE1,tp);
   ObjectSetDouble(chart_id,"tp",OBJPROP_PRICE2,tp);
   
   ObjectSetInteger(chart_id,"sl",OBJPROP_TIME1,TimeCurrent());
   ObjectSetInteger(chart_id,"sl",OBJPROP_TIME2,TimeCurrent()-(bars*PeriodSeconds()));
   if(mode) sl=Ask-(pips*Point()*10); else sl=Bid+(pips*Point()*10);
   ObjectSetDouble(chart_id,"sl",OBJPROP_PRICE1,sl);
   ObjectSetDouble(chart_id,"sl",OBJPROP_PRICE2,sl);     
   
   string txt;
   if(mode) txt="Buy mode"; else txt="Sell mode"; 
   if(order)
   {
      if(OrderSelect(order,SELECT_BY_TICKET))
      {
         if(OrderCloseTime()==0) // open
         {
            if(OrderType()==OP_BUY) profit=Bid-OrderOpenPrice(); else profit=OrderOpenPrice()-Ask;         
            txt=StringFormat("Pips %0.1f",profit/Point()/10);            
         }
      }
   }    
   ObjectSetString(chart_id,"profit",OBJPROP_TEXT,txt);
}

void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
{
   int ret=0;
   double lots;

   if(id==CHARTEVENT_KEYDOWN)
   {
      if(lparam=='M')
      { 
         mode=!mode; 
         if(mode) ObjectSetString(id,"profit",OBJPROP_TEXT,"Buy mode"); else ObjectSetString(id,"profit",OBJPROP_TEXT,"Sell mode"); 
         WindowRedraw(); 
      }
      if(lparam=='T')
      {
         if(mode) // buy
         {
            lots=Lotsize();
            if(lots!=0)
               ret=OrderSend(Symbol(),OP_BUY,lots,Ask,10,Ask-(pips*Point()*10),Ask+(pips*Point()*10),NULL,0,0,clrNONE);
         }
         else // sell
         {
            lots=Lotsize();
            if(lots!=0)
               ret=OrderSend(Symbol(),OP_SELL,lots,Bid,10,Bid+(pips*Point()*10),Bid-(pips*Point()*10),NULL,0,0,clrNONE);
         }
         if(ret==-1) Print("OrderSend Error ",GetLastError()); else order=ret; 
      }
      if(lparam=='P')
      {
         pips+=5;
         if(pips>50)pips=initpips;
         Print(pips," Pips sl/tp");
         WindowRedraw();
      }
   }
}

double Lotsize()
{
   if(lotsize!=0) return lotsize;   
   double risk=0;   
   if(riskpercent!=0) risk=AccountBalance()*riskpercent*0.01;
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
