# Restaurant Ops Hub — Deployment Instructions for Hardened Version

**Your Complete Step-by-Step Guide to Deploy the Secure, Production-Ready App**

---

## 📋 What You Have

You now have 4 key documents + 2 SQL files. Here's what each is:

| Document | Purpose | Use When |
|----------|---------|----------|
| **CHANGELOG-ALL-FIXES.md** | Complete map of every change | Need to understand what changed & why |
| **CODE-PATCHES.md** | Copy-paste code changes for index.html | Applying security fixes to frontend |
| **schema-hardened.sql** | SQL constraints + validation | Running in Supabase after original schema |
| **rls-hardened.sql** | Enhanced RLS policies | Running in Supabase after original rls.sql |
| **This file** | Step-by-step deployment guide | Your roadmap to production |

---

## 🚀 Deployment Steps (In Order)

### PHASE 1: Prepare Your Supabase Project (Already Done?)

If you've already created a Supabase project and run the original schema.sql + rls.sql, **skip to Phase 2**.

If not, do this first:

```bash
1. Go to https://supabase.com → Create new project
2. Name: restaurant-ops-hub
3. Region: Canada-Central (if in Ontario)
4. Wait 2-3 min for init
5. Go to SQL Editor → New Query
6. Paste ORIGINAL db/schema.sql → Run
7. Go to SQL Editor → New Query
8. Paste ORIGINAL db/rls.sql → Run
```

**Verify:**
- Tables view shows ~15 tables
- Auth → Policies shows ~20+ policies

---

### PHASE 2: Apply SQL Hardening (Database Constraints + Audit Logging)

**This is the database security layer.**

#### Step 1: Run schema-hardened.sql

```bash
1. Supabase Dashboard → SQL Editor → New Query
2. Copy entire contents of schema-hardened.sql
3. Paste into editor
4. Click RUN
5. Wait for success (no errors)
```

**What this does:**
- ✓ Adds input validation (wages, amounts, hours)
- ✓ Adds rate limiting constraint (clock entries)
- ✓ Adds audit logging table + triggers
- ✓ Adds performance indexes
- ✓ Adds token encryption functions (ready for Vault)

**Verify success:**
```sql
-- In SQL Editor, run this:
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'audit_log';
-- Should return: audit_log
```

#### Step 2: Run rls-hardened.sql

```bash
1. SQL Editor → New Query
2. Copy entire rls-hardened.sql
3. Paste and RUN
4. Wait for success
```

**What this does:**
- ✓ Adds vendor role policies
- ✓ Adds audit log access policies
- ✓ Documents security architecture in schema comments
- ✓ Enhances POS token protection notes

**Verify success:**
```sql
-- In SQL Editor, run this:
SELECT policy_name FROM pg_policies 
WHERE tablename = 'audit_log';
-- Should return: 2 policies (select, insert)
```

---

### PHASE 3: Apply Frontend Hardening (Security Fixes to index.html)

**This is where you add the security code to your frontend SPA.**

#### Step 1: Open Your index.html in a Text Editor

Use VSCode, Sublime Text, or any code editor. NOT a word processor.

#### Step 2: Apply Patches in Order

Use **CODE-PATCHES.md** file to apply each patch. Go through them in this order:

1. **PATCH 1:** Add Supabase library to `<head>`
2. **PATCH 2:** Add Supabase client initialization (after `"use strict";`)
3. **PATCH 3:** Fix `num()` function (add max bounds) — CRITICAL
4. **PATCH 4:** Add error wrapper function
5. **PATCH 5:** Fix `saveDB()` for quota handling — CRITICAL
6. **PATCH 6:** Add offline sync queue
7. **PATCH 7:** Add rate limiting logic
8. **PATCH 8:** Update all `num()` calls with max bounds
9. **PATCH 9:** Update `loadDB()` function

#### Step 3: Test After Each Patch

After applying EACH patch:

```bash
1. Save index.html
2. Open app in browser (localhost or existing URL)
3. Press F12 → Console tab
4. Look for errors (should be clean, no red text)
5. Perform a basic operation:
   - If it's the Supabase patch: console should show "[INIT] Supabase client ready"
   - If it's the num() patch: try entering wage=999999999 → should reject
   - If it's the saveDB patch: add many expenses with photos → should auto-cleanup
6. If all good, move to next patch
7. If error: check CHANGELOG for that fix, debug, then retry
```

---

### PHASE 4: Set Up Environment Variables

**So your frontend can connect to Supabase.**

#### Step 1: Create .env File

In your project root (same folder as index.html):

```bash
# Create file: .env
```

```env
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...your_anon_key_here
```

**Get these values:**
- Go to Supabase Dashboard → Settings → API
- Copy "Project URL" → SUPABASE_URL
- Copy "anon public" key → SUPABASE_ANON_KEY

#### Step 2: Add .env to .gitignore

```bash
# In .gitignore file, add:
.env
.env.local
.env.*.local
```

**Why:** Prevents accidental commit of API keys to GitHub.

---

### PHASE 5: Deploy to Hosting (Cloudflare Pages)

**Make your app live on the internet.**

#### Step 1: Push to GitHub

```bash
# In your project folder:
git add .
git commit -m "Security hardening: input validation, error sanitization, offline sync"
git push origin main
```

#### Step 2: Connect Cloudflare Pages

```bash
1. Go to https://dash.cloudflare.com → Pages
2. "Create a project" → "Connect to Git"
3. Authorize GitHub → Select "restaurant-ops-hub" repo
4. Build settings:
   - Framework preset: None
   - Build command: (leave empty)
   - Build output directory: /
5. Click "Save and Deploy"
6. Wait 1-2 minutes
```

**You'll get a URL:** `https://restaurant-ops-hub.pages.dev`

#### Step 3: Set Production Environment Variables

In Cloudflare Pages:

```bash
1. Go to your Pages project → Settings
2. Environment variables
3. Add:
   - SUPABASE_URL = https://YOUR_PROJECT.supabase.co
   - SUPABASE_ANON_KEY = your_key
4. Save
```

**Redeploy** (push an empty commit or click "Redeploy"):

```bash
git commit --allow-empty -m "Trigger redeploy with env vars"
git push origin main
```

---

### PHASE 6: Comprehensive Testing

**Before telling anyone about the app, verify everything works.**

#### Test 1: Multi-Tenancy (RLS Works)

```bash
1. Create User A account, create restaurant "Pizza Palace"
2. Create User B account, create restaurant "Burger King"
3. Sign in as User A
4. Go to Staff tab → Should see ONLY Pizza Palace staff
5. Try to manually query Burger King data (browser console):
   - new URLSearchParams("?restaurantId=BURGER_KING_ID")
   - Should be blocked by RLS (error in console)
6. Sign in as User B → Should see ONLY Burger King staff
```

**Result:** ✓ Data is isolated per restaurant (RLS is working)

#### Test 2: Input Validation

```bash
1. Go to Staff tab → Add staff
2. Try wage = -100 → Rejected
3. Try wage = 999999999 → Rejected
4. Try wage = 25 → Accepted
```

**Result:** ✓ Invalid inputs rejected at frontend AND database

#### Test 3: Offline Functionality

```bash
1. Go to Staff tab, add a new staff member
2. Turn off WiFi (airplane mode)
3. Add another staff member → Should show "offline" message
4. Turn WiFi back on → "synced" message should appear
5. Check Supabase → Both staff members in database
```

**Result:** ✓ Offline changes queue and sync when online

#### Test 4: Error Messages Don't Leak Data

```bash
1. Go to Supabase → temporarily disable a permission (for testing)
2. Try to do an action that's now blocked
3. Check the toast message: should say "You don't have permission"
4. Check browser console: should NOT show table names or RLS details
```

**Result:** ✓ Safe error messages (no schema exposed)

#### Test 5: Clock Entry Rate Limiting

```bash
1. Go to Clock tab → Click "Clock In"
2. Immediately try to click "Clock In" again
3. Button should be disabled for 30 seconds
4. After 30 seconds, button re-enables
```

**Result:** ✓ Rate limiting prevents spam

#### Test 6: Payroll Math

```bash
1. Go to Staff tab → Add "John" wage $20/hr
2. Go to Schedule → Add shift for John: Mon 9am-5pm (8 hours)
3. Go to Payroll → Run payroll
4. Verify CPP/EI/tax calculations against CRA payroll calculator
5. Numbers should match (within rounding)
```

