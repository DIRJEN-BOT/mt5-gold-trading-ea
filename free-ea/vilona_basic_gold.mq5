//+------------------------------------------------------------------+
//|                                             Vilona Basic Gold    |
//|                                          Simple EMA Crossover EA |
//|                                       Free MT5 Gold Trading Tool |
//+------------------------------------------------------------------+
#property copyright "Vilona Systems"
#property link      "https://github.com/codergaboets/mt5-gold-trading-ea"
#property version   "1.00"
#property description "Vilona Basic Gold - Free EMA Crossover EA for XAUUSD"
#property description "Simple, transparent, no martingale, no grid, no hedge"

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input double   InpRiskPct     = 1.0;          // Risk per trade (%)
input int      InpFastEMA     = 20;           // Fast EMA period
input int      InpSlowEMA     = 50;           // Slow EMA period
input int      InpStopLossPts = 3000;         // Stop Loss (points)
input int      InpTakeProfitPts = 6000;       // Take Profit (points)
input int      InpMagic       = 110001;       // Magic number
input int      InpSignalTF    = 15;           // Signal timeframe (minutes)

//+------------------------------------------------------------------+
//| HUD Panel (simplified Vilona style)                              |
//+------------------------------------------------------------------+
#define HUD_PREFIX "VLB_"

int g_hud_created = 0;
int g_hud_obj_count = 0;
string g_hud_names[100];

// Handles
int g_fast_ema_h = INVALID_HANDLE;
int g_slow_ema_h = INVALID_HANDLE;

// Signal state
int g_signal = 0;  // 1 = buy, 0 = flat, -1 = sell
int g_prev_signal = 0;

//+------------------------------------------------------------------+
//| Helper: create HUD object                                        |
//+------------------------------------------------------------------+
void HudObj(string name, int type, int x, int y, int w, int h)
{
   string full = HUD_PREFIX + name;
   if (ObjectFind(0, full) >= 0) return;
   ObjectCreate(0, full, (type == 0) ? OBJ_RECTANGLE_LABEL : OBJ_LABEL, 0, 0, 0);
   if (type == 0)
   {
      ObjectSetInteger(0, full, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, full, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, full, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, full, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, full, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, full, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, full, OBJPROP_BACK, true);
      ObjectSetInteger(0, full, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, full, OBJPROP_HIDDEN, true);
   }
   else
   {
      ObjectSetInteger(0, full, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, full, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, full, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, full, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, full, OBJPROP_HIDDEN, true);
   }
   g_hud_names[g_hud_obj_count] = full;
   g_hud_obj_count++;
}

