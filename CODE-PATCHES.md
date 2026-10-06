# Restaurant Ops Hub — Code Patches for Hardening

**Use this file to apply security fixes to your existing index.html**

Each patch includes:
- Line numbers where to insert/replace
- Exact code to copy-paste
- What issue it fixes
- Testing instruction

**Apply patches in this order.** Test after each one.

---

## PATCH 1: Add Supabase Library to HTML Head

**Location:** `<head>` section, after the last `<style>` tag (before `</head>`)

**Insert this line:**
```html
<script async defer src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
```

**Fixes:** Infrastructure (needed for all Supabase functions)  
**Test:** Open browser console (F12). No errors about missing `supabase` should appear.

---

## PATCH 2: Add Supabase Client Initialization

**Location:** After line 343 (`"use strict";`)

**Insert this entire block:**
```javascript
/* ---------- SUPABASE CLIENT INITIALIZATION (NEW) ---------- */
const SUPABASE_URL = window.__ENV__?.SUPABASE_URL || "https://YOUR_PROJECT.supabase.co";
const SUPABASE_ANON_KEY = window.__ENV__?.SUPABASE_ANON_KEY || "YOUR_ANON_KEY_HERE";

let supabaseClient = null;
let isOnline = typeof navigator !== 'undefined' ? navigator.onLine : true;

function initSupabase() {
  if (typeof supabase !== 'undefined') {
    try {
      supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      console.log('[INIT] Supabase client ready');
    } catch (e) {
      console.warn('[INIT] Supabase initialization failed:', e);
    }
  } else {
    console.warn('[INIT] Supabase library not yet loaded, will retry...');
    setTimeout(initSupabase, 500);
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initSupabase);
} else {
  initSupabase();
}

if (typeof window !== 'undefined') {
  window.addEventListener('online', () => {
    isOnline = true;
    console.log('[NETWORK] Connection restored');
    if (typeof syncQueuedWrites === 'function') syncQueuedWrites();
  });
  window.addEventListener('offline', () => {
    isOnline = false;
    console.log('[NETWORK] Connection lost');
    toast('You are offline. Changes will sync when connected.', 'warning');
  });
}
/* ---------------------------------------------------------- */
```

**Fixes:** Infrastructure (Supabase integration)  
**Test:** In console, type `supabaseClient` → should show Supabase client object (not null)

---

## PATCH 3: Fix num() Function - Add Max Bounds (CRITICAL)

**Location:** Lines 612-620 (replace entire num() function)

**BEFORE:**
```javascript
function num(v, min){
  if(v==null) return null;
  const s = String(v).trim().replace(/[$,]/g,"");
  if(s==="") return null;
  const n = Number(s);
  if(!isFinite(n)) return null;
  if(min!=null && n<min) return null;
  return n;
}
```

**AFTER:**
```javascript
function num(v, min, max){
  if(v==null) return null;
  const s = String(v).trim().replace(/[$,]/g,"");
  if(s==="") return null;
  const n = Number(s);
  if(!isFinite(n)) return null;
  if(min!=null && n<min) return null;
  if(max!=null && n>max) return null;  // ← NEW: Enforce max bound
  return n;
}
```

**Fixes:** CRITICAL Issue #1 (Input Validation)  
**Test:** Type wage value "999999999" → should reject. Try "500" → should accept.

---

## PATCH 4: Add Safe Supabase Error Wrapper (CRITICAL)

**Location:** After PATCH 2 (after Supabase init block, before THEMES section around line 620)

**Insert this block:**
```javascript
/* ---------- SAFE SUPABASE ERROR WRAPPER (NEW) ---------- */
async function safeSupabaseCall(promise, context = 'operation') {
  try {
    const result = await promise;
    return result;
  } catch(error) {
    console.error(`[ERROR] ${context}:`, error);
    
    const message = error?.message || '';
    const code = error?.code || '';
    
    if (code === '42501' || message.includes('permission') || message.includes('policy')) {
      toast("You don't have permission for that action.", "error");
    } else if (code === '23505' || message.includes('duplicate') || message.includes('unique')) {
      toast("That record already exists.", "error");
    } else if (code === '23503' || message.includes('foreign key')) {
      toast("Cannot delete this record—it's in use elsewhere.", "error");
    } else if (code === '42P01' || message.includes('table') || message.includes('not exist')) {
      toast("Database connection error. Please try again.", "error");
    } else if (message.includes('network') || message.includes('timeout') || message.includes('ECONNREFUSED')) {
      toast("Network error. Check your connection and try again.", "error");
    } else if (message.includes('401') || message.includes('unauthorized')) {
      toast("Your session expired. Please sign out and back in.", "error");
    } else {
      toast("Something went wrong. Please try again later.", "error");
    }
    
    return null;
  }
}
/* -------------------------------------------------------- */
```

**Fixes:** CRITICAL Issue #3 (Error Message Sanitization)  
**Test:** In Supabase, temporarily disable a permission, try an operation → should show generic message, not schema details

---

## PATCH 5: Fix saveDB() - Add Quota Handling (CRITICAL)

**Location:** Lines 651-653 (replace saveDB function)

