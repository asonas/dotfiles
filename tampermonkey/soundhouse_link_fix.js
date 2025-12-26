// ==UserScript==
// @name         SoundHouse Link Fix
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  SoundHouseの検索結果で商品リンクを新規タブで開けるようにする
// @author       You
// @match        https://www.soundhouse.co.jp/search/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function() {
    'use strict';

    // ページ読み込み完了後に実行
    function fixLinks() {
        // 商品リンクを全て取得（画像リンクと商品名リンク）
        const links = document.querySelectorAll('a[onClick*="ukClickLogSender"]');

        links.forEach(link => {
            // onClickイベントを完全に削除
            link.removeAttribute('onClick');
        });
    }

    // DOMContentLoadedイベント後に実行
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', fixLinks);
    } else {
        fixLinks();
    }

    // 動的に追加される要素に対応するため、MutationObserverを使用
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.addedNodes.length) {
                fixLinks();
            }
        });
    });

    // body要素を監視
    if (document.body) {
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }
})();

