// ==UserScript==
// @name          Create story to PivotalTracker
// @namespace   https://ason.as/
// @version      1.0.0
// @description  Create story to Pivotal Tracker
// @author       asonas
// @match        https://ghe.ckpd.co/*
// @grant GM_setValue
// @grant GM_getValue
// @grant GM_xmlhttpRequest
// @grant GM_setClipboard
// @connect  www.pivotaltracker.com
// ==/UserScript==

(function() {
    'use strict';

    async function postData() {
        var projectID = "YOUR_PROJECT_ID";
        var endpoint = "https://www.pivotaltracker.com/services/v5/projects/" + projectID + "/stories"

        var name = "name=" + document.querySelector('.js-issue-title').innerHTML.trim();
        var description = "description=" + document.querySelector(".js-write-bucket textarea").value + "\n\n" + location.href

        GM_xmlhttpRequest ( {
            method: "POST",
            url: endpoint,
            responseType: 'json',
            data: name + "&" + description,
            headers: {
                "Content-Type": "application/x-www-form-urlencoded",
                'X-TrackerToken': 'YOUR_TOKEN',
            },
            onload: function(res) {
                var response = JSON.parse(res.responseText);
                var url = response.url;
                console.log(url)
                GM_setClipboard("Story has been created. " + url, { type: 'text', mimetype: 'text/plain'});
                var ele = document.querySelector(".js-create-story-flush")
                console.log(ele);
                console.log(ele.style);
                ele.style.opacity = 1;
            },
        });
    };

    var currentUrl = encodeURI(location.href);

    var style = 'background-color: #21567D; color: #fff;magin-right: 4px;'
    var html = '<div style="position: relative;"><a style="'+style+'" href="#" class="btn btn-sm js-create-story-btn" aria-expanded="false" aria-label="Add Thingsapp">Create Story</a>';
    html += '<span class="js-create-story-flush" style="opacity: 0; transition: all 0.2s ease-in-out; position: absolute; top: 32px; right: 5px; background-color: #D5E8C8; padding: 6px 10px; border-radius: 4px; font-size: 0.6rem; text-align: center; line-height:12px;">'
    html += '<strong style="font-size: 0.8rem">Succeed</strong><br> Copy story url.</span> </div>';

    var ele = document.querySelector('.gh-header-actions');
    ele.insertAdjacentHTML('afterbegin', html);

    document.querySelector(".js-create-story-btn").addEventListener("click", postData);
})();
