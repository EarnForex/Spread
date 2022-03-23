//+------------------------------------------------------------------+
//|                                                       Spread.mq4 |
//|                             Copyright © 2009-2022, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2022, www.EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Spread/"
#property version   "1.08"
#property strict

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
    ObjectCreate("Spread", OBJ_LABEL, 0, 0, 0);
    ObjectSet("Spread", OBJPROP_CORNER, corner);
    ObjectSet("Spread", OBJPROP_XDISTANCE, spread_distance_x);
    ObjectSet("Spread", OBJPROP_YDISTANCE, spread_distance_y);
    ObjectSet("Spread", OBJPROP_BACK, DrawTextAsBackground);

    if (DrawLabel)
    {
        ObjectCreate("SpreadLabel", OBJ_LABEL, 0, 0, 0);
        ObjectSet("SpreadLabel", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSet("SpreadLabel", OBJPROP_COLOR, label_font_color);
        ObjectSet("SpreadLabel", OBJPROP_SELECTABLE, false);
        ObjectSet("SpreadLabel", OBJPROP_HIDDEN, false);
        ObjectSet("SpreadLabel", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSet("SpreadLabel", OBJPROP_BACK, DrawTextAsBackground);
    }

    if (UseCustomPipSize)
    {
        divider = MathPow(0.1, DecimalPlaces) / Point;
        n_digits = (int)MathAbs(MathLog10(divider));
    }

    double spread = MarketInfo(Symbol(), MODE_SPREAD);
    OutputSpread(spread);
}

void OnDeinit(const int reason)
{
    ObjectDelete("Spread");
    ObjectDelete("SpreadLabel");
}

int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[])
{
    double spread = (Ask - Bid) / Point;
    OutputSpread(spread);
    if (DrawLabel) DrawPipsDifference("SpreadLabel", Bid, Ask, label_font_color);

    if (AlertIfSpreadAbove > 0)
    {
        if (NormalizeSpread(spread) < AlertIfSpreadAbove) alert_done = false;
        else if (!alert_done)
        {
            if (AlertNative) Alert(_Symbol, " Spread = ", DoubleToString(NormalizeSpread(spread), n_digits));
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
    ObjectSetText("Spread", "Spread: " + DoubleToString(NormalizeSpread(spread), n_digits) + " points.", font_size, font_face, font_color);
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
    // Data not loaded yet.
    if (Bars <= 0) return;

    int x, y;
    long real_x;
    uint w, h;
    string pips = DoubleToString(NormalizeSpread((MathAbs(price1 - price2) / Point)), n_digits);

    ObjectSetText(label, pips, label_font_size, label_font_face, col);
    real_x = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - 2;
    // Needed only for y, x is derived from the chart width.
    ChartTimePriceToXY(0, 0, Time[0], price1, x, y);
    // Get the width of the text based on font and its size. Negative because OS-dependent, *10 because set in 1/10 of pt.
    TextSetFont(label_font_face, -label_font_size * 10);
    TextGetSize(pips, w, h);
    ObjectSet(label, OBJPROP_XDISTANCE, real_x - w);
    ObjectSet(label, OBJPROP_YDISTANCE, y);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id != CHARTEVENT_CHART_CHANGE) return;
    if (DrawLabel) DrawPipsDifference("SpreadLabel", Bid, Ask, label_font_color);
}
//+------------------------------------------------------------------+