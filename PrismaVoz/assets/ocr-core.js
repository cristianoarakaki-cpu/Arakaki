/* Bounded-memory grayscale normalization, adaptive binarization and deskew. */
(function(root){'use strict';
 function normalize(data,width,height){
  const gray=new Uint8Array(width*height),hist=new Uint32Array(256);let borders=0,darkBorders=0;
  for(let i=0;i<gray.length;i++){const j=i*4,alpha=data[j+3]/255;const v=Math.round((data[j]*.299+data[j+1]*.587+data[j+2]*.114)*alpha+255*(1-alpha));gray[i]=v;hist[v]++;const x=i%width,y=Math.floor(i/width);if(x<width*.04||x>width*.96||y<height*.04||y>height*.96){borders++;if(v<100)darkBorders++}}
  const inverted=darkBorders>Math.max(1,borders)*.7;
  if(inverted){hist.fill(0);for(let i=0;i<gray.length;i++){gray[i]=255-gray[i];hist[gray[i]]++}}
  function percentile(f){const target=gray.length*f;let count=0;for(let i=0;i<256;i++){count+=hist[i];if(count>=target)return i}return 255}
  let first=0,last=255;while(first<255&&!hist[first])first++;while(last>0&&!hist[last])last--;const extent=last-first;
  const low=percentile(.005),high=percentile(.995),range=high-low;
  if(range>=12)for(let i=0;i<gray.length;i++)gray[i]=Math.max(0,Math.min(255,Math.round((gray[i]-low)*255/range)));
  return {gray,range,inverted,extent};
 }
 function rgba(gray){const out=new Uint8ClampedArray(gray.length*4);for(let i=0;i<gray.length;i++){out[i*4]=out[i*4+1]=out[i*4+2]=gray[i];out[i*4+3]=255}return out}
 function adaptive(gray,width,height,radius=15){
  const out=new Uint8Array(gray.length),columns=new Float64Array(width);
  // Sliding box mean uses O(width) auxiliary memory, not a page-size integral image.
  for(let y=0;y<=Math.min(radius,height-1);y++)for(let x=0;x<width;x++)columns[x]+=gray[y*width+x];
  for(let y=0;y<height;y++){
   if(y>0){const add=y+radius,remove=y-radius-1;if(add<height)for(let x=0;x<width;x++)columns[x]+=gray[add*width+x];if(remove>=0)for(let x=0;x<width;x++)columns[x]-=gray[remove*width+x]}
   const rows=Math.min(height-1,y+radius)-Math.max(0,y-radius)+1;let sum=0;
   for(let x=0;x<=Math.min(radius,width-1);x++)sum+=columns[x];
   for(let x=0;x<width;x++){if(x>0){if(x+radius<width)sum+=columns[x+radius];if(x-radius-1>=0)sum-=columns[x-radius-1]}const cells=(Math.min(width-1,x+radius)-Math.max(0,x-radius)+1)*rows;out[y*width+x]=gray[y*width+x]<sum/cells-8?0:255}
  }
  return out;
 }
 function skew(gray,width,height){
  const step=Math.max(1,Math.ceil(Math.max(width,height)/900)),points=[];
  for(let y=step*2;y<height-step*2;y+=step)for(let x=step*2;x<width-step*2;x+=step)if(gray[y*width+x]<140)points.push([x/step,y/step]);
  const area=width*height/(step*step),density=points.length/area;
  if(density<.003||density>.3)return 0;
  const h=Math.ceil(height/step),w=width/step;
  function score(deg){const bins=new Float64Array(h+Math.ceil(w*.1)+20),offset=Math.ceil(w*.05)+10,tan=Math.tan(deg*Math.PI/180);for(const [x,y]of points){const n=Math.round(y+(x-w/2)*tan)+offset;if(n>=0&&n<bins.length)bins[n]++}let sum=0;for(const b of bins)sum+=b*b;return sum}
  const baseline=score(0);let best=baseline,angle=0;
  for(let deg=-4;deg<=4;deg+=.5){const s=score(deg);if(s>best){best=s;angle=deg}}
  return best>baseline*1.16&&Math.abs(angle)>=.5?angle:0;
 }
 function result(text,confidence){const clean=String(text||'').trim(),letters=(clean.match(/[\p{L}\p{N}]/gu)||[]).length,bad=(clean.match(/\ufffd/g)||[]).length;return{text:clean,confidence:Math.max(0,Math.min(100,Number(confidence)||0)),letters,bad}}
 function better(a,b){if(!b.text)return a;if(!a.text)return b;if(b.confidence>=a.confidence+5&&b.letters>=a.letters*.65)return b;if(b.letters>a.letters*1.35&&b.confidence>=Math.max(40,a.confidence-5)&&b.bad<=a.bad)return b;return a}
 const api={normalize,rgba,adaptive,skew,result,better};if(typeof module==='object'&&module.exports)module.exports=api;else root.PrismaVoiceOcrCore=api;
})(typeof window!=='undefined'?window:globalThis);