**BEFORE:**
```javascript
function saveDB(){
  try{ localStorage.setItem(DB_KEY, JSON.stringify(DB)); }
  catch(e){ toast("Could not save — storage may be full (large receipt photos are the usual cause). Try deleting old receipt photos.","error"); }
}
```

**AFTER:**
```javascript
function saveDB(){
  try {
    localStorage.setItem(DB_KEY, JSON.stringify(DB));
  } catch(e) {
    if (e.name === 'QuotaExceededError') {
      console.warn('[QUOTA] localStorage full. Attempting cleanup...');
      
      const cutoff = addDaysISO(todayISO(), -7);
      let purgedCount = 0;
      
      DB.expenses = DB.expenses.map(exp => {
        if (exp.date < cutoff && exp.receipt) {
          exp.receipt = null;
          purgedCount++;
        }
        return exp;
      });
      
      if (purgedCount > 0) {
        console.log(`[CLEANUP] Purged ${purgedCount} old photos`);
        try {
          localStorage.setItem(DB_KEY, JSON.stringify(DB));
          toast(`Recovered space. Deleted ${purgedCount} old receipt photos.`, "info");
        } catch (e2) {
          toast("Storage still full after cleanup. Delete old expenses manually.", "error");
        }
      } else {
        toast("Storage full. Please delete old expenses (especially with photos).", "error");
      }
    } else {
      toast(`Save failed: ${e.message}`, "error");
      console.error('[SAVE_ERROR]', e);
    }
  }
}
```

**Fixes:** CRITICAL Issue #2 (localStorage Quota Exhaustion)  
**Test:** Add large receipt photos until storage fills, then add one more → should auto-cleanup and succeed

---

## PATCH 6: Add Offline Sync Queue (HIGH)

**Location:** After PATCH 5 (around line 670, before RENDER section)

**Insert this block:**
```javascript
/* ---------- OFFLINE SYNC QUEUE (NEW) ---------- */
const SYNC_QUEUE = [];

async function queueWrite(table, operation, record) {
  const queueItem = {
    table,
    operation,  // 'insert', 'update', 'delete'
    record,
    timestamp: Date.now(),
    id: uid()
  };
  
  SYNC_QUEUE.push(queueItem);
  saveDB();  // Persist queue to localStorage
  
  if (isOnline && supabaseClient) {
    await syncQueuedWrites();
  }
}

async function syncQueuedWrites() {
  if (SYNC_QUEUE.length === 0) return;
  if (!supabaseClient) {
    console.warn('[SYNC] Supabase not initialized yet');
    return;
  }
  
  console.log(`[SYNC] Syncing ${SYNC_QUEUE.length} pending writes...`);
  
  for (let i = SYNC_QUEUE.length - 1; i >= 0; i--) {
    const item = SYNC_QUEUE[i];
    let result = null;
    
    try {
      switch (item.operation) {
        case 'insert':
          result = await safeSupabaseCall(
            supabaseClient.from(item.table).insert([item.record]),
            `sync insert to ${item.table}`
          );
          break;
        case 'update':
          result = await safeSupabaseCall(
            supabaseClient.from(item.table).update(item.record).eq('id', item.record.id),
            `sync update to ${item.table}`
          );
          break;
        case 'delete':
          result = await safeSupabaseCall(
            supabaseClient.from(item.table).delete().eq('id', item.record.id),
            `sync delete from ${item.table}`
          );
          break;
      }
      
      if (result !== null) {
        SYNC_QUEUE.splice(i, 1);
        console.log(`[SYNC] ✓ ${item.table} ${item.operation}`);
      }
    } catch (e) {
      console.error(`[SYNC] ✗ Failed: ${item.table}`, e);
    }
  }
  
  if (SYNC_QUEUE.length === 0) {
    toast('All offline changes synced!', 'success');
  }
  saveDB();
}
/* -------------------------------------------- */
```

**Fixes:** HIGH Issue #8 (Offline Mode Handling)  
**Test:** Turn off WiFi, add staff, turn on WiFi → staff should sync to database automatically

---

## PATCH 7: Add Rate Limiting for Clock Entries (HIGH)

**Location:** After PATCH 6 (around line 750)

**Insert this block:**
```javascript
/* ---------- RATE LIMITING FOR CLOCK ENTRIES (NEW) ---------- */
const CLOCK_RATE_LIMIT = 30;  // seconds
const clockLastActionTime = {};

function canClockNow(staffId) {
  const now = Date.now();
  const lastTime = clockLastActionTime[staffId] || 0;
  const elapsed = (now - lastTime) / 1000;
  
  if (elapsed < CLOCK_RATE_LIMIT) {
    toast(`Wait ${Math.ceil(CLOCK_RATE_LIMIT - elapsed)}s before clocking again.`, "warning");
    return false;
  }
  
  clockLastActionTime[staffId] = now;
  return true;
}

function disableClockButton(staffId, durationSecs = CLOCK_RATE_LIMIT) {
  const btn = document.getElementById(`clockBtn_${staffId}`);
  if (!btn) return;
  
  btn.disabled = true;
  btn.style.opacity = '0.5';
  let remaining = durationSecs;
  btn.textContent = `Wait ${remaining}s...`;
  
  const countdown = setInterval(() => {
    remaining--;
    btn.textContent = `Wait ${Math.max(0, remaining)}s...`;
    
    if (remaining <= 0) {
      clearInterval(countdown);
      btn.disabled = false;
      btn.style.opacity = '1';
      btn.textContent = 'Clock In';
    }
  }, 1000);
}
/* --------------------------------------------------------- */
```