**Result:** ✓ Payroll math is accurate

---

## ✅ Final Checklist Before Go-Live

- [ ] All 9 code patches applied and tested
- [ ] schema-hardened.sql ran successfully
- [ ] rls-hardened.sql ran successfully
- [ ] Environment variables set in Cloudflare Pages
- [ ] Test 1-6 all passed (multi-tenancy, validation, offline, errors, rate limiting, payroll)
- [ ] No errors in browser console (F12)
- [ ] Supabase backups enabled (7-day retention)
- [ ] Error tracking set up (Sentry or similar - optional but recommended)
- [ ] README.md written with setup instructions
- [ ] Support email configured (info@yourapp.com)
- [ ] Privacy Policy + Terms added to app (or linked)

---

## 🚀 Go-Live (Launch!)

Once all checks pass:

```bash
1. Announce the app to first restaurants
2. Share your Cloudflare Pages URL
3. Monitor error logs for first 24 hours
4. Be available for support
5. Document common issues in README
```

---

## 🆘 Troubleshooting

### "Supabase client not defined" error

**Problem:** Supabase library didn't load

**Fix:**
1. Check PATCH 1 was applied (Supabase script tag in `<head>`)
2. F12 → Network tab → Search for "supabase-js" → should be 200 OK
3. If 404: the CDN link is broken, try a different version

### "Cannot read property 'from' of null" error

**Problem:** Supabase client not initialized

**Fix:**
1. Check PATCH 2 was applied (initSupabase function)
2. Wait a few seconds, then retry (library loads async)
3. Check console for "[INIT] Supabase client ready" message

### Data not saving to Supabase

**Problem:** Frontend or database issue

**Fix:**
1. Check environment variables are set (SUPABASE_URL, SUPABASE_ANON_KEY)
2. Go to Supabase Dashboard → Auth → verify user is logged in
3. Check browser console for error messages
4. Verify RLS policies are enabled (Auth → Policies)

### Wage validation not working

**Problem:** num() function not updated or constraint not applied

**Fix:**
1. Check PATCH 3 & PATCH 8 were applied (num() with max parameter)
2. Verify schema-hardened.sql was run (CHECK constraint on staff.wage)
3. Try entering "500" (should accept), then "500.01" (should reject)

### Offline sync not working

**Problem:** Sync queue not triggered

**Fix:**
1. Check PATCH 6 was applied (syncQueuedWrites function)
2. Turn off WiFi, add staff, turn on WiFi
3. Check console for "[SYNC]" messages
4. May need to reload page to trigger sync

---

## 📞 Support

**During Deployment:**
- Reference the CHANGELOG for why each change exists
- Reference CODE-PATCHES for exact code changes
- Reference this guide for step-by-step deployment

**After Go-Live:**
- Monitor Supabase logs and audit_log table
- Set up alerts for errors (Sentry recommended)
- Have a rollback plan (backup + restore procedures documented)

---

## 📚 Key Files

| File | Size | Purpose |
|------|------|---------|
| CHANGELOG-ALL-FIXES.md | ~50KB | Complete change documentation |
| CODE-PATCHES.md | ~30KB | Copy-paste code sections for frontend |
| schema-hardened.sql | ~10KB | Database constraints & audit logging |
| rls-hardened.sql | ~8KB | Enhanced RLS policies |
| DEPLOYMENT-INSTRUCTIONS.md | This file | Your deployment roadmap |

---

## Estimated Timeline

| Phase | Task | Time |
|-------|------|------|
| 1 | Supabase setup (or verify existing) | 30 min |
| 2 | Apply SQL hardening | 15 min |
| 3 | Apply frontend patches (9 patches × test) | 90 min |
| 4 | Environment variables | 10 min |
| 5 | Deploy to Cloudflare Pages | 20 min |
| 6 | Comprehensive testing | 40 min |
| **TOTAL** | | **3.5 hours** |

**Add 30 min buffer for debugging/troubleshooting.**

---

**You're ready to deploy! 🎉**

Follow this guide step-by-step, test after each phase, and your hardened Restaurant Ops Hub will be production-ready.

For questions, refer to the CHANGELOG or CODE-PATCHES documents.

Good luck! 🍽️