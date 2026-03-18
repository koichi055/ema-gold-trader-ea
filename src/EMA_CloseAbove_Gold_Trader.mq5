//+------------------------------------------------------------------+
//| EMA_CloseAbove_Gold_Trader.mq5                                  |
//| Estrategia BUY-only en XAUUSD basada en vela cerrando sobre EMA |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.30"
#property strict

//--- Parámetros de entrada
input string          InpSymbol        = "XAUUSD";
input ENUM_TIMEFRAMES InpTF           = PERIOD_H1;
input double          InpLot          = 0.01;

//--- EMA para entrada
input int             InpEMAPeriod    = 50;
input ENUM_TIMEFRAMES InpEMATF        = PERIOD_H1;

//--- DEMA (se mantiene igual para confirmación)
input int             InpDemaPeriod   = 50;
input ENUM_TIMEFRAMES InpDemaTF      = PERIOD_H1;

//--- Gestión de posiciones
input int             InpMaxTrades    = 3;
input int             InpSlippage     = 30;
input double          InpTrailStart   = 200;
input double          InpTrailStep    = 100;
input ulong           InpMagic        = 20260301;

//--- Protección
input double          InpDailyLossLimit = 500.0; // pérdida diaria máxima $
input int             InpMaxSpread      = 50;    // spread máximo permitido (points)

//--- Variables globales
int      emaHandle   = INVALID_HANDLE;
int      demaHandle  = INVALID_HANDLE;
datetime lastBarTime = 0;
datetime currentDay  = 0;
bool     tradingBlockedToday = false;

//+------------------------------------------------------------------+
int OnInit()
{
//--- Crear handle de EMA (nueva condición de entrada)
emaHandle = iMA(InpSymbol, InpEMATF, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE); // [web:3][web:23]
if(emaHandle == INVALID_HANDLE)
return(INIT_FAILED);

//--- DEMA (igual que antes)
demaHandle = iDEMA(InpSymbol, InpDemaTF, InpDemaPeriod, 0, PRICE_CLOSE);
if(demaHandle == INVALID_HANDLE)
return(INIT_FAILED);

currentDay = iTime(InpSymbol, PERIOD_D1, 0);
return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
if(_Symbol != InpSymbol)
return;

ResetDailyState();
if(CheckDailyLossLimit())
return;
if(tradingBlockedToday)
return;
if(!SpreadOK())
return;

ManageTrailingStops();

MqlRates rates[];
if(CopyRates(InpSymbol, InpTF, 0, 3, rates) < 3)
return;

datetime currentBarTime = rates[0].time;
if(currentBarTime == lastBarTime)
return;

lastBarTime = currentBarTime;

CheckForEntry();
}

//+------------------------------------------------------------------+
void ResetDailyState()
{
datetime newDay = iTime(InpSymbol, PERIOD_D1, 0);
if(newDay != currentDay)
{
currentDay = newDay;
tradingBlockedToday = false;
Print("Nuevo día, trading reactivado.");
}
}

//+------------------------------------------------------------------+
bool SpreadOK()
{
double spread = (SymbolInfoDouble(InpSymbol, SYMBOL_ASK) - SymbolInfoDouble(InpSymbol, SYMBOL_BID)) /
SymbolInfoDouble(InpSymbol, SYMBOL_POINT);
if(spread > InpMaxSpread)
return false;
return true;
}

//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
{
double closedLoss   = GetTodayClosedLoss();
double floatingLoss = GetFloatingLoss();
double totalLoss    = closedLoss + floatingLoss;

if(totalLoss >= InpDailyLossLimit)
{
Print("Límite diario alcanzado: ", totalLoss);
CloseAllPositions();
tradingBlockedToday = true;
return true;
}
return false;
}

//+------------------------------------------------------------------+
double GetTodayClosedLoss()
{
datetime dayStart = iTime(InpSymbol, PERIOD_D1, 0);
if(!HistorySelect(dayStart, TimeCurrent()))
return 0;
double loss = 0;
for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
{
ulong ticket = HistoryDealGetTicket(i);
if(HistoryDealGetString(ticket, DEAL_SYMBOL) != InpSymbol)
continue;
if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != (long)InpMagic)
continue;
if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT)
continue;

```
  double profit =
     HistoryDealGetDouble(ticket, DEAL_PROFIT) +
     HistoryDealGetDouble(ticket, DEAL_SWAP) +
     HistoryDealGetDouble(ticket, DEAL_COMMISSION);

  if(profit < 0)
     loss += MathAbs(profit);
 }
```

return loss;
}

//+------------------------------------------------------------------+
double GetFloatingLoss()
{
double loss = 0;
for(int i = PositionsTotal() - 1; i >= 0; i--)
{
ulong ticket = PositionGetTicket(i);
if(!PositionSelectByTicket(ticket))
continue;
if(PositionGetString(POSITION_SYMBOL) != InpSymbol)
continue;
if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagic)
continue;

```
  double profit = PositionGetDouble(POSITION_PROFIT);
  if(profit < 0)
     loss += MathAbs(profit);
 }
```

return loss;
}

