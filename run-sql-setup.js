#!/usr/bin/env node
/**
 * Restaurant Ops Hub — Automated SQL Setup Script
 *
 * Run: node run-sql-setup.js
 *
 * This script connects to your Supabase database and runs all 4 SQL files
 * in the correct order to set up the hardened production database.
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { Client } = require('pg');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(q) {
  return new Promise(resolve => rl.question(q, resolve));
}

async function main() {
  console.log('🍽️  Restaurant Ops Hub — SQL Setup\n');
  console.log('This script will run 4 SQL files to harden your Supabase database.\n');

  // Get PostgreSQL password
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('STEP 1: Get Your PostgreSQL Password\n');
  console.log('You need your Supabase PostgreSQL password.\n');
  console.log('To find it:');
  console.log('  1. Go to: https://supabase.com/dashboard/org/tkohhxyhyscprqotklvc');
  console.log('  2. Select "restaurant-ops-hub" project');
  console.log('  3. Click Settings → Database → "Connection pooling" OR "Direct connection"');
  console.log('  4. Look for the "Password" field\n');
  console.log('If you don\'t have it, you can reset it:');
  console.log('  1. Settings → Database');
  console.log('  2. Click "Reset database password"');
  console.log('  3. Copy the new password\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const password = await question('Enter your PostgreSQL password: ');

  if (!password.trim()) {
    console.error('❌ Password required. Exiting.');
    rl.close();
    process.exit(1);
  }

  // Connection config
  const config = {
    host: 'ukoopvlybwcxhmardgsc.supabase.co',
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: password.trim(),
    ssl: { rejectUnauthorized: false }
  };

  const client = new Client(config);

  try {
    console.log('\n⏳ Connecting to Supabase...');
    await client.connect();
    console.log('✅ Connected!\n');

    // Read SQL files
    const sqlFiles = [
      { name: 'schema.sql', path: './db/schema.sql', desc: 'Original Schema' },
      { name: 'rls.sql', path: './db/rls.sql', desc: 'Original RLS Policies' },
      { name: 'schema-hardened.sql', path: './db/schema-hardened.sql', desc: 'Hardened Schema (Validation + Audit)' },
      { name: 'rls-hardened.sql', path: './db/rls-hardened.sql', desc: 'Hardened RLS (Enhanced Security)' }
    ];

    let successCount = 0;

    for (const file of sqlFiles) {
      const filePath = path.join(__dirname, file.path);

      if (!fs.existsSync(filePath)) {
        console.error(`❌ ${file.name}: File not found at ${filePath}`);
        continue;
      }

      const sql = fs.readFileSync(filePath, 'utf-8');

      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`Running: ${file.desc}`);
      console.log(`File: ${file.name}\n`);

      try {
        await client.query(sql);
        console.log(`✅ SUCCESS: ${file.name} executed\n`);
        successCount++;
      } catch (err) {
        console.error(`❌ ERROR: ${file.name}`);
        console.error(`   ${err.message}\n`);
      }
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`\n✅ Complete! ${successCount}/4 SQL files executed successfully\n`);

    if (successCount === 4) {
      console.log('🎉 Your Supabase database is now hardened and production-ready!\n');
      console.log('Next steps:');
      console.log('  1. Apply 9 code patches to index.html (see CODE-PATCHES.md)');
      console.log('  2. Push to GitHub');
      console.log('  3. Deploy to Cloudflare Pages\n');
      console.log('See DEPLOYMENT-INSTRUCTIONS.md for full step-by-step guide.\n');
    } else if (successCount > 0) {
      console.log('⚠️  Some files succeeded but not all. Check errors above.\n');
    } else {
      console.log('❌ No SQL files ran successfully. Check your password and try again.\n');
    }

  } catch (err) {
    console.error('❌ Connection failed:', err.message);
    console.error('\nTroubleshooting:');
    console.error('  • Check your password is correct');
    console.error('  • Check your internet connection');
    console.error('  • Verify the project URL is correct\n');
  } finally {
    await client.end();
    rl.close();
  }
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
