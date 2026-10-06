# Quick Database Setup

**Automated script to harden your Supabase database in 5 minutes.**

## What This Does

Runs all 4 SQL files in your Supabase database automatically:
1. ✅ `db/schema.sql` — Original schema
2. ✅ `db/rls.sql` — Original RLS policies  
3. ✅ `db/schema-hardened.sql` — Validation + audit logging
4. ✅ `db/rls-hardened.sql` — Enhanced security policies

## How to Run

### Step 1: Install Dependencies
```bash
npm install pg
```

### Step 2: Run the Setup Script
```bash
node run-sql-setup.js
```

### Step 3: Enter Your PostgreSQL Password When Prompted

The script will ask for your Supabase PostgreSQL password. To find it:

1. Go to: https://supabase.com/dashboard/org/tkohhxyhyscprqotklvc
2. Select **restaurant-ops-hub** project
3. Click **Settings** → **Database**
4. Look for "Password" in the connection string, OR
5. Click **"Reset database password"** to create a new one
6. Copy the password and paste it into the script

### Step 4: Done! 🎉

The script will run all 4 files and report success/errors.

---

## Troubleshooting

**"Connection failed" error:**
- Double-check your PostgreSQL password
- Make sure you have internet connection
- Verify the project URL is correct

**"File not found" error:**
- Make sure you're in the project root directory
- Run: `pwd` → should end in `/restaurant-ops-hub`
- Run: `ls db/*.sql` → should show all 4 files

**"Permission denied" on password:**
- Your password may contain special characters
- Wrap it in quotes: `node run-sql-setup.js`
- When prompted, paste the full password

---

## Next Steps

Once setup completes successfully:

1. ✅ Database is hardened
2. Apply 9 code patches to `index.html` (see `CODE-PATCHES.md`)
3. Push to GitHub
4. Deploy to Cloudflare Pages

See **DEPLOYMENT-INSTRUCTIONS.md** for the complete guide.
