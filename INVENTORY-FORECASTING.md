# Inventory Management & Forecasting Modules

**Status**: ✅ **COMPLETE & DEPLOYED**

---

## Overview

Two new modules have been added to Restaurant Ops Hub for managing inventory and predicting operational needs:

1. **Inventory Management** — Track stock levels, costs, and suppliers
2. **Forecasting** — Predict sales trends, staffing needs, and reorder requirements

Both modules work offline, integrate with existing sales data, and provide real-time alerts.

---

## Inventory Management Module

### What It Does

Tracks every item your restaurant buys and uses:
- Stock quantities and par levels
- Item costs and total inventory value
- Supplier information
- Reorder history

### How to Use

#### Adding Inventory Items

```
1. Open Restaurant Ops Hub
2. Go to "Inventory" tab
3. Click "+ Add item"
4. Fill in:
   - Item name (e.g., "Tomatoes")
   - Category (e.g., "Produce")
   - Unit (e.g., "lbs", "cases")
   - Cost per unit (e.g., $2.50)
   - Current quantity
   - Par level (minimum safe stock)
   - Supplier name
5. Click Save
```

#### Editing Items

```
1. Go to "Inventory" tab
2. Find the item
3. Click "Edit"
4. Change quantities (for daily updates)
5. Click Save
```

#### Understanding Par Levels

**Par Level** = minimum quantity you want to have in stock at all times

Example:
- You use 10 lbs of tomatoes per day on average
- You want 3 days of safety stock
- Set par level to 30 lbs
- System alerts you when stock drops below 30

### Key Features

| Feature | What It Shows | Why It Matters |
|---------|---------------|----------------|
| **Low Stock Alert** | Items below par level | Know when to reorder |
| **Inventory Value** | Total cost of all items in stock | Financial tracking |
| **Category Grouping** | Items organized by type | Easy to find and manage |
| **Supplier Tracking** | Who you buy from | Quick reorder reference |
| **Cost per Unit** | Price you pay suppliers | Forecast purchasing costs |

### Data Stored Per Item

```javascript
{
  id: "unique-id",
  name: "Tomatoes",
  category: "Produce",
  unit: "lbs",
  quantity: 25,        // Current stock
  cost: 2.50,          // Per unit
  parLevel: 30,        // Minimum stock
  supplier: "Produce Market",
  lastOrdered: "2026-10-06",
  notes: "Vine tomatoes preferred"
}
```

### Dashboard Stats

When you have items tracked, the Inventory tab shows:

- **Total Items** — How many different products you track
- **Low Stock** — Items below par level (need reorder)
- **Inventory Value** — Total $ in stock right now
- **Avg Unit Cost** — Average price per item

---

## Forecasting Module

### What It Does

Analyzes past 30 days of sales to predict:
- Sales trends (up or down?)
- 7-day sales forecast
- Staffing needs based on sales volume
- Which items need reordering

### How to Use

```
1. Open Restaurant Ops Hub
2. Go to "Forecasting" tab
3. See 4 automatic sections:
   - Sales Forecast (based on past 30 days)
   - Staffing Forecast (hours needed)
   - Reorder Alerts (what to buy)
   - Inventory Projections
```

**No setup needed** — it reads your sales data automatically.

### Forecast Sections

#### 1. Sales Forecast

Shows:
- **Avg Daily Sales** — Average revenue per day (last 30 days)
- **Total (30d)** — Total revenue last month
- **Trend** — Going up or down? (%)
- **Forecast (7d)** — Projected sales next week

Example:
```
Avg Daily: $1,350
Trend: +8.5% (increasing)
7-day Forecast: $9,600 (slightly higher than normal)
```

#### 2. Staffing Forecast

Calculates how many staff hours you'll need based on sales:

- **Avg Hours/Day** — Total labor hours per day historically
- **Total 30 Days** — Labor hours worked last month
- **Forecasted Hours/Day** — Predicted hours for next week
- **Staff Needed** — Full-time equivalent employees

Example:
```
Avg Hours/Day: 42.5
Forecast: 46 hours/day (sales are up)
Staff Needed: 5.75 FTE (6 full-time staff)
→ Schedule accordingly or add part-time staff
```

#### 3. Reorder Alerts

Automatic list of items that need ordering:

Shows items that are:
- Below par level, OR
- Less than 10 units in stock

For each item, shows:
- How much to order (to reach par)
- Estimated cost
- Supplier

Example:
```
🚨 Reorder Alerts

Tomatoes | Produce | Need: 18 lbs | Cost: $45
→ Supplier: Produce Market

Chicken Breast | Proteins | Need: 35 lbs | Cost: $140
→ Supplier: Sysco
```

### How Forecasting Works

**Data Source**: Past 30 days of sales from the Sales tab

**Calculation**:
1. Looks at daily sales totals
2. Calculates average daily revenue
3. Compares first 15 days vs. last 15 days
4. Calculates trend (% change)
5. Projects next 7 days
6. Predicts staffing based on hours-per-dollar-of-sales ratio

**Updates**: Automatic — runs whenever you open Forecasting tab

---

## Integration Examples

### Scenario 1: Daily Manager Routine

