//+------------------------------------------------------------------+
//|                                           CommunityTrader.mq5    |
//|              ✅ FIXED: Production-Ready EA with Full Logging     |
//+------------------------------------------------------------------+
#property copyright "Community Trading"
#property version   "2.01"
#property strict

#include <Trade\Trade.mqh>

// ✅ Configuration with ENHANCED LOGGING
input string API_URL = "https://ansorade-backend.onrender.com";
input string API_KEY = "Mr.creative090";
input int CHECK_INTERVAL = 5;
input double RISK_PERCENT = 1.0;

CTrade trade;
datetime lastSignalCheck = 0;
datetime lastAccountUpdate = 0;

// ✅ NEW: File logging for persistent record
string LOG_FILE = "Community_Trader_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";

//+------------------------------------------------------------------+
//| Log to file                                                       |
//+------------------------------------------------------------------+
void LogToFile(string message)
{
    int handle = FileOpen(LOG_FILE, FILE_READ|FILE_WRITE|FILE_TXT);
    if(handle != INVALID_HANDLE)
    {
        FileSeek(handle, 0, SEEK_END);
        FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS) + " | " + message);
        FileClose(handle);
    }
    Print(message);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    LogToFile("════════════════════════════════════════════════");
    LogToFile("✅ COMMUNITY TRADER EA STARTED (v2.01)");
    LogToFile("════════════════════════════════════════════════");
    LogToFile("Server: " + AccountInfoString(ACCOUNT_SERVER));
    LogToFile("Account: " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
    LogToFile("Account Name: " + AccountInfoString(ACCOUNT_NAME));
    LogToFile("Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
    LogToFile("Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    LogToFile("");
    LogToFile("API Configuration:");
    LogToFile("  URL: " + API_URL);
    LogToFile("  API Key: " + API_KEY);
    LogToFile("  Check Interval: " + IntegerToString(CHECK_INTERVAL) + " seconds");
    LogToFile("  Log File: " + LOG_FILE);
    LogToFile("════════════════════════════════════════════════");
    
    trade.SetDeviationInPoints(10);
    trade.SetAsyncMode(false);
    
    EventSetTimer(1);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    LogToFile("════════════════════════════════════════════════");
    LogToFile("❌ COMMUNITY TRADER EA STOPPED");
    LogToFile("════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Timer function                                                     |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(TimeCurrent() - lastSignalCheck >= CHECK_INTERVAL)
    {
        CheckForSignals();
        lastSignalCheck = TimeCurrent();
    }
    
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
    
    LogToFile("📡 [POLL] Checking for pending signals at: " + url);
    
    int res = WebRequest("GET", url, headers, 10000, data, result, headers);
    
    if(res == 200)
    {
        string response = CharArrayToString(result);
        LogToFile("✅ [POLL] Got signals response (" + IntegerToString(StringLen(response)) + " bytes)");
        
        if(response != "" && response != "[]")
        {
            LogToFile("📊 [PARSE] Processing response: " + StringSubstr(response, 0, 200));
            ProcessSignals(response);
        }
        else
        {
            LogToFile("ℹ️  [POLL] No pending signals in response");
        }
    }
    else if(res > 0)
    {
        LogToFile("⚠️  [POLL] API returned HTTP " + IntegerToString(res) + " (" + GetHTTPErrorDescription(res) + ")");
    }
    else
    {
        LogToFile("❌ [POLL] WebRequest failed. Code: " + IntegerToString(res));
        LogToFile("   Make sure 'Allow WebRequest' is enabled in EA settings!");
    }
}

//+------------------------------------------------------------------+
//| Process trading signals                                            |
//+------------------------------------------------------------------+
void ProcessSignals(string jsonResponse)
{
    if(jsonResponse == "" || jsonResponse == "[]")
    {
        return;
    }
    
    LogToFile("🔍 [PARSE] Detecting signal format...");
    
    if(StringFind(jsonResponse, "[") == 0)
    {
        int signalCount = CountSignals(jsonResponse);
        LogToFile("📊 [PARSE] Array detected with " + IntegerToString(signalCount) + " signals");
        
        int pos = 1;
        int processedCount = 0;
        
        while(pos < StringLen(jsonResponse))
        {
            int signalStart = StringFind(jsonResponse, "{", pos);
            if(signalStart < 0) break;
            
            int signalEnd = StringFind(jsonResponse, "}", signalStart);
            if(signalEnd < 0) break;
            
            string singleSignal = StringSubstr(jsonResponse, signalStart, signalEnd - signalStart + 1);
            ProcessSingleSignal(singleSignal);
            processedCount++;
            
            pos = signalEnd + 1;
        }
        
        LogToFile("✅ [PARSE] Processed " + IntegerToString(processedCount) + " signals");
    }
    else
    {
        LogToFile("📊 [PARSE] Single object detected");
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
    
    LogToFile("");
    LogToFile("═══════════════════════════════════");
    LogToFile("📈 NEW SIGNAL - VALIDATION START");
    LogToFile("═══════════════════════════════════");
    LogToFile("Signal ID: " + IntegerToString(signalId));
    LogToFile("Symbol: " + symbol);
    LogToFile("Action: " + action);
    LogToFile("Volume: " + DoubleToString(volume, 2));
    LogToFile("Entry: MARKET");
    LogToFile("TP: " + DoubleToString(tp, 5) + " | SL: " + DoubleToString(sl, 5));
    LogToFile("Confidence: " + DoubleToString(confidence * 100, 1) + "%");
    LogToFile("═══════════════════════════════════");
    
    if(!ValidateSignal(action, symbol, volume, tp, sl))
    {
        LogToFile("❌ VALIDATION FAILED - ABORTING TRADE");
        return;
    }
    
    LogToFile("✅ VALIDATION PASSED - EXECUTING TRADE");
    
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
        LogToFile("⚠️  Unknown action: " + action);
    }
}

//+------------------------------------------------------------------+
//| Validate signal parameters                                        |
//+------------------------------------------------------------------+
bool ValidateSignal(string action, string symbol, double volume, double tp, double sl)
{
    if(!SymbolSelect(symbol, true))
    {
        LogToFile("❌ [VALIDATE] Symbol not found: " + symbol);
        return false;
    }
    LogToFile("✅ [VALIDATE] Symbol exists: " + symbol);
    
    if(volume <= 0 || volume > 100)
    {
        LogToFile("❌ [VALIDATE] Invalid volume: " + DoubleToString(volume, 2));
        return false;
    }
    LogToFile("✅ [VALIDATE] Volume valid: " + DoubleToString(volume, 2));
    
    if(tp <= 0 || sl <= 0)
    {
        LogToFile("❌ [VALIDATE] Invalid TP/SL: TP=" + DoubleToString(tp, 5) + " SL=" + DoubleToString(sl, 5));
        return false;
    }
    LogToFile("✅ [VALIDATE] TP/SL valid");
    
    if(StringUpper(action) == "BUY" && tp <= sl)
    {
        LogToFile("❌ [VALIDATE] BUY: TP must be > SL");
        return false;
    }
    else if(StringUpper(action) == "SELL" && tp >= sl)
    {
        LogToFile("❌ [VALIDATE] SELL: TP must be < SL");
        return false;
    }
    LogToFile("✅ [VALIDATE] TP/SL relationship valid for " + action);
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double margin_required = SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL) * volume;
    
    if(balance < margin_required)
    {
        LogToFile("❌ [VALIDATE] Insufficient balance. Need: $" + DoubleToString(margin_required, 2) + " Have: $" + DoubleToString(balance, 2));
        return false;
    }
    LogToFile("✅ [VALIDATE] Sufficient balance: $" + DoubleToString(balance, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Execute Buy Order                                                  |
//+------------------------------------------------------------------+
void ExecuteBuy(string symbol, double volume, double sl, double tp)
{
    LogToFile("");
    LogToFile("🔵 [EXECUTE] BUY ORDER EXECUTION STARTED");
    LogToFile("   Symbol: " + symbol);
    LogToFile("   Volume: " + DoubleToString(volume, 2));
    
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    LogToFile("   Current ASK: " + DoubleToString(ask, 5));
    LogToFile("   TP: " + DoubleToString(tp, 5) + " | SL: " + DoubleToString(sl, 5));
    
    if(!trade.Buy(volume, symbol, ask, sl, tp, "CT_" + IntegerToString(rand())))
    {
        LogToFile("❌ [EXECUTE] BUY FAILED!");
        LogToFile("   Retcode: " + IntegerToString(trade.ResultRetcode()));
        LogToFile("   Description: " + trade.ResultRetcodeDescription());
        return;
    }
    
    ulong ticket = trade.ResultOrder();
    double orderPrice = trade.ResultPrice();
    
    LogToFile("✅ [EXECUTE] BUY ORDER EXECUTED SUCCESSFULLY!");
    LogToFile("   Ticket: " + IntegerToString(ticket));
    LogToFile("   Execution Price: " + DoubleToString(orderPrice, 5));
    LogToFile("   Volume: " + DoubleToString(volume, 2));
    LogToFile("");
    
    SendTradeConfirmation(ticket, "BUY", symbol, volume, orderPrice);
}

//+------------------------------------------------------------------+
//| Execute Sell Order                                                 |
//+------------------------------------------------------------------+
void ExecuteSell(string symbol, double volume, double sl, double tp)
{
    LogToFile("");
    LogToFile("🔴 [EXECUTE] SELL ORDER EXECUTION STARTED");
    LogToFile("   Symbol: " + symbol);
    LogToFile("   Volume: " + DoubleToString(volume, 2));
    
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    LogToFile("   Current BID: " + DoubleToString(bid, 5));
    LogToFile("   TP: " + DoubleToString(tp, 5) + " | SL: " + DoubleToString(sl, 5));
    
    if(!trade.Sell(volume, symbol, bid, sl, tp, "CT_" + IntegerToString(rand())))
    {
        LogToFile("❌ [EXECUTE] SELL FAILED!");
        LogToFile("   Retcode: " + IntegerToString(trade.ResultRetcode()));
        LogToFile("   Description: " + trade.ResultRetcodeDescription());
        return;
    }
    
    ulong ticket = trade.ResultOrder();
    double orderPrice = trade.ResultPrice();
    
    LogToFile("✅ [EXECUTE] SELL ORDER EXECUTED SUCCESSFULLY!");
    LogToFile("   Ticket: " + IntegerToString(ticket));
    LogToFile("   Execution Price: " + DoubleToString(orderPrice, 5));
    LogToFile("   Volume: " + DoubleToString(volume, 2));
    LogToFile("");
    
    SendTradeConfirmation(ticket, "SELL", symbol, volume, orderPrice);
}

//+------------------------------------------------------------------+
//| Send account update to API                                         |
//+------------------------------------------------------------------+
void SendAccountUpdate()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double profit = AccountInfoDouble(ACCOUNT_PROFIT);
    
    string json = "{";
    json += "\"balance\":" + DoubleToString(balance, 2) + ",";
    json += "\"equity\":" + DoubleToString(equity, 2) + ",";
    json += "\"margin\":" + DoubleToString(margin, 2) + ",";
    json += "\"free_margin\":" + DoubleToString(free_margin, 2) + ",";
    json += "\"profit\":" + DoubleToString(profit, 2);
    json += "}";
    
    LogToFile("📊 [ACCOUNT] Sending account update - Balance: $" + DoubleToString(balance, 2) + " Profit: $" + DoubleToString(profit, 2));
    
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
    
    LogToFile("📤 [CONFIRM] Sending trade confirmation - Ticket: " + IntegerToString(ticket));
    
    SendToAPI("/api/trades/confirm", json, "POST");
}

//+------------------------------------------------------------------+
//| Send data to API                                                  |
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
    
    LogToFile("📡 [API] Sending " + method + " to: " + url);
    
    int res = WebRequest(method, url, headers, 10000, data, result, headers);
    
    if(res == 200)
    {
        string response = CharArrayToString(result);
        LogToFile("✅ [API] Response: " + StringSubstr(response, 0, 100));
    }
    else if(res > 0)
    {
        LogToFile("⚠️  [API] HTTP " + IntegerToString(res) + ": " + GetHTTPErrorDescription(res));
    }
    else
    {
        LogToFile("❌ [API] WebRequest error code: " + IntegerToString(res));
    }
}

//+------------------------------------------------------------------+
//| Extract JSON field value                                           |
//+------------------------------------------------------------------+
string ExtractField(string json, string fieldName)
{
    string searchStr = "\"" + fieldName + "\":";
    int start = StringFind(json, searchStr);
    
    if(start < 0)
        return "";
    
    start += StringLen(searchStr);
    
    while(start < StringLen(json) && (json[start] == ' ' || json[start] == '\t'))
        start++;
    
    int end = start;
    char charAtEnd = json[end];
    
    if(charAtEnd == '"')
    {
        end++;
        while(end < StringLen(json) && json[end] != '"')
            end++;
        return StringSubstr(json, start + 1, end - start - 1);
    }
    else
    {
        while(end < StringLen(json) && json[end] != ',' && json[end] != '}' && json[end] != ']')
            end++;
        return StringSubstr(json, start, end - start);
    }
}

//+------------------------------------------------------------------+
//| Count signals in array                                             |
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
//| Get HTTP error description                                         |
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
