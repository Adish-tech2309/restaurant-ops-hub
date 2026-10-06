# How to Export Staff Data from Your POS

## Quick Start

1. **Export** your staff list as CSV from your POS
2. **Upload** the CSV file in Restaurant Ops Hub → Settings → POS Connection
3. **Done!** All staff data syncs automatically

---

## Popular POS Systems

### **Toast POS** 
*Used by: Enterprise restaurants, chains*

**How to export:**
1. Log in to Toast Dashboard
2. Go to **Settings** → **Staff Management**
3. Select all staff members (or filter by location)
4. Click **Export** → Choose **CSV format**
5. Download the file
6. Upload to Restaurant Ops Hub

**CSV columns Toast provides:**
- Name ✅ (required)
- Role/Position ✅ (required - maps to "role")
- Email
- Phone ✅ (maps to "phone")
- Wage/Hourly Rate ✅ (required)
- Hire Date ✅ (optional)

---

### **Square**
*Used by: Small businesses, coffee shops, retail*

**How to export:**
1. Log in to Square Dashboard
2. Go to **Employees** → **Team Members**
3. Click **⋯ (menu)** → **Export as CSV**
4. Download the file
5. Upload to Restaurant Ops Hub

**CSV columns Square provides:**
- Name ✅ (required)
- Role ✅ (required)
- Email
- Phone ✅ (maps to "phone")
- Regular Hourly Rate ✅ (required)

---

### **Cluster POS**
*Used by: Montreal-based restaurants*

**Option 1: CSV Export**
1. Log in to Cluster Dashboard
2. Go to **Reports** → **Staff**
3. Click **Export** → **CSV**
4. Download the file
5. Upload to Restaurant Ops Hub

**Option 2: Direct Integration** (Coming Soon)
1. Go to Restaurant Ops Hub → Settings → POS Connection
2. Select "Cluster POS"
3. Enter your Cluster API key
4. Click "Connect"
5. Auto-syncs automatically!

**CSV columns Cluster provides:**
- Name ✅ (required)
- Position ✅ (maps to "role")
- Phone Number ✅ (maps to "phone")
- Hourly Rate ✅ (required)
- Hire Date ✅ (optional)

---

### **Clover**
*Used by: Independent restaurants, bars*

**How to export:**
1. Log in to Clover Dashboard
2. Go to **Employees**
3. Click **Settings** (gear icon)
4. Select **Export Staff**
5. Choose **CSV format**
6. Download the file
7. Upload to Restaurant Ops Hub

**CSV columns Clover provides:**
- Name ✅ (required)
- Role ✅ (required)
- Email
- Phone ✅ (maps to "phone")
- Wage ✅ (required)

---

### **Lightspeed**
*Used by: Restaurants, hospitality*

**How to export:**
1. Log in to Lightspeed
2. Go to **Back Office** → **Employees**
3. Select employees to export
4. Click **Export** → **CSV**
5. Download the file
6. Upload to Restaurant Ops Hub

**CSV columns Lightspeed provides:**
- Name ✅ (required)
- Role ✅ (required)
- Phone ✅ (maps to "phone")
- Base Wage ✅ (required)
- Hire Date ✅ (optional)

---

### **Custom POS or Legacy System**
*Used by: Older restaurants, custom builds*

**If your POS can export CSV:**
1. Look for: **Reports** → **Staff Export** or **Employees**
2. Export as CSV or Excel
3. Make sure file has these columns:
   - `name` (required)
   - `wage` (required)
   - `role` (optional)
   - `phone` (optional)
   - `hireDate` (optional)
   - `notes` (optional)
4. Upload to Restaurant Ops Hub

**If your POS doesn't export CSV:**
Contact your POS vendor and ask for CSV export. If they don't offer it:
- Manually enter staff in Restaurant Ops Hub (takes 5 min)
- Or email us at support@restaurantopshub.com

---

## CSV Format Reference

### What Restaurant Ops Hub Expects

