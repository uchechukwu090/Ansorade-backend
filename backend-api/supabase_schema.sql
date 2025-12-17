-- MT5 Community Trading Platform - Supabase Schema
-- Run this SQL in your Supabase SQL Editor

-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
  id BIGSERIAL PRIMARY KEY,
  user_id VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  investment DECIMAL(15, 2) DEFAULT 0,
  profit_loss DECIMAL(15, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create signals table
CREATE TABLE IF NOT EXISTS public.signals (
  id BIGSERIAL PRIMARY KEY,
  symbol VARCHAR(50) NOT NULL,
  action VARCHAR(10) NOT NULL, -- BUY or SELL
  volume DECIMAL(10, 2) NOT NULL,
  entry DECIMAL(10, 5),
  sl DECIMAL(10, 5),
  tp DECIMAL(10, 5),
  confidence DECIMAL(3, 2),
  timeframe VARCHAR(10),
  limit_orders BOOLEAN DEFAULT FALSE, -- ✅ NEW: Support limit orders
  status VARCHAR(50) DEFAULT 'pending', -- pending, processing, executed, failed
  reasoning TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  executed_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create trades table
CREATE TABLE IF NOT EXISTS public.trades (
  id BIGSERIAL PRIMARY KEY,
  ticket BIGINT UNIQUE,
  signal_id BIGINT REFERENCES public.signals(id),
  symbol VARCHAR(50) NOT NULL,
  action VARCHAR(10) NOT NULL,
  volume DECIMAL(10, 2) NOT NULL,
  open_price DECIMAL(10, 5),
  close_price DECIMAL(10, 5),
  profit DECIMAL(15, 2),
  status VARCHAR(50) DEFAULT 'open', -- open, closed
  opened_at TIMESTAMP DEFAULT NOW(),
  closed_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create account_state table
CREATE TABLE IF NOT EXISTS public.account_state (
  id BIGSERIAL PRIMARY KEY,
  balance DECIMAL(15, 2) NOT NULL,
  equity DECIMAL(15, 2) NOT NULL,
  margin DECIMAL(15, 2),
  free_margin DECIMAL(15, 2),
  profit DECIMAL(15, 2),
  timestamp TIMESTAMP DEFAULT NOW()
);

-- Create indices for better query performance
CREATE INDEX IF NOT EXISTS idx_users_user_id ON public.users(user_id);
CREATE INDEX IF NOT EXISTS idx_signals_status ON public.signals(status);
CREATE INDEX IF NOT EXISTS idx_signals_created_at ON public.signals(created_at);
CREATE INDEX IF NOT EXISTS idx_trades_status ON public.trades(status);
CREATE INDEX IF NOT EXISTS idx_trades_ticket ON public.trades(ticket);
CREATE INDEX IF NOT EXISTS idx_account_state_timestamp ON public.account_state(timestamp);

-- Enable RLS (Row Level Security) - Adjust as needed for your use case
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_state ENABLE ROW LEVEL SECURITY;

-- Create policies for public read/write (adjust for your security needs)
CREATE POLICY "Allow public read on users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow public read on signals" ON public.signals FOR SELECT USING (true);
CREATE POLICY "Allow public read on trades" ON public.trades FOR SELECT USING (true);
CREATE POLICY "Allow public read on account_state" ON public.account_state FOR SELECT USING (true);
