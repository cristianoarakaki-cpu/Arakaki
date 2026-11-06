/* Text-only preparation; no network, PDF changes or persistence. */
(function(root){'use strict';
 function pageText(items){return items.filter(x=>typeof x.str==='string').map(x=>x.str+(x.hasEOL?'\n':' ')).join('').replace(/[\t \u00a0]+/g,' ').replace(/ *\n */g,'\n').trim()}
 function chunks(text,limit=2800){if(!Number.isInteger(limit)||limit<16)throw Error('Limite de voz inválido.');const out=[];let rest=String(text).trim();while(rest.length){let end=Math.min(limit,rest.length);if(end<rest.length){const tail=rest.slice(0,end),breakAt=Math.max(tail.lastIndexOf('. '),tail.lastIndexOf('! '),tail.lastIndexOf('? '),tail.lastIndexOf('\n'));if(breakAt>end/2)end=breakAt+1;else{const space=tail.lastIndexOf(' ');if(space>end/2)end=space}const code=rest.charCodeAt(end-1);if(code>=0xd800&&code<=0xdbff)end--}const part=rest.slice(0,end).trim();if(part)out.push(part);rest=rest.slice(end).trim()}return out}
 const api={pageText,chunks};if(typeof module==='object'&&module.exports)module.exports=api;else root.PrismaSpeechCore=api;
})(typeof window!=='undefined'?window:globalThis);