**Required columns (must have):**
- `name` — Employee's full name
- `wage` — Hourly wage as a number (e.g., 16.50)

**Optional columns:**
- `role` — Job title (Chef, Server, Bartender, etc.)
- `phone` — Phone number
- `hireDate` — Date hired (format: YYYY-MM-DD)
- `notes` — Any notes about the employee

### Sample CSV File

```
name,role,phone,wage,hireDate,notes
Alice Johnson,Chef,647-123-4567,24.50,2024-03-15,Lead chef - French cuisine
Bob Smith,Server,416-555-0000,16.00,2023-09-01,Senior server
Carol Davis,Host,647-987-6543,15.50,2024-06-01,Bilingual
```

---

## Uploading to Restaurant Ops Hub

### Step-by-Step

1. Open Restaurant Ops Hub on your manager's device
2. Go to **Settings** tab (bottom navigation)
3. Find "POS CONNECTION" section
4. Click **"CSV Import"** from dropdown
5. Click **"Upload staff list"** button
6. Select your CSV file from your computer
7. Click **"Upload"**
8. App will show: "✓ Synced: 6 staff" (or however many)

### What Happens Next

- ✅ All staff members appear in the Staff tab
- ✅ Hours and payroll calculations work
- ✅ Schedule shifts for these staff
- ✅ Clock in/out works

---

## Troubleshooting

### "CSV file is empty or has no data rows"
- **Problem**: File has no staff data
- **Fix**: Make sure you have at least 2 lines (header + 1 staff member)

### "CSV must have 'name' and 'wage' columns"
- **Problem**: Missing required columns
- **Fix**: Check that your CSV has these exact column headers:
  - `name`
  - `wage`
- **Note**: Column names are case-insensitive, extra columns are OK

### "wage must be a positive number"
- **Problem**: Wage column has invalid data
- **Fix**: Make sure wage column has numbers only:
  - ✅ `16.50`
  - ✅ `24`
  - ❌ `$16.50` (remove $ sign)
  - ❌ `sixteen dollars` (use numbers)

### "No valid staff records found in CSV"
- **Problem**: All rows were skipped
- **Fix**: 
  - Check that staff names are in the `name` column
  - Check that wage is in the `wage` column
  - Look at console log for clues which rows failed

### Upload works but some staff are missing
- **Problem**: Some rows had errors and were skipped
- **Fix**: Check the name and wage columns for all staff
- **Tip**: Look at browser console (F12) for error messages

---

## Updating Staff Later

### Option 1: Upload Updated CSV
- Export updated staff list from your POS
- Upload new CSV to Restaurant Ops Hub
- App will replace all staff with new data

### Option 2: Manual Edit
- Go to **Staff** tab
- Click **Edit** on any staff member
- Change details
- Click **Save**

### Option 3: Add New Staff
- Go to **Staff** tab
- Click **Add staff member**
- Fill in details
- Click **Save**

---

## Syncing with Cluster (Coming Soon)

If your restaurant uses Cluster POS, you'll be able to:

1. Go to Settings → POS Connection
2. Select "Cluster POS"
3. Enter your API key
4. Click "Connect"
5. Data auto-syncs!

**When it's ready**, we'll send you an update.

---

## Need Help?

### Common Questions

**Q: Will this delete my existing data?**  
A: No. CSV upload adds/updates staff. Your existing shifts and clock entries stay.

**Q: Can I edit staff after uploading?**  
A: Yes. Go to Staff tab, click Edit.

**Q: What if I have 100 staff members?**  
A: Upload works with any number. We've tested with 500+.

**Q: Do I need to upload every day?**  
A: No. Upload once when you start. Update only when staff changes.

**Q: What if my POS isn't listed?**  
A: Email us at support@restaurantopshub.com with your POS name.

---

## Support

- 📧 Email: support@restaurantopshub.com
- 🐛 Report a bug: Click "Help" in Settings
- 📱 Text: 647-RROPS-HUB