```
9:00 AM: Open app
9:05 AM: Check Forecasting tab
         → See "Staffing: 45 hours needed today" (+10% from trend)
         → Call second cook to come in 2 hours early
         
Afternoon: Update Inventory tab
           → Adjust tomato quantity to reflect this morning's delivery
           
4:00 PM: Check Reorder Alerts
         → See we need 40 lbs of beef (down to 20)
         → Email Sysco to place order
```

### Scenario 2: Weekly Planning

```
Monday morning: Go to Forecasting tab
                → See trend: "+6% this week expected"
                → Sales were $9,200 last week
                → Forecast: $9,750 this week
                → Schedule extra servers for weekend

Check Reorder Alerts
                → 3 items need ordering
                → Place bulk order on Monday (better pricing)
                → Expect delivery Wednesday
```

### Scenario 3: Inventory Turnover

```
You want to know: "How expensive is my inventory sitting in the walk-in?"

Go to Inventory tab → See: "Inventory Value: $4,250"

Current sales: $1,350/day
Inventory turnover: $4,250 ÷ $1,350 = 3.15 days

Translation: You have 3+ days of inventory on hand
(Industry standard: 3-5 days for most restaurants)
```

---

## Data Storage

### Inventory Data
- **Location**: localStorage on manager device
- **Persists**: Until you delete it
- **Backed up**: When you export data in Settings → Backup
- **No cloud**: All data stays on your device

### Sales Data Used for Forecasting
- **Window**: Last 30 days automatically
- **Updates**: When you add sales entries
- **Real-time**: Forecasts update instantly

---

## Features Not Yet Implemented

❌ **Automatic purchase orders** — You still place orders manually  
❌ **Supplier pricing comparison** — Compare costs between suppliers  
❌ **Historical forecasting** — Seasonal trends (summer vs. winter)  
❌ **Inventory alerts via SMS** — Get alerts on your phone  
❌ **Multi-location inventory** — Support for multiple restaurants  
❌ **Barcode scanning** — Inventory counts with device camera  

**Timeline**: These can be added based on customer demand.

---

## Common Questions

### Q: How often does forecasting update?
A: Automatic, every time you open the Forecasting tab. It reads your latest sales data from the Sales tab.

### Q: Can I change the 30-day window?
A: Currently fixed at 30 days. If you need 60-day or 14-day forecasts, let us know.

### Q: What if my sales data is incomplete?
A: Forecasting works with what you have. If you only have 5 days of sales, it forecasts based on 5 days. More data = better predictions.

### Q: Can I compare two time periods?
A: Not yet, but you can track this manually by taking screenshots of the Forecasting tab each week.

### Q: Does it account for holidays?
A: Not automatically. If next week includes Thanksgiving, adjust your forecast expectations mentally (typically +20-30% revenue).

### Q: Can I share forecasts with my accountant?
A: Yes — take a screenshot or print the Forecasting tab (Cmd+P or Ctrl+P).

---

## Technical Details

### Database Structure

```javascript
DB.inventory = [
  {
    id: "inv-001",
    name: "Tomatoes",
    category: "Produce",
    unit: "lbs",
    quantity: 25,
    cost: 2.50,
    parLevel: 30,
    supplier: "Produce Market",
    lastOrdered: "2026-10-06",
    notes: ""
  },
  // ... more items
]

DB.forecastData = []  // Reserved for future forecast history
```

### Calculations

**Inventory Value**:
```
For each item: quantity × cost
Total: sum of all items
```

**Sales Trend**:
```
First 15 days avg: sum / 15
Last 15 days avg: sum / 15
Trend %: (last - first) / first × 100
```

**Staffing Forecast**:
```
Historical rate: total_hours / total_sales
Predicted hours: forecasted_sales × historical_rate
Staff needed: predicted_hours / 8 (full-time = 8h/day)
```

**Reorder Quantity**:
```
For each item below par:
  Amount to order = par_level - current_quantity
```

---

## Implementation

### Files Changed
- `index.html` — Added 2 render functions, 2 tabs, DB schema update

### Commit
- Hash: `fa1950d`
- Date: 2026-10-06
- Changes: +172 lines (inventory + forecasting code)

### Testing

Both modules have been tested with:
- ✅ Empty inventory (no items)
- ✅ Multiple items across categories
- ✅ Low stock alerts
- ✅ Sales trend calculations
- ✅ Staffing forecasts
- ✅ localStorage persistence

---

## Next Steps

### To Use Starting Today
1. Open Inventory tab
2. Add your current items (10-15 minutes)
3. Set par levels based on daily usage
4. Open Forecasting tab
5. See automatic alerts for items that need ordering

### To Enhance Later
- [ ] Weekly forecast reports emailed to manager
- [ ] Integration with supplier ordering systems
- [ ] Historical comparison (this week vs. last week)
- [ ] Seasonal forecasting
- [ ] Mobile app for inventory counts
- [ ] Barcode scanner integration

---

## Support

**Questions about Inventory tab?**
- Check items are in correct category
- Update quantities as stock changes
- Review par levels quarterly

**Questions about Forecasting tab?**
- Forecasts are based on past 30 days only
- Add more sales data for better predictions
- Check if sales tab has entries for the dates you want

**Bugs or issues?**
- Check browser console (F12) for errors
- Try Settings → Reset data → Reload
- Contact support with screenshots

---

**Version**: 1.0  
**Released**: 2026-10-06  
**Status**: Production Ready
