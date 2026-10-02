// DOM-free regressions for the page shell; no WebGL/browser dependency.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const html = fs.readFileSync('web_template/index.html', 'utf8');
const script = html.match(/<script type='text\/javascript'>([\s\S]*?)<\/script>/)[1];

function setup() {
  const handlers = {};
  const elements = {};
  const document = {
    activeElement: null,
    fullscreenElement: null,
    getElementById(id) { return elements[id]; },
    querySelector() { return {clientWidth:800, clientHeight:600}; },
    addEventListener() {},
  };
  for (const id of ['canvas', 'loadingCanvas', 'statusText', 'game-error', 'fullscreen-button']) {
    elements[id] = {
      style: {}, hidden: id === 'game-error', textContent: '',
      listeners: {},
      addEventListener(event, callback) { this.listeners[event] = callback; },
      focus() { document.activeElement = this; },
    };
  }
  elements.loadingCanvas.getContext = () => new Proxy({canvas:{width:800,height:600}}, {
    get(target, key) { return key in target ? target[key] : () => {}; },
  });
  const window = {addEventListener(name, callback) { handlers[name] = callback; }};
  const context = vm.createContext({
    document, window, console:{error() {}}, requestAnimationFrame() {},
    ResizeObserver: class { observe() {} },
  });
  vm.runInContext(script, context);
  function key(key, keyCode, extras = {}) {
    const event = {key, keyCode, prevented:false, stopped:false,
      preventDefault() { this.prevented = true; },
      stopImmediatePropagation() { this.stopped = true; }, ...extras};
    handlers.keydown(event);
    return event;
  }
  return {context, elements, document, window, key};
}

{
  const {context, elements} = setup();
  context.Module.setStatus('');
  assert.equal(elements.statusText.textContent, 'ACTIVE');
  assert.equal(elements['game-error'].hidden, true);
  context.Module.printErr('IndexedDB unavailable; using localStorage');
  assert.equal(elements.statusText.textContent, 'ACTIVE', 'nonfatal logs stay nonfatal');
  context.Module.printErr('Unable to create OpenGL window');
  context.Module.setStatus('');
  context.Module.setStatus('All downloads complete.');
  assert.equal(elements.statusText.textContent, 'UNAVAILABLE', 'failure cannot revert to ACTIVE');
  assert.equal(elements['game-error'].hidden, false);
  assert.match(elements['game-error'].textContent, /WebGL/);
  assert.equal(elements.canvas.style.visibility, 'hidden');
}
for (const fail of [
  ({context}) => context.Module.onAbort(),
  ({window}) => window.onerror(new Error('test')),
  ({elements}) => elements.canvas.listeners.webglcontextlost({preventDefault() {}}),
]) {
  const shell = setup();
  fail(shell);
  shell.context.Module.setStatus('');
  assert.equal(shell.elements.statusText.textContent, 'UNAVAILABLE');
  assert.equal(shell.elements['game-error'].hidden, false);
}
{
  const {elements, document, key} = setup();
  document.activeElement = elements['fullscreen-button'];
  for (const [name, code] of [[' ',32], ['ArrowLeft',37], ['ArrowUp',38], ['ArrowRight',39], ['ArrowDown',40]]) {
    assert.equal(key(name, code).prevented, false, `${name} retains normal page behavior`);
  }
  assert.equal(key('F11',122).prevented, false, 'normal browser fullscreen remains available');
  document.activeElement = elements.canvas;
  assert.equal(key('Tab',9).prevented, true, 'Tab still navigates game controls');
  assert.equal(key('ArrowDown',40).prevented, true, 'game keys do not scroll the page');
  assert.equal(key('Escape',27).stopped, false, 'plain Escape still reaches the game');
  const escape = key('Escape',27,{shiftKey:true});
  assert.equal(escape.prevented, true);
  assert.equal(escape.stopped, true);
  assert.equal(document.activeElement, elements['fullscreen-button'], 'Shift+Escape exits the canvas');
}
assert.match(html, /aria-describedby="game-keyboard-help"/);
assert.match(html, /id="game-keyboard-help"[^>]*>[\s\S]*?Shift\+Esc/);
console.log('PASS web shell: graphics failure, abort, context loss, page keys, and keyboard exit');
