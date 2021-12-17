// ==UserScript==
// @name        Override icon
// @namespace    http://tampermonkey.net/
// @version      1.0.0
// @description  try to take over the world!
// @author       asonas
// @match        https://github.com/*
// @icon         https://www.google.com/s2/favicons?domain=sushi.money
// @grant        GM_addStyle
// @run-at   document-start
// ==/UserScript==

GM_addStyle ( `
button[data-reaction-label="-1"], button[data-reaction-label="Confused"] {
    pointer-events: none;
    filter: contrast(0);
}
`)
