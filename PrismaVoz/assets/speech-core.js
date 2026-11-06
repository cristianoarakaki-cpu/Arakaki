/* Local PDF reading order and speech preparation. Never changes the PDF. */
(function(root){'use strict';
 const letters=/[\p{L}\p{N}]/gu;
 function clean(text){return String(text).replace(/\ufb00/g,'ff').replace(/\ufb01/g,'fi').replace(/\ufb02/g,'fl').replace(/\ufb03/g,'ffi').replace(/\ufb04/g,'ffl').replace(/\u00ad\s*\n\s*/g,'').replace(/\u00ad/g,'').replace(/[\t \u00a0]+/g,' ').replace(/ *\n */g,'\n').trim()}
 function continuous(text){return clean(text).replace(/([\p{L}])-\n(?=\p{L})/gu,'$1-').replace(/([^\n])\n(?!\n|[•▪●]\s|\d+[.)]\s)/g,'$1 ').trim()}
 function legacy(items){return clean(items.filter(x=>typeof x.str==='string').map(x=>x.str+(x.hasEOL?'\n':' ')).join(''))}
 function pageText(items,options={}){
  const textItems=items.filter(x=>typeof x.str==='string'&&x.str.trim());
  if(!textItems.length)return '';
  if(textItems.some(x=>!Array.isArray(x.transform)||!Number.isFinite(x.transform[4])||!Number.isFinite(x.transform[5])||!Number.isFinite(x.width)))return continuous(legacy(items));
  // Vertical writing and rotated glyph runs retain the original PDF stream order.
  if(textItems.some(x=>x.dir==='ttb'||x.dir==='rtl'||Math.abs(x.transform[1])>Math.abs(x.transform[0])*.35))return continuous(legacy(items));
  const sorted=textItems.map(x=>({str:x.str,x:x.transform[4],y:x.transform[5],w:Math.abs(x.width),h:Math.max(1,Math.abs(x.height)||Math.hypot(x.transform[2],x.transform[3])||10)})).sort((a,b)=>b.y-a.y||a.x-b.x);
  const rows=[];
  for(const item of sorted){let row=rows.slice(-3).find(r=>Math.abs(r.y-item.y)<=Math.min(r.h,item.h)*.35);if(!row){row={y:item.y,h:item.h,items:[]};rows.push(row)}row.items.push(item);row.h=Math.max(row.h,item.h)}
  rows.sort((a,b)=>b.y-a.y);for(const row of rows)row.items.sort((a,b)=>a.x-b.x);
  const maxX=sorted.reduce((m,x)=>Math.max(m,x.x+x.w),0),minX=sorted.reduce((m,x)=>Math.min(m,x.x),Infinity),width=options.pageWidth||maxX,mid=(minX+maxX)/2;
  const gaps=[];
  for(const row of rows){for(let i=1;i<row.items.length;i++){const a=row.items[i-1],b=row.items[i],end=a.x+a.w;if(b.x-end>width*.08&&end<mid&&b.x>mid)gaps.push({left:end,right:b.x,prose:row.items.slice(0,i).map(x=>x.str).join(' ').trim().split(/\s+/).length>=5&&row.items.slice(i).map(x=>x.str).join(' ').trim().split(/\s+/).length>=5})}}
  let cut=null;
  if(gaps.length>=4&&gaps.filter(g=>g.prose).length>=Math.max(3,gaps.length*.5)){const commonLeft=gaps.reduce((m,g)=>Math.max(m,g.left),-Infinity),commonRight=gaps.reduce((m,g)=>Math.min(m,g.right),Infinity);if(commonRight-commonLeft>width*.04)cut=(commonLeft+commonRight)/2}
  function rowText(items){let out='',previous=null;for(const item of items){if(previous){const gap=item.x-(previous.x+previous.w),space=gap>Math.min(previous.h,item.h)*.12;if(space&&!/\s$/.test(out)&&!/^\s/.test(item.str))out+=' '}out+=item.str;previous=item}return clean(out)}
  const ordered=[];let left=[],right=[];
  function flush(){ordered.push(...left,...right);left=[];right=[]}
  for(const row of rows){if(cut===null){ordered.push({...row,text:rowText(row.items)});continue}const spanning=row.items.some(x=>x.x<cut&&x.x+x.w>cut);if(spanning){flush();ordered.push({...row,text:rowText(row.items)});continue}const a=row.items.filter(x=>x.x+x.w/2<cut),b=row.items.filter(x=>x.x+x.w/2>=cut);if(a.length)left.push({...row,text:rowText(a),column:0});if(b.length)right.push({...row,text:rowText(b),column:1})}flush();
  let result='',previous=null;
  for(const row of ordered){if(!row.text)continue;if(previous){const paragraph=previous.column!==row.column||previous.y-row.y>Math.max(previous.h,row.h)*1.8;result+=paragraph?'\n\n':'\n'}result+=row.text;previous=row}
  return continuous(result);
 }
 function quality(text){const s=clean(text),readable=(s.match(letters)||[]).length,bad=(s.match(/[\ufffd\u0000-\u0008\u000b\u000c\u000e-\u001f]/g)||[]).length;return{readable,bad,suspect:readable<60||bad>Math.max(1,s.length*.02)}}
 function chooseText(nativeText,ocr,force=false){const native=clean(nativeText),recognized=continuous(ocr.text||''),a=quality(native),b=quality(recognized);if(!recognized)return native;if(force)return recognized;if(!native)return recognized;if((b.bad<=a.bad&&b.readable>a.readable*1.3&&ocr.confidence>=35)||(a.bad>0&&b.bad===0&&b.readable>=a.readable*.65&&ocr.confidence>=55))return recognized;return native}
 function chunks(text,limit=700){if(!Number.isInteger(limit)||limit<16)throw Error('Limite de voz inválido.');const out=[];let rest=continuous(text);while(rest.length){let end=Math.min(limit,rest.length);if(end<rest.length){const tail=rest.slice(0,end),breakAt=Math.max(tail.lastIndexOf('. '),tail.lastIndexOf('! '),tail.lastIndexOf('? '),tail.lastIndexOf('; '),tail.lastIndexOf('\n'));if(breakAt>end*.4)end=breakAt+1;else{const space=tail.lastIndexOf(' ');if(space>end*.4)end=space}const code=rest.charCodeAt(end-1);if(code>=0xd800&&code<=0xdbff)end--}const part=rest.slice(0,end).trim();if(part)out.push(part);rest=rest.slice(end).trim()}return out}
 const api={pageText,chunks,clean,continuous,quality,chooseText};if(typeof module==='object'&&module.exports)module.exports=api;else root.PrismaSpeechCore=api;
})(typeof window!=='undefined'?window:globalThis);
