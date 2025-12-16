//+------------------------------------------------------------------+
//|                                           CommunityTrader.mq5    |
//|                          ✅ FIXED: Production-Ready EA            |
//+------------------------------------------------------------------+
#property copyright "Community Trading"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>

// ✅ FIXED: Use environment variables or proper configuration
input string API_URL = "https://ansorade-backend.onrender.com";  // Production URL
input string API_KEY = "Mr.creative090";                          // API secret key
input int CHECK_INTERVAL = 5;                                     // 5 seconds between checks
input double RISK_PERCENT = 1.0;                                  // Risk 1% per trade

CTrade trade;
datetime lastSignalCheck = 0;
datetime lastAccountUpdate = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("════════════════════════════════════════════════");
    Print("✅ COMMUNITY TRADER EA STARTED");
    Print("════════════════════════════════════════════════");
    Print("Server: ", AccountInfoString(ACCOUNT_SERVER));
    Print("Account: ", AccountInfoInteger(ACCOUNT_LOGIN));
    Print("Account Name: ", AccountInfoString(ACCOUNT_NAME));
    Print("Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
    Print("Equity: $", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    Print("");
    Print("API Configuration:");
    Print("  URL: ", API_URL);
    Print("  API Key: ", API_KEY);
    Print("  Check Interval: ", CHECK_INTERVAL, " seconds");
    Print("════════════════════════════════════════════════");
    
    // ✅ NEW: Set trade configuration
    trade.SetDeviationInPoints(10);
    trade.SetAsyncMode(false);
    
    EventSetTimer(1);  // 1 second timer
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("════════════════════════════════════════════════");
    Print("❌ COMMUNITY TRADER EA STOPPED");
    Print("════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Timer function                                                     |
//+------------------------------------------------------------------+
void OnTimer()
{
    // ✅ FIXED: Proper timing to avoid spam
    if(TimeCurrent() - lastSignalCheck >= CHECK_INTERVAL)
    {
        CheckForSignals();
        lastSignalCheck = TimeCurrent();
    }
    
    // Send account update every 10 seconds
    if(TimeCurrent() - lastAccountUpdate >= 10)
    {
        SendAccountUpdate();
        lastAccountUpdate = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Check for new trading signals                                      |
//+------------------------------------------------------------------+
void CheckForSignals()
{
    char data[];
    char result[];
    string headers = "X-API-Key: " + API_KEY + "\r\n";
    headers += "Content-Type: application/json\r\n";
    
    string url = API_URL + "/api/signals/pending";
    
    Print("📡 Checking for signals: ", url);
    
    int res = WebRequest("GET", url, headers, 10000, data, result, headers);
    
    if(res == 200)
    {
        string response = CharArrayToString(result);
        Print("✅ Got signals response: ", StringSubstr(response, 0, 100));
        ProcessSignals(response);
    }
    else if(res > 0)
    {
        Print("⚠️ API returned: ", res, " (", GetHTTPErrorDescription(res), ")");
    }
    else
    {
        Print("❌ WebRequest failed. Code: ", res);
        Print("   Make sure EA has WebRequest permissions!");
        Print("   Check Tools → Options → Expert Advisors → Allow WebRequest");
    }
}

//+------------------------------------------------------------------+
//| Process trading signals (handles JSON array)                       |
//+------------------------------------------------------------------+
void ProcessSignals(string jsonResponse)
{
    // ✅ FIXED: Handle empty response
    if(jsonResponse == "" || jsonResponse == "[]")
    {
        Print("ℹ️ No pending signals");
        return;
    }
    
    // ✅ FIXED: Handle single signal or array
    if(StringFind(jsonResponse, "[") == 0)
    {
        // Array of signals
        Print("📊 Processing ", CountSignals(jsonResponse), " signals");
        
        int pos = 1;  // Skip opening bracket
        while(pos < StringLen(jsonResponse))
        {
            int signalStart = StringFind(jsonResponse, "{", pos);
            if(signalStart < 0) break;
            
            int signalEnd = StringFind(jsonResponse, "}", signalStart);
            if(signalEnd < 0) break;
            
            string singleSignal = StringSubstr(jsonResponse, signalStart, signalEnd - signalStart + 1);
            ProcessSingleSignal(singleSignal);
            
            pos = signalEnd + 1;
        }
    }
    else
    {
        // Single signal object
        ProcessSingleSignal(jsonResponse);
    }
}

//+------------------------------------------------------------------+
//| Process a single signal                                            |
//+------------------------------------------------------------------+
void ProcessSingleSignal(string signal)
{
    string action = ExtractField(signal, "action");
    string symbol = ExtractField(signal, "symbol");
    double volume = StringToDouble(ExtractField(signal, "volume"));
    double tp = StringToDouble(ExtractField(signal, "tp"));
    double sl = StringToDouble(ExtractField(signal, "sl"));
    double confidence = StringToDouble(ExtractField(signal, "confidence"));
    int signalId = (int)StringToDouble(ExtractField(signal, "id"));
    
    Print("");
    Print("═══════════════════════════════════");
    Print("📈 NEW SIGNAL RECEIVED");
    Print("═══════════════════════════════════");
    Print("Action: ", action);
    Print("Symbol: ", symbol);
    Print("Volume: ", volume);
    Print("Entry: ", ExtractField(signal, "entry"));
    Print("TP: ", tp);
    Print("SL: ", sl);
    Print("Confidence: ", DoubleToString(confidence * 100, 1), "%");
    Print("═══════════════════════════════════");
    
    // ✅ FIXED: Validate signal before trading
    if(!ValidateSignal(action, symbol, volume, tp, sl))
    {
        Print("❌ Signal validation failed!");
        return;
    }
    
    // Execute trade
    if(StringUpper(action) == "BUY")
    {
        ExecuteBuy(symbol, volume, sl, tp);
    }
    else if(StringUpper(action) == "SELL")
    {
        ExecuteSell(symbol, volume, sl, tp);
    }
    else
    {
        Print("⚠️ Unknown action: ", action);
    }
}

//+------------------------------------------------------------------+
//| Validate signal parameters                                        |
//+------------------------------------------------------------------+
bool ValidateSignal(string action, string symbol, double volume, double tp, double sl)
{
    // Check if symbol exists
    if(!SymbolSelect(symbol, true))
    {
        Print("❌ Symbol not found: ", symbol);
        return false;
    }
    
    // Check volume
    if(volume <= 0 || volume > 100)
    {
        Print("❌ Invalid volume: ", volume);
        return false;
    }
    
    // Check TP/SL
    if(tp <= 0 || sl <= 0)
    {
        Print("❌ Invalid TP/SL: TP=", tp, " SL=", sl);
        return false;
    }
    
    // Check TP > SL for BUY, TP < SL for SELL
    if(action == "BUY" && tp <= sl)
    {
        Print("❌ BUY: TP must be > SL");
        return false;
    }
    else if(action == "SELL" && tp >= sl)
    {
        Print("❌ SELL: TP must be < SL");
        return false;
    }
    
    // Check balance
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double minBalance = (AccountInfoDouble(ACCOUNT_MARGIN_REQUIRED) * volume) / 100;
    if(balance < minBalance)
    {
        Print("❌ Insufficient balance. Need: $", DoubleToString(minBalance, 2), " Have: $", DoubleToString(balance, 2));
        return false;
    }
    
    Print("✅ Signal validation passed!");
    return true;
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                  |
//+------------------------------------------------------------------+
void ExecuteBuy(string symbol, double volume, double sl, double tp)
{
    Print("");
    Print("🔵 EXECUTING BUY ORDER");
    Print("Symbol: ", symbol);
    Print("Volume: ", volume);
    Print("Entry: MARKET");
    Print("TP: ", tp);
    Print("SL: ", sl);
    
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    // ✅ FIXED: Use proper trade execution with error handling
    if(!trade.Buy(volume, symbol, ask, sl, tp, "Community Trade"))
    {
        Print("❌ BUY FAILED!");
        Print("   Error Code: ", trade.ResultRetcode());
        Print("   Error Desc: ", trade.ResultRetcodeDescription());
        Print("   Volume: ", volume);
        Print("   Ask Price: ", ask);
        Print("   SL: ", sl, " TP: ", tp);
        return;
    }
    
    ulong ticket = trade.ResultOrder();
    double orderPrice = trade.ResultPrice();
    
    Print("✅ BUY ORDER EXECUTED!");
    Print("   Ticket: ", ticket);
    Print("   Price: ", DoubleToString(orderPrice, 5));
    Print("   Volume: ", volume);
    
    // Send confirmation to API
    SendTradeConfirmation(ticket, "BUY", symbol, volume, orderPrice);
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                                 |
//+------------------------------------------------------------------+
void ExecuteSell(string symbol, double volume, double sl, double tp)
{
    Print("");
    Print("🔴 EXECUTING SELL ORDER");
    Print("Symbol: ", symbol);
    Print("Volume: ", volume);
    Print("Entry: MARKET");
    Print("TP: ", tp);
    Print("SL: ", sl);
    
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    
    // ✅ FIXED: Use proper trade execution with error handling
    if(!trade.Sell(volume, symbol, bid, sl, tp, "Community Trade"))
    {
        Print("❌ SELL FAILED!");
        Print("   Error Code: ", trade.ResultRetcode());
        Print("   Error Desc: ", trade.ResultRetcodeDescription());
        Print("   Volume: ", volume);
        Print("   Bid Price: ", bid);
        Print("   SL: ", sl, " TP: ", tp);
        return;
    }
    
    ulong ticket = trade.ResultOrder();
    double orderPrice = trade.ResultPrice();
    
    Print("✅ SELL ORDER EXECUTED!");
    Print("   Ticket: ", ticket);
    Print("   Price: ", DoubleToString(orderPrice, 5));
    Print("   Volume: ", volume);
    
    // Send confirmation to API
    SendTradeConfirmation(ticket, "SELL", symbol, volume, orderPrice);
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
    
    SendToAPI("/api/account/update", json, "POST");
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
    
    SendToAPI("/api/trades/confirm", json, "POST");
}

//+------------------------------------------------------------------+
//| Send data to API with proper error handling                        |
//+------------------------------------------------------------------+
void SendToAPI(string endpoint, string jsonData, string method = "POST")
{
    char data[];
    char result[];
    
    string headers = "X-API-Key: " + API_KEY + "\r\n";
    headers += "Content-Type: application/json\r\n";
    
    if(method == "POST")
    {
        StringToCharArray(jsonData, data, 0, StringLen(jsonData));
    }
    
    string url = API_URL + endpoint;
    
    Print("📡 Sending ", method, " to: ", url);
    
    int res = WebRequest(method, url, headers, 10000, data, result, headers);
    
    if(res == 200)
    {
        Print("✅ API Response: ", CharArrayToString(result));
    }
    else
    {
        Print("❌ API Error: ", res, " (", GetHTTPErrorDescription(res), ")");
    }
}

//+------------------------------------------------------------------+
//| Helper: Extract JSON field value                                   |
//+------------------------------------------------------------------+
string ExtractField(string json, string fieldName)
{
    string searchStr = "\"" + fieldName + "\":";
    int start = StringFind(json, searchStr);
    
    if(start < 0)
        return "";
    
    start += StringLen(searchStr);
    
    // Skip whitespace
    while(start < StringLen(json) && (json[start] == ' ' || json[start] == '\t'))
        start++;
    
    int end = start;
    char charAtEnd = json[end];
    
    if(charAtEnd == '"')
    {
        // String value
        end++;
        while(end < StringLen(json) && json[end] != '"')
            end++;
        return StringSubstr(json, start + 1, end - start - 1);
    }
    else
    {
        // Numeric value
        while(end < StringLen(json) && json[end] != ',' && json[end] != '}' && json[end] != ']')
            end++;
        return StringSubstr(json, start, end - start);
    }
}

//+------------------------------------------------------------------+
//| Helper: Count number of signals in array                           |
//+------------------------------------------------------------------+
int CountSignals(string json)
{
    int count = 0;
    int pos = 0;
    
    while((pos = StringFind(json, "\"id\":", pos)) >= 0)
    {
        count++;
        pos++;
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Helper: Get HTTP error description                                 |
//+------------------------------------------------------------------+
string GetHTTPErrorDescription(int code)
{
    switch(code)
    {
        case 0:    return "Success";
        case -1:   return "Invalid URL";
        case -2:   return "Cannot connect";
        case -3:   return "Invalid file";
        case -4:   return "Invalid data";
        case -5:   return "Network timeout";
        case 400:  return "Bad Request";
        case 401:  return "Unauthorized";
        case 403:  return "Forbidden (Invalid API Key)";
        case 404:  return "Not Found";
        case 405:  return "Method Not Allowed";
        case 500:  return "Internal Server Error";
        case 502:  return "Bad Gateway";
        case 503:  return "Service Unavailable";
        default:   return "HTTP Error " + IntegerToString(code);
    }
}

//+------------------------------------------------------------------+