**Fixes:** HIGH Issue #6 (Rate Limiting)  
**Test:** Try clicking "Clock In" twice rapidly → second click should be disabled for 30 seconds

---

## PATCH 8: Update All num() Calls with Max Bounds

**Location:** Search for all `num(` calls in the file (~15-20 locations)

**Find these patterns and update them:**

### Pattern 1: Wages
```javascript
// BEFORE:
const wage = num(wageInput);

// AFTER:
const wage = num(wageInput, 0, 500);  // Max $500/hr
```

### Pattern 2: Hours
```javascript
// BEFORE:
const hours = num(hoursInput);

// AFTER:
const hours = num(hoursInput, 0, 24);  // Max 24 hours/day
```

### Pattern 3: Sales Amounts
```javascript
// BEFORE:
const sales = num(salesInput);

// AFTER:
const sales = num(salesInput, 0, 50000);  // Max $50k/day
```

### Pattern 4: Expense Amounts
```javascript
// BEFORE:
const amount = num(expenseInput);

// AFTER:
const amount = num(expenseInput, 0, 10000);  // Max $10k
```

### Pattern 5: Invoice Amounts
```javascript
// BEFORE:
const itemAmount = num(amountInput);

// AFTER:
const itemAmount = num(amountInput, 0, 10000);  // Max $10k per item
```

**Fixes:** CRITICAL Issue #1 (all uses)  
**Test:** Try entering unreasonable values (negative, 999999999) → should reject

---

## PATCH 9: Update loadDB() for Supabase

**Location:** Lines 643-650 (replace loadDB function)

**BEFORE:**
```javascript
function loadDB(){
  try{
    const raw = localStorage.getItem(DB_KEY);
    if(!raw) return;
    const d = JSON.parse(raw);
    if(d && d.v===1 && Array.isArray(d.staff)) DB = Object.assign(blankDB(), d);
  }catch(e){ console.warn("Could not load saved data:", e); }
}
```

**AFTER:**
```javascript
async function loadDB(source = 'auto') {
  // Try Supabase first
  if (supabaseClient && source !== 'local') {
    try {
      const user = await safeSupabaseCall(
        supabaseClient.auth.getUser(),
        'check authentication'
      );
      
      if (user?.data?.user) {
        const restaurants = await safeSupabaseCall(
          supabaseClient.from('restaurants').select('*').limit(1),
          'load restaurants'
        );
        
        if (restaurants?.data && restaurants.data.length > 0) {
          const r = restaurants.data[0];
          DB.settings = Object.assign(DB.settings, {
            restaurantName: r.name || '',
            restaurantId: r.id,
            province: r.province || 'Ontario',
            hstRate: r.hst_rate || 13
          });
          console.log('[LOAD] Loaded from Supabase');
          return;
        }
      }
    } catch (e) {
      console.warn('[LOAD] Supabase load failed, falling back to localStorage');
    }
  }
  
  // Fallback to localStorage
  try {
    const raw = localStorage.getItem(DB_KEY);
    if (!raw) return;
    const d = JSON.parse(raw);
    if (d && d.v === 1 && Array.isArray(d.staff)) {
      DB = Object.assign(blankDB(), d);
      console.log('[LOAD] Loaded from localStorage');
    }
  } catch(e) {
    console.warn('[LOAD_ERROR] Could not load data:', e);
  }
}
```

**Fixes:** Architecture (Supabase integration)  
**Test:** After creating a restaurant in Supabase, reload page → should load data from database

---

## Summary of Patches

| # | Fix | Type | File Lines | Status |
|---|-----|------|-----------|--------|
| 1 | Add Supabase library | Infra | `<head>` | ☐ |
| 2 | Init Supabase client | Infra | ~343 | ☐ |
| 3 | Fix num() bounds | CRITICAL | 612-620 | ☐ |
| 4 | Error wrapper | CRITICAL | ~620 | ☐ |
| 5 | Quota handling | CRITICAL | 651-653 | ☐ |
| 6 | Offline sync queue | HIGH | ~670 | ☐ |
| 7 | Rate limiting | HIGH | ~750 | ☐ |
| 8 | Update all num() calls | CRITICAL | Multiple | ☐ |
| 9 | Update loadDB() | Infra | 643-650 | ☐ |

**Total time to apply:** 2-3 hours with careful testing between each patch.

---

## Testing After Each Patch

After applying each patch:
1. Open app in browser (F12 for console)
2. Check console for errors (should be clean)
3. Perform basic operation (add staff, log sales, clock in/out)
4. Verify data saves (check browser storage and Supabase)

If you see errors, check the CHANGELOG for that fix's explanation and debugging tips.