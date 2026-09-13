// GCopyStorageBridge - injected into the generated love.js runtime by
// tools/inject_bridge.js at build time. This code runs INSIDE the love.js
// module closure (the only place FS and Module are in scope), right before
// the runtime's own IDBFS mount/populate statement.
//
// Why: this love.js runtime has no Lua->JS interop module, so the game's
// love.filesystem writes go to an IDBFS-backed MEMFS save dir that is only
// flushed to IndexedDB asynchronously on beforeunload - a killed tab can
// lose the last session's saves. This bridge mirrors every business.dat
// write into localStorage synchronously, and seeds localStorage values back
// into the filesystem right after the boot-time IDBFS populate completes.
;(function () {
    var FILES = { "business.dat": true };
    var PREFIX = "g-copy_";
    // Candidate save locations: the LOVE save dir is the IDBFS mount plus
    // the conf.lua t.identity. Seed both; writes are matched by basename.
    var SEED_DIRS = ["/home/web_user/love/g-copy", "/home/web_user/love"];

    function basename(path) { return path.split("/").pop(); }

    // love.filesystem.write enters the runtime through the POSIX layer
    // (_fd_write -> FS.write on a stream), never through the FS.writeFile
    // convenience method. Intercept FS.close instead: at close time the
    // MEMFS node holds the complete file regardless of write chunking.
    // Storage.save writes business.tmp and then atomically renames it onto
    // business.dat via os.rename, so FS.rename is intercepted as well; the
    // tmp close alone never matches FILES and the rename is the real save.
    var mirroring = false;
    function mirror(path, name) {
        if (mirroring) return;
        mirroring = true;
        try {
            var data = FS.readFile(path);
            localStorage.setItem(PREFIX + name, new TextDecoder().decode(data));
        } catch (e) {
            // Mirror failed (quota/blocked): drop any stale value so the
            // next boot seeds from the newer IDBFS save instead of
            // rolling back to the stale one.
            try { localStorage.removeItem(PREFIX + name); } catch (e2) {}
        }
        finally { mirroring = false; }
    }

    var origClose = FS.close;
    FS.close = function (stream) {
        var result = origClose.call(FS, stream);
        var name;
        try { name = basename(stream.path); } catch (e) { return result; }
        if (FILES[name]) mirror(stream.path, name);
        return result;
    };

    var origRename = FS.rename;
    FS.rename = function (oldPath, newPath) {
        var result = origRename.call(FS, oldPath, newPath);
        var name;
        try { name = basename(newPath); } catch (e) { return result; }
        if (FILES[name]) mirror(newPath, name);
        return result;
    };

    function seedFromLocalStorage() {
        for (var name in FILES) {
            var value;
            try { value = localStorage.getItem(PREFIX + name); } catch (e) { value = null; }
            if (value === null) continue;
            for (var i = 0; i < SEED_DIRS.length; i++) {
                try {
                    FS.mkdirTree(SEED_DIRS[i]);
                    FS.writeFile(SEED_DIRS[i] + "/" + name, value);
                } catch (e) {}
            }
        }
    }

    // The runtime calls FS.syncfs(true) right after this injection point to
    // populate MEMFS from IndexedDB before the game boots. Wrap syncfs so
    // seeding happens immediately after that populate completes. The run
    // dependency delays game boot until seeding is done (and is always
    // removed, even on syncfs error, so the game can never hang here).
    Module.addRunDependency("gcopy_storage_seed");
    var origSyncfs = FS.syncfs;
    var seeded = false;
    FS.syncfs = function (populate, callback) {
        return origSyncfs.call(FS, populate, function (err) {
            if (populate && !seeded) {
                seeded = true;
                if (!err) {
                    try { seedFromLocalStorage(); } catch (e) {}
                }
                Module.removeRunDependency("gcopy_storage_seed");
            }
            if (callback) callback(err);
        });
    };
})();
