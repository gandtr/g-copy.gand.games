const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const bridge = fs.readFileSync('web_template/storage-bridge.js', 'utf8');

function boot({populateError = null, stored = 'version=2\nmoney=170\n', quota = false} = {}) {
  const files = new Map();
  const local = new Map(stored === null ? [] : [['g-copy_business.dat', stored]]);
  const dependencies = new Set();
  const FS = {
    close() {},
    rename(from, to) { files.set(to, files.get(from)); files.delete(from); },
    readFile(path) { return Buffer.from(files.get(path)); },
    writeFile(path, value) { files.set(path, value); this.close({path}); },
    mkdirTree() {},
    syncfs(populate, callback) { callback(populateError); },
  };
  const Module = {
    addRunDependency(name) { dependencies.add(name); },
    removeRunDependency(name) { dependencies.delete(name); },
  };
  vm.runInNewContext(bridge, {
    FS, Module, TextDecoder,
    localStorage: {
      getItem(key) { return local.get(key) ?? null; },
      setItem(key, value) { if (quota) throw Error('quota'); local.set(key, value); },
      removeItem(key) { local.delete(key); },
    },
  });
  FS.syncfs(true, error => assert.equal(error, null, 'bootstrap callback must be allowed to finish'));
  assert.equal(dependencies.size, 0, 'boot must release the storage dependency');
  return {FS, files, local};
}
for (const populateError of [null, Error('IndexedDB blocked')]) {
  const {files} = boot({populateError});
  assert.equal(files.get('/home/web_user/love/g-copy/business.dat'), 'version=2\nmoney=170\n');
}
const {FS, files, local} = boot();
const dir = '/home/web_user/love/g-copy/';
FS.writeFile(dir + 'business.tmp', 'version=2\nmoney=240\n');
assert.equal(local.get('g-copy_business.dat'), 'version=2\nmoney=170\n');
FS.rename(dir + 'business.tmp', dir + 'business.dat');
assert.equal(local.get('g-copy_business.dat'), 'version=2\nmoney=240\n');
assert.equal(files.has(dir + 'business.tmp'), false);
const blocked = boot({stored: null, quota: true});
blocked.FS.writeFile(dir + 'business.dat', 'version=2\nmoney=500\n');
assert.equal(blocked.local.size, 0);
console.log('PASS storage recovery, failed IndexedDB recovery, atomic rename mirroring, quota fallback');