//+------------------------------------------------------------------+
//| Helper: set HUD text                                             |
//+------------------------------------------------------------------+
void HudText(string name, string text, color clr)
{
   string full = HUD_PREFIX + name;
   ObjectSetString(0, full, OBJPROP_TEXT, text);
   ObjectSetInteger(0, full, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Create HUD panel                                                 |
//+------------------------------------------------------------------+
void HudCreate()
{
   if (ObjectFind(0, HUD_PREFIX + "BG") >= 0) return;
   g_hud_obj_count = 0;
   const int X = 8, Y = 48, W = 220, H = 160;

   // Background
   HudObj("BG", 0, X, Y, W, H);
   ObjectSetInteger(0, HUD_PREFIX + "BG", OBJPROP_BGCOLOR, (color)0x1B140E);

   // Accent bar
   HudObj("ACCENT", 0, X, Y, 3, H);
   ObjectSetInteger(0, HUD_PREFIX + "ACCENT", OBJPROP_BGCOLOR, (color)0xE94560);

   // Title bar
   HudObj("TITLE_BG", 0, X + 3, Y, W - 3, 22);
   ObjectSetInteger(0, HUD_PREFIX + "TITLE_BG", OBJPROP_BGCOLOR, (color)0x0E141B);
   HudObj("TITLE", 1, X + 12, Y + 4, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "TITLE", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, HUD_PREFIX + "TITLE", OBJPROP_FONT, "Consolas");
   ObjectSetString(0, HUD_PREFIX + "TITLE", OBJPROP_TEXT, "VILONA BASIC GOLD");

   // Signal dot
   HudObj("SIG_DOT", 0, X + W - 20, Y + 5, 10, 10);
   ObjectSetInteger(0, HUD_PREFIX + "SIG_DOT", OBJPROP_BGCOLOR, clrGray);

   // Divider
   HudObj("DIV1", 0, X + 10, Y + 24, W - 20, 1);
   ObjectSetInteger(0, HUD_PREFIX + "DIV1", OBJPROP_BGCOLOR, (color)0x50402E);

   // Equity
   HudObj("EQ_LABEL", 1, X + 12, Y + 30, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "EQ_LABEL", OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, HUD_PREFIX + "EQ_LABEL", OBJPROP_FONT, "Consolas");
   ObjectSetString(0, HUD_PREFIX + "EQ_LABEL", OBJPROP_TEXT, "EQUITY");

   HudObj("EQ_VAL", 1, X + 12, Y + 42, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "EQ_VAL", OBJPROP_FONTSIZE, 14);
   ObjectSetString(0, HUD_PREFIX + "EQ_VAL", OBJPROP_FONT, "Consolas Bold");

   // Balance
   HudObj("BAL_LABEL", 1, X + 12, Y + 68, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "BAL_LABEL", OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, HUD_PREFIX + "BAL_LABEL", OBJPROP_FONT, "Consolas");
   ObjectSetString(0, HUD_PREFIX + "BAL_LABEL", OBJPROP_TEXT, "BALANCE");

   HudObj("BAL_VAL", 1, X + 12, Y + 80, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "BAL_VAL", OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, HUD_PREFIX + "BAL_VAL", OBJPROP_FONT, "Consolas");

   // Divider
   HudObj("DIV2", 0, X + 10, Y + 96, W - 20, 1);
   ObjectSetInteger(0, HUD_PREFIX + "DIV2", OBJPROP_BGCOLOR, (color)0x50402E);

   // Signal
   HudObj("SIG_LABEL", 1, X + 12, Y + 102, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "SIG_LABEL", OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, HUD_PREFIX + "SIG_LABEL", OBJPROP_FONT, "Consolas");
   ObjectSetString(0, HUD_PREFIX + "SIG_LABEL", OBJPROP_TEXT, "SIGNAL");

   HudObj("SIG_VAL", 1, X + 12, Y + 114, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "SIG_VAL", OBJPROP_FONTSIZE, 12);
   ObjectSetString(0, HUD_PREFIX + "SIG_VAL", OBJPROP_FONT, "Consolas Bold");

   // Position status
   HudObj("POS_LABEL", 1, X + 12, Y + 134, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "POS_LABEL", OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, HUD_PREFIX + "POS_LABEL", OBJPROP_FONT, "Consolas");
   ObjectSetString(0, HUD_PREFIX + "POS_LABEL", OBJPROP_TEXT, "POSITION");

   HudObj("POS_VAL", 1, X + 12, Y + 146, 0, 0);
   ObjectSetInteger(0, HUD_PREFIX + "POS_VAL", OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, HUD_PREFIX + "POS_VAL", OBJPROP_FONT, "Consolas");
}

//+------------------------------------------------------------------+
//| Delete HUD panel                                                 |
//+------------------------------------------------------------------+
void HudDelete()
{
   for (int i = 0; i < g_hud_obj_count; i++)
      ObjectDelete(0, g_hud_names[i]);
   g_hud_obj_count = 0;
}

//+------------------------------------------------------------------+
//| Update HUD panel                                                 |
//+------------------------------------------------------------------+
void HudUpdate()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   string eqs = "$" + DoubleToString(eq, 2);
   string bals = "$" + DoubleToString(bal, 2);
   color grn = (color)0x00FF88;
   color red = (color)0xFF4444;
   color gld = (color)0xD2B89D;
   color lbl = (color)0x807060;

   const int X = 8, Y = 48, W = 220;

   // Title bar accent color by signal
   color acc = clrGray;
   string sig_text = "FLAT";
   string pos_text = "None";
   int pos_count = 0;

   // Check position
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (PositionGetTicket(i) > 0)
      {
         if ((int)PositionGetInteger(POSITION_MAGIC) == InpMagic)
         {
            pos_count++;
            if (pos_count == 1)
            {
               pos_text = (int)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "Long" : "Short";
            }
         }
      }
   }

   if (g_signal > 0)
   {
      acc = (color)0x6EE023;
      sig_text = "BUY";
   }
   else if (g_signal < 0)
   {
      acc = (color)0xE94560;
      sig_text = "SELL";
   }

   // Update accent
   ObjectSetInteger(0, HUD_PREFIX + "ACCENT", OBJPROP_BGCOLOR, acc);
   ObjectSetInteger(0, HUD_PREFIX + "SIG_DOT", OBJPROP_BGCOLOR, acc);

   // Equity
   HudText("EQ_VAL", eqs, (eq >= bal) ? grn : red);
   ObjectSetInteger(0, HUD_PREFIX + "EQ_VAL", OBJPROP_XDISTANCE, X + W - 12 - StringLen(eqs) * 8);

   // Balance
   HudText("BAL_VAL", bals, gld);
   ObjectSetInteger(0, HUD_PREFIX + "BAL_VAL", OBJPROP_XDISTANCE, X + W - 12 - StringLen(bals) * 8);

   // Signal
   HudText("SIG_VAL", sig_text, acc);
   ObjectSetInteger(0, HUD_PREFIX + "SIG_VAL", OBJPROP_XDISTANCE, X + W - 12 - StringLen(sig_text) * 7);

   // Position
   HudText("POS_VAL", pos_text, pos_count > 0 ? (color)0x6EE023 : lbl);
   ObjectSetInteger(0, HUD_PREFIX + "POS_VAL", OBJPROP_XDISTANCE, X + W - 12 - StringLen(pos_text) * 8);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Create indicator handles
   ENUM_TIMEFRAMES tf = PERIOD_CURRENT;
   if (InpSignalTF == 5) tf = PERIOD_M5;
   else if (InpSignalTF == 15) tf = PERIOD_M15;
   else if (InpSignalTF == 30) tf = PERIOD_M30;
   else if (InpSignalTF == 60) tf = PERIOD_H1;
   else if (InpSignalTF == 240) tf = PERIOD_H4;
   else if (InpSignalTF == 1440) tf = PERIOD_D1;

   g_fast_ema_h = iMA(_Symbol, tf, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_slow_ema_h = iMA(_Symbol, tf, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);

   if (g_fast_ema_h == INVALID_HANDLE || g_slow_ema_h == INVALID_HANDLE)
   {
      Print("Failed to create indicator handles");
      return INIT_FAILED;
   }

   Comment("Vilona Basic Gold v1.00 - EMA Crossover");
   g_signal = 0;
   g_prev_signal = 0;
   g_hud_created = 0;

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   HudDelete();
   if (g_fast_ema_h != INVALID_HANDLE) IndicatorRelease(g_fast_ema_h);
   if (g_slow_ema_h != INVALID_HANDLE) IndicatorRelease(g_slow_ema_h);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Create HUD on first tick
   if (g_hud_created == 0)
   {
      HudCreate();
      g_hud_created = 1;
   }

   // Check if new bar (only trade on new M15 bar open)
   static datetime last_bar = 0;
   datetime current_bar = iTime(_Symbol, PERIOD_M15, 0);
   bool new_bar = (current_bar != last_bar);
   if (new_bar)
      last_bar = current_bar;

   // Read EMA values
   double fast[2], slow[2];
   if (CopyBuffer(g_fast_ema_h, 0, 0, 2, fast) < 2) return;
   if (CopyBuffer(g_slow_ema_h, 0, 0, 2, slow) < 2) return;

   // Determine signal: EMA crossover
   // fast[1] = previous bar, fast[0] = current bar
   g_prev_signal = g_signal;
   g_signal = 0;
   if (fast[1] <= slow[1] && fast[0] > slow[0])
      g_signal = 1;  // Golden cross: fast crosses above slow
   else if (fast[1] >= slow[1] && fast[0] < slow[0])
      g_signal = -1; // Death cross: fast crosses below slow

   // Manage positions
   int pos_count = 0;
   ulong pos_ticket = 0;

   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if ((int)PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      pos_count++;
      pos_ticket = ticket;
   }

   // Long-only strategy
   // Close on death cross signal
   if (g_signal == -1 && pos_count > 0)
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if (ticket == 0) continue;
         if ((int)PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
         PositionSelectByTicket(ticket);
         if ((int)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            MqlTradeRequest req = {};
            MqlTradeResult res = {};
            req.action = TRADE_ACTION_DEAL;
            req.position = ticket;
            req.symbol = _Symbol;
            req.volume = PositionGetDouble(POSITION_VOLUME);
            req.deviation = 10;
            req.type = ORDER_TYPE_SELL;
            req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            req.comment = "VLB Close";
            if (!OrderSend(req, res))
               Print("Close failed: ", res.retcode);
         }
      }
   }

   // Open new buy on golden cross (only if no position)
   if (g_signal == 1 && pos_count == 0 && new_bar)
   {
      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_amt = bal * InpRiskPct / 100.0;
      double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

      if (tick_value > 0 && tick_size > 0)
      {
         double risk_per_lot = InpStopLossPts * _Point * (tick_value / tick_size);
         double lot = risk_amt / risk_per_lot;
         double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
         double lot_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         double lot_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
         lot = MathFloor(lot / lot_step) * lot_step;
         if (lot < lot_min) lot = lot_min;
         if (lot > lot_max) lot = lot_max;

         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl = ask - InpStopLossPts * _Point;
         double tp = ask + InpTakeProfitPts * _Point;

         MqlTradeRequest req = {};
         MqlTradeResult res = {};
         req.action = TRADE_ACTION_DEAL;
         req.symbol = _Symbol;
         req.volume = lot;
         req.deviation = 10;
         req.type = ORDER_TYPE_BUY;
         req.price = ask;
         req.sl = sl;
         req.tp = tp;
         req.magic = InpMagic;
         req.comment = "VLB EMA Cross";

         if (!OrderSend(req, res))
            Print("Open failed: ", res.retcode);
         else
            Print("Buy opened: Lot=", lot, " Price=", ask, " SL=", sl, " TP=", tp);
      }
   }

   // Update HUD
   HudUpdate();
}
//+------------------------------------------------------------------+