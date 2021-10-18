// ==UserScript==
// @name         ToDo to Things from GHE Issues
// @namespace   https://ason.as/
// @version      1.0.0
// @description  todo to thingsapp
// @author       asonas
// @match        https://ghe.ckpd.co/*
// @grant GM_setValue
// @grant GM_getValue
// ==/UserScript==

(function() {
    'use strict';
    var currentUrl = encodeURI(location.href);
    var title = document.querySelector('.js-issue-title').innerHTML.trim();
    var thingsSchemaUri = 'things:///add?title='+encodeURI(title)+'&notes='+currentUrl+'&when=today'

    var style = 'background-color: #2174E5; background-image: linear-gradient(-180deg, #2174E5, #2274E5 90%); color: #fff; margin-right: 4px;'
    var html = '<a style="'+style+'" href="'+thingsSchemaUri+'" class="btn btn-sm" aria-expanded="false" aria-label="Add Thingsapp">Add to Things</a>'

    var ele = document.querySelector('.gh-header-actions');
    ele.insertAdjacentHTML('afterbegin', html)
})();