//+------------------------------------------------------------------+
void CloseAllPositions()
{
for(int i = PositionsTotal() - 1; i >= 0; i--)
{
ulong ticket = PositionGetTicket(i);
if(!PositionSelectByTicket(ticket))
continue;
if(PositionGetString(POSITION_SYMBOL) != InpSymbol)
continue;
if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagic)
continue;

```
  long   type   = PositionGetInteger(POSITION_TYPE);
  double volume = PositionGetDouble(POSITION_VOLUME);

  MqlTradeRequest request;
  MqlTradeResult  result;

  ZeroMemory(request);
  ZeroMemory(result);

  request.action   = TRADE_ACTION_DEAL;
  request.position = ticket;
  request.symbol   = InpSymbol;
  request.volume   = volume;
  request.magic    = InpMagic;
  request.deviation= InpSlippage;

  if(type == POSITION_TYPE_BUY)
    {
     request.type  = ORDER_TYPE_SELL;
     request.price = SymbolInfoDouble(InpSymbol, SYMBOL_BID);
    }
  else
    {
     request.type  = ORDER_TYPE_BUY;
     request.price = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);
    }

  request.type_filling = ORDER_FILLING_FOK;

  OrderSend(request, result);
 }
```

}

//+------------------------------------------------------------------+
//  NUEVA LÓGICA DE ENTRADA: vela cerrando por encima de la EMA
//  Mantiene confirmación con DEMA como antes.
//+------------------------------------------------------------------+
void CheckForEntry()
{
int buyCount = 0;
for(int i = PositionsTotal() - 1; i >= 0; i--)
{
ulong ticket = PositionGetTicket(i);
if(!PositionSelectByTicket(ticket))
continue;

```
  if(PositionGetString(POSITION_SYMBOL) == InpSymbol &&
     PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY &&
     PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
     buyCount++;
 }
```

if(buyCount >= InpMaxTrades)
return;

//--- Obtener valor de EMA en la vela cerrada anterior (shift 1)
double emaBuffer[];
if(CopyBuffer(emaHandle, 0, 1, 1, emaBuffer) != 1)
return;
double emaValue = emaBuffer[0];

//--- Close de esa misma vela
double closeArr[];
if(CopyClose(InpSymbol, InpEMATF, 1, 1, closeArr) != 1)
return;
double closePrice = closeArr[0];

//--- Confirmación con DEMA igual que antes
double demaBuffer[];
if(CopyBuffer(demaHandle, 0, 1, 1, demaBuffer) != 1)
return;
double dema = demaBuffer[0];

// Condición: vela cerrada por encima de la EMA y por encima de la DEMA
if(closePrice > emaValue && closePrice > dema)
OpenBuy();
}

//+------------------------------------------------------------------+
void OpenBuy()
{
double ask = SymbolInfoDouble(InpSymbol, SYMBOL_ASK);

MqlTradeRequest request;
MqlTradeResult  result;

ZeroMemory(request);
ZeroMemory(result);

request.action      = TRADE_ACTION_DEAL;
request.symbol      = InpSymbol;
request.magic       = InpMagic;
request.volume      = InpLot;
request.type        = ORDER_TYPE_BUY;
request.price       = ask;
request.deviation   = InpSlippage;
request.type_filling= ORDER_FILLING_FOK;

OrderSend(request, result);
}

//+------------------------------------------------------------------+
void ManageTrailingStops()
{
double point = SymbolInfoDouble(InpSymbol, SYMBOL_POINT);

for(int i = PositionsTotal() - 1; i >= 0; i--)
{
ulong ticket = PositionGetTicket(i);
if(!PositionSelectByTicket(ticket))
continue;

```
  if(PositionGetString(POSITION_SYMBOL) != InpSymbol)
     continue;
  if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagic)
     continue;

  double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  double sl        = PositionGetDouble(POSITION_SL);
  double tp        = PositionGetDouble(POSITION_TP);
  double bid       = SymbolInfoDouble(InpSymbol, SYMBOL_BID);

  double profitPoints = (bid - openPrice) / point;
  if(profitPoints <= InpTrailStart)
     continue;

  double newSL = bid - InpTrailStep * point;
  if(sl != 0 && newSL <= sl)
     continue;

  MqlTradeRequest request;
  MqlTradeResult  result;

  ZeroMemory(request);
  ZeroMemory(result);

  request.action   = TRADE_ACTION_SLTP;
  request.symbol   = InpSymbol;
  request.position = ticket;
  request.sl       = newSL;
  request.tp       = tp;

  OrderSend(request, result);
 }
```

}
//+------------------------------------------------------------------+
