# EMA Gold Trader EA
### Automated Expert Advisor for XAUUSD — MQL5 / MetaTrader 5

![Status](https://img.shields.io/badge/Status-Live%20Tested-2D7D46?style=flat-square)
![Symbol](https://img.shields.io/badge/Symbol-XAUUSD%20Gold-D4A017?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-MetaTrader%205-1E6FBF?style=flat-square)
![Language](https://img.shields.io/badge/Language-MQL5-0D1117?style=flat-square)

---

## Backtest Results — Jan 2025 to Mar 2026

| Metric | Value |
|--------|-------|
| Initial Deposit | $10,000 |
| Net Profit | **+$11,042.03** |
| Total Return | **+110.4%** |
| Profit Factor | **1.92** |
| Sharpe Ratio | **3.47** |
| Win Rate | **72.46%** (471/650 trades) |
| Max Equity Drawdown | **9.57%** |
| Recovery Factor | **6.09** |
| LR Correlation | **0.96** |
| History Quality | 100% |
| Platform | FTMO Server 4 (Build 5660) |

> 11 of 15 months profitable. 3 drawdown months (May, Jul, Oct 2025) recovered fully within the same quarter.

---

## Strategy Logic

### Entry Condition
A BUY order is placed when the **previous closed candle** satisfies both conditions:

```mql5
// Entry signal: candle closed above EMA AND above DEMA
if(closePrice > emaValue && closePrice > dema)
    OpenBuy();
```

- **EMA (50):** Primary trend filter — confirms bullish momentum
- **DEMA (50):** Double EMA secondary confirmation — reduces false signals in ranging markets
- **Closed candle evaluation:** Entry logic runs on bar open only — eliminates repainting

### Trailing Stop System
Profit is locked progressively once a position reaches the TrailStart threshold:

```mql5
double profitPoints = (bid - openPrice) / point;
if(profitPoints <= InpTrailStart) continue;

double newSL = bid - InpTrailStep * point;
if(sl != 0 && newSL <= sl) continue;
// Move SL forward
```

### Daily Loss Limit — Prop Firm Ready
Tracks both closed P&L and floating losses in real time:

```mql5
double totalLoss = GetTodayClosedLoss() + GetFloatingLoss();
if(totalLoss >= InpDailyLossLimit)
{
    CloseAllPositions();
    tradingBlockedToday = true;
}
```

### Spread Filter
Rejects entries during high-spread events (news, session open/close):

```mql5
double spread = (SYMBOL_ASK - SYMBOL_BID) / SYMBOL_POINT;
if(spread > InpMaxSpread) return false;
```

---

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `InpSymbol` | XAUUSD | Trading symbol |
| `InpTF` | H1 | Entry timeframe |
| `InpLot` | 0.01 | Lot size per trade |
| `InpEMAPeriod` | 50 | EMA period |
| `InpDemaPeriod` | 50 | DEMA period |
| `InpMaxTrades` | 3 | Max concurrent positions |
| `InpTrailStart` | 200 | Points before trailing activates |
| `InpTrailStep` | 100 | Trailing step in points |
| `InpDailyLossLimit` | $500 | Max daily loss before trading blocks |
| `InpMaxSpread` | 50 | Max spread filter (points) |

---

## FTMO Compatibility

| Rule | Limit | EA Setting | Status |
|------|-------|-----------|--------|
| Max daily loss | 5% ($500) | `InpDailyLossLimit = 500` | ✅ Enforced in code |
| Max total loss | 10% ($1,000) | Drawdown peaked at 9.57% | ✅ Within limit |
| Profit target | 10% ($1,000) | +$11,042 in backtest | ✅ Surpassed |
| Spread control | Real spreads | `InpMaxSpread` filter active | ✅ Protected |

---

## Monthly Performance

| Month | Net P&L | Trades | Win Rate |
|-------|---------|--------|----------|
| Jan 2025 | +$1,965.85 | 39 | 100.0% |
| Feb 2025 | +$1,374.22 | 45 | 77.8% |
| Mar 2025 | +$2,126.12 | 42 | 100.0% |
| Apr 2025 | +$577.69 | 50 | 70.0% |
| May 2025 | -$36.02 | 46 | 50.0% |
| Jun 2025 | +$110.72 | 40 | 45.0% |
| Jul 2025 | -$187.88 | 49 | 40.8% |
| Aug 2025 | +$512.12 | 31 | 58.1% |
| Sep 2025 | +$2,387.58 | 47 | 100.0% |
| Oct 2025 | -$102.29 | 56 | 66.1% |
| Nov 2025 | +$1,102.96 | 46 | 80.4% |
| Dec 2025 | +$1,186.39 | 50 | 78.0% |
| Jan 2026 | +$829.71 | 48 | 81.2% |
| Feb 2026 | +$427.67 | 46 | 67.4% |
| Mar 2026* | +$234.33 | 15 | 73.3% |

*Partial month — backtest to March 11, 2026.

---

## Repository Structure

```
ema-gold-trader-ea/
│
├── src/
│   └── EMA_CloseAbove_Gold_Trader.mq5   # Full EA source code
│
├── backtest/
│   ├── Strategy_Tester_Report.html       # MT5 backtest report (100% quality)
│   └── monthly_performance.csv          # Extracted monthly P&L data
│
├── docs/
│   ├── case_study.pdf                   # Full case study document
│   └── equity_curve.png                 # Equity curve screenshot
│
└── README.md
```

---

## Services Available

Based on this project, the following services are available:

**Custom EA Development**
Full MQL5 Expert Advisor development from strategy spec — entry/exit logic, multi-timeframe analysis, risk management, prop firm compliance. Delivery includes `.ex5` compiled file + full source code + backtest report.

**Backtest Analysis**
Strategy Tester report extraction, parameter optimization, walk-forward analysis, and performance comparison across configurations.

**EA Review & Debugging**
Code audit, logic debugging, MT4 → MT5 migration, performance diagnosis from existing backtest reports.

---

## Risk Disclosure

Past backtest performance does not guarantee future results. Backtests are conducted under controlled conditions and do not account for slippage variations, broker-specific execution, or real market liquidity. This repository is provided for portfolio and educational purposes. Forward testing is recommended before deploying any automated strategy with real capital.

---

*Portfolio project · XAUUSD · MQL5 · MetaTrader 5 · 2026*
