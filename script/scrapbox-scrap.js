javascript: (() => {
   const site = 'https://scrapbox.io/asonas-memo';
   const title = window.prompt('タイトル', document.title);
   if (!title) return;
   const ng = text => text.trim().replace(/[\[\]\n]/g, ' ');
   const lines = [];
   const canonical = document.querySelector('link[rel="canonical"]');
   if (canonical) {
     lines.push(`[${canonical.href}]`);
   } else {
     lines.push(`[${window.location.href}]`);
   }
   const description = document.querySelector('meta[name="description"]');
   if (description) {
     lines.push(description.content.trim());
   }
   const cover = document.querySelector('meta[property="og:image"]');
   if (cover) {
     lines.push(`[${cover.content}#.png]`);
     lines.push('');
   }
   const keywords = document.querySelector('meta[name="keywords"]');
   if (keywords) {
     keywords.content.split(',').forEach(function (k){
       lines.push('#' + k.trim());
     });
   }
   lines.push('#scrap');
   const e = t => encodeURIComponent(t);
   window.open(`${site}/${e(ng(title))}?body=${e(lines.join('\n'))}`);
 })()
