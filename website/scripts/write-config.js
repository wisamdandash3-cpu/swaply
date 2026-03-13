#!/usr/bin/env node
/**
 * يكتب config.supabase.js من متغيرات البيئة (للاستخدام على Vercel أو أي مضيف).
 * على Vercel: اضبط SUPABASE_URL و SUPABASE_ANON_KEY في Environment Variables.
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const outPath = path.join(root, 'config.supabase.js');

const url = process.env.SUPABASE_URL || '';
const key = process.env.SUPABASE_ANON_KEY || '';

const content =
  '// Generated at build time from env (SUPABASE_URL, SUPABASE_ANON_KEY)\n' +
  (url && key
    ? 'window.SUPABASE_URL = ' + JSON.stringify(url) + ';\nwindow.SUPABASE_ANON_KEY = ' + JSON.stringify(key) + ';\n'
    : 'window.SUPABASE_URL = "";\nwindow.SUPABASE_ANON_KEY = "";\n');

fs.writeFileSync(outPath, content, 'utf8');
console.log(outPath + ' written (' + (url && key ? 'with' : 'without') + ' Supabase keys).');
