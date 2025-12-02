//+------------------------------------------------------------------+
//|                                           CommunityTrader.mq5    |
//|                                 Community Trading Platform        |
//+------------------------------------------------------------------+
#property copyright "Community Trading"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

input string API_URL = "http://localhost:8000";
input string API_KEY = "your_api_key_here";
input int CHECK_INTERVAL = 1000; // milliseconds

CTrade trade;
datetime lastCheck = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Community Trader EA Started");
    Print("Connected to: ", AccountInfoString(ACCOUNT_SERVER));
    Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
    Print("Balance: ", AccountInfoDouble(ACCOUNT_BALANCE));
    
    EventSetTimer(1); // Check every second
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("Community Trader EA Stopped");
}

//+------------------------------------------------------------------+
//| Timer function                                                     |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Check for new signals
    CheckForSignals();
    
    // Send account status update
    SendAccountUpdate();
}

//+------------------------------------------------------------------+
//| Check for new trading signals                                      |
//+------------------------------------------------------------------+
void CheckForSignals()
{
    char data[];
    char result[];
    string headers = "Content-Type: application/json\r\n";
    headers += "X-API-Key: " + API_KEY + "\r\n";
    
    string url = API_URL + "/api/signals/pending";
    
    int res = WebRequest("GET", url, headers, 5000, data, result, headers);
    
    if(res == 200)
    {
        string response = CharArrayToString(result);
        ProcessSignals(response);
    }
}

//+------------------------------------------------------------------+
//| Process trading signals                                            |
//+------------------------------------------------------------------+
void ProcessSignals(string jsonSignals)
{
    // Parse JSON and execute trades
    // This is simplified - you'd need proper JSON parsing
    
    if(StringFind(jsonSignals, "\"action\":\"BUY\"") >= 0)
    {
        string symbol = ExtractSymbol(jsonSignals);
        double volume = ExtractVolume(jsonSignals);
        double sl = ExtractSL(jsonSignals);
        double tp = ExtractTP(jsonSignals);
        
        ExecuteBuy(symbol, volume, sl, tp);
    }
    else if(StringFind(jsonSignals, "\"action\":\"SELL\"") >= 0)
    {
        string symbol = ExtractSymbol(jsonSignals);
        double volume = ExtractVolume(jsonSignals);
        double sl = ExtractSL(jsonSignals);
        double tp = ExtractTP(jsonSignals);
        
        ExecuteSell(symbol, volume, sl, tp);
    }
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                  |
//+------------------------------------------------------------------+
void ExecuteBuy(string symbol, double volume, double sl, double tp)
{
    double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(trade.Buy(volume, symbol, price, sl, tp, "Community Trade"))
    {
        Print("Buy order executed: ", symbol, " Volume: ", volume);
        SendTradeConfirmation(trade.ResultOrder(), "BUY", symbol, volume, price);
    }
    else
    {
        Print("Buy order failed: ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                                 |
//+------------------------------------------------------------------+
void ExecuteSell(string symbol, double volume, double sl, double tp)
{
    double price = SymbolInfoDouble(symbol, SYMBOL_BID);
    
    if(trade.Sell(volume, symbol, price, sl, tp, "Community Trade"))
    {
        Print("Sell order executed: ", symbol, " Volume: ", volume);
        SendTradeConfirmation(trade.ResultOrder(), "SELL", symbol, volume, price);
    }
    else
    {
        Print("Sell order failed: ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| Send account update to API                                         |
//+------------------------------------------------------------------+
void SendAccountUpdate()
{
    string json = "{";
    json += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
    json += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",";
    json += "\"margin\":" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2) + ",";
    json += "\"free_margin\":" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2) + ",";
    json += "\"profit\":" + DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT), 2);
    json += "}";
    
    SendToAPI("/api/account/update", json);
}

//+------------------------------------------------------------------+
//| Send trade confirmation to API                                     |
//+------------------------------------------------------------------+
void SendTradeConfirmation(ulong ticket, string action, string symbol, double volume, double price)
{
    string json = "{";
    json += "\"ticket\":" + IntegerToString(ticket) + ",";
    json += "\"action\":\"" + action + "\",";
    json += "\"symbol\":\"" + symbol + "\",";
    json += "\"volume\":" + DoubleToString(volume, 2) + ",";
    json += "\"price\":" + DoubleToString(price, 5);
    json += "}";
    
    SendToAPI("/api/trades/confirm", json);
}

//+------------------------------------------------------------------+
//| Send data to API                                                   |
//+------------------------------------------------------------------+
void SendToAPI(string endpoint, string jsonData)
{
    char data[];
    char result[];
    string headers = "Content-Type: application/json\r\n";
    headers += "X-API-Key: " + API_KEY + "\r\n";
    
    StringToCharArray(jsonData, data, 0, StringLen(jsonData));
    
    string url = API_URL + endpoint;
    WebRequest("POST", url, headers, 5000, data, result, headers);
}

//+------------------------------------------------------------------+
//| Helper functions to extract data from JSON                        |
//+------------------------------------------------------------------+
string ExtractSymbol(string json)
{
    // Simplified extraction - use proper JSON parser in production
    int start = StringFind(json, "\"symbol\":\"") + 10;
    int end = StringFind(json, "\"", start);
    return StringSubstr(json, start, end - start);
}

double ExtractVolume(string json)
{
    int start = StringFind(json, "\"volume\":") + 9;
    int end = StringFind(json, ",", start);
    if(end < 0) end = StringFind(json, "}", start);
    return StringToDouble(StringSubstr(json, start, end - start));
}

double ExtractSL(string json)
{
    int start = StringFind(json, "\"sl\":") + 5;
    int end = StringFind(json, ",", start);
    if(end < 0) end = StringFind(json, "}", start);
    return StringToDouble(StringSubstr(json, start, end - start));
}

double ExtractTP(string json)
{
    int start = StringFind(json, "\"tp\":") + 5;
    int end = StringFind(json, ",", start);
    if(end < 0) end = StringFind(json, "}", start);
    return StringToDouble(StringSubstr(json, start, end - start));
}
//+------------------------------------------------------------------+
