//+------------------------------------------------------------------+
//|                                                       Spread.mq5 |
//|                             Copyright © 2009-2022, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2022, www.EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Spread/"
#property version   "1.08"

#property description "Spread - displays current spread in the chart window."
#property description "Modifiable font parameters, location, and normalization."

#property indicator_chart_window
#property indicator_plots 0

input bool UseCustomPipSize = false; // UseCustomPipSize: if true, pip size will be based on DecimalPlaces input parameter.
input int DecimalPlaces = 0; // DecimalPlaces: how many decimal places in a pip?
input double AlertIfSpreadAbove = 0; // AlertIfSpreadAbove: if > 0 alert will sound when sprea above the value.
input bool AlertNative = true; // AlertNative: Alert popup inside platform.
input bool AlertSound = false; // AlertSound: Play a sound on alert.
input bool AlertEmail = false; // AlertEmail: Send an email on alert.
input bool AlertNotification = false; // AlertNotification: Send a push notification on alert.
input bool DrawLabel = false; // DrawLabel: Draw spread as a line label.

input color font_color = clrRed;
input int font_size = 14;
input string font_face = "Arial";
input ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER;
input int spread_distance_x = 10;
input int spread_distance_y = 130;
input bool DrawTextAsBackground = false; //DrawTextAsBackground: if true, the text will be drawn as background.
input color label_font_color = clrRed;
input int label_font_size = 13;
input string label_font_face = "Courier";

int n_digits = 0;
double divider = 1;
bool alert_done = false;

void OnInit()
{
    IndicatorSetString(INDICATOR_SHORTNAME, "Spread");

    ObjectCreate(0, "Spread", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "Spread", OBJPROP_CORNER, corner);
    ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER;
    if (corner == CORNER_LEFT_LOWER) anchor = ANCHOR_LEFT_LOWER;
    else if (corner == CORNER_RIGHT_LOWER) anchor = ANCHOR_RIGHT_LOWER;
    else if (corner == CORNER_RIGHT_UPPER) anchor = ANCHOR_RIGHT_UPPER;
    ObjectSetInteger(0, "Spread", OBJPROP_ANCHOR, anchor);
    ObjectSetInteger(0, "Spread", OBJPROP_XDISTANCE, spread_distance_x);
    ObjectSetInteger(0, "Spread", OBJPROP_YDISTANCE, spread_distance_y);

    if (DrawLabel)
    {
        ObjectCreate(0, "SpreadLabel", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, "SpreadLabel", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "SpreadLabel", OBJPROP_COLOR, label_font_color);
        ObjectSetInteger(0, "SpreadLabel", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, "SpreadLabel", OBJPROP_HIDDEN, false);
        ObjectSetInteger(0, "SpreadLabel", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, "SpreadLabel", OBJPROP_BACK, DrawTextAsBackground);
    }

    if (UseCustomPipSize)
    {
        divider = MathPow(0.1, DecimalPlaces) / _Point;
        n_digits = (int)MathAbs(MathLog10(divider));
    }

    double spread = (double)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
    OutputSpread(spread);
    ObjectSetString(0, "Spread", OBJPROP_FONT, font_face);
    ObjectSetInteger(0, "Spread", OBJPROP_FONTSIZE, font_size);
    ObjectSetInteger(0, "Spread", OBJPROP_COLOR, font_color);
}

void OnDeinit(const int reason)
{
    ObjectDelete(0, "Spread");
    ObjectDelete(0, "SpreadLabel");
}

int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[])
{
    double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
    OutputSpread(spread);
    if (DrawLabel) DrawPipsDifference("SpreadLabel", SymbolInfoDouble(_Symbol, SYMBOL_BID), SymbolInfoDouble(_Symbol, SYMBOL_ASK), label_font_color);

    if (AlertIfSpreadAbove > 0)
    {
        if (NormalizeSpread(spread) < AlertIfSpreadAbove) alert_done = false;
        else if (!alert_done)
        {
            if (AlertNative) Alert("Spread = ", DoubleToString(NormalizeSpread(spread), n_digits));
            if (AlertSound) PlaySound("alert.wav");
            if (AlertEmail) SendMail(_Symbol + " Spread = " + DoubleToString(NormalizeSpread(spread), n_digits), _Symbol + " Spread = " + DoubleToString(NormalizeSpread(spread), n_digits));
            if (AlertNotification) SendNotification(_Symbol + " Spread = " + DoubleToString(NormalizeSpread(spread), n_digits));
            alert_done = true;
        }
    }
    return rates_total;
}

void OutputSpread(double spread)
{
    ObjectSetString(0, "Spread", OBJPROP_TEXT, "Spread: " + DoubleToString(NormalizeSpread(spread), n_digits) + " points.");
}

double NormalizeSpread(double spread)
{
    return NormalizeDouble(spread / divider, n_digits);
}

//+------------------------------------------------------------------+
//| Draws a pips distance for SL or TP.                              |
//+------------------------------------------------------------------+
void DrawPipsDifference(string label, double price1, double price2, color col)
{
    int x, y;
    long real_x;
    uint w, h;
    string pips = DoubleToString(NormalizeSpread((MathAbs(price1 - price2) / Point())), n_digits);

    ObjectSetString(0, label, OBJPROP_TEXT, pips);
    ObjectSetInteger(0, label, OBJPROP_FONTSIZE, label_font_size);
    ObjectSetString(0, label, OBJPROP_FONT, label_font_face);
    ObjectSetInteger(0, label, OBJPROP_COLOR, col);
    datetime Time[1];
    CopyTime(Symbol(), Period(), 0, 1, Time);
    real_x = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - 2;
    // Needed only for y, x is derived from the chart width.
    ChartTimePriceToXY(0, 0, Time[0], price1, x, y);
    // Get the width of the text based on font and its size. Negative because OS-dependent, *10 because set in 1/10 of pt.
    TextSetFont(label_font_face, -label_font_size * 10);
    TextGetSize(pips, w, h);
    ObjectSetInteger(0, label, OBJPROP_XDISTANCE, real_x - w);
    ObjectSetInteger(0, label, OBJPROP_YDISTANCE, y);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id != CHARTEVENT_CHART_CHANGE) return;
    if (DrawLabel) DrawPipsDifference("SpreadLabel", SymbolInfoDouble(_Symbol, SYMBOL_BID), SymbolInfoDouble(_Symbol, SYMBOL_ASK), label_font_color);
}
//+------------------------------------------------------------------+