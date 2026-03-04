// ==UserScript==
// @name         Hide Coolify Sponsorship Banner
// @namespace    http://tampermonkey.net/
// @version      1.2.0
// @description  Remove sponsorship popup banner from Coolify
// @author       asonas
// @match        *://*/*
// @grant        GM_addStyle
// @run-at       document-start
// ==/UserScript==

if (location.hostname.startsWith('coolify.')) {
    GM_addStyle(`
        span[x-show="popups.sponsorship"] {
            display: none !important;
        }
    `);
}
