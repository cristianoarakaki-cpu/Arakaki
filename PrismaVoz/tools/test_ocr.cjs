'use strict';
const assert=require('assert/strict'),core=require('../assets/ocr-core.js');
function pixels(w,h,background=240){const a=new Uint8ClampedArray(w*h*4);for(let i=0;i<w*h;i++){a[i*4]=a[i*4+1]=a[i*4+2]=background;a[i*4+3]=255}return a}
const w=100,h=60,faint=pixels(w,h);for(let y=20;y<30;y++)for(let x=15;x<85;x++){const i=(y*w+x)*4;faint[i]=faint[i+1]=faint[i+2]=200}
const normalized=core.normalize(faint,w,h);assert(normalized.gray[25*w+40]<20);assert(normalized.gray[0]>240);assert.equal(normalized.inverted,false);
const dark=pixels(w,h,15);for(let y=20;y<30;y++)for(let x=15;x<85;x++){const i=(y*w+x)*4;dark[i]=dark[i+1]=dark[i+2]=220}assert(core.normalize(dark,w,h).inverted);
assert(core.adaptive(new Uint8Array(w*h).fill(240),w,h).every(v=>v===255));
assert.equal(core.skew(new Uint8Array(w*h).fill(255),w,h),0);
// Reference box mean checks every border pixel and a seeded irregular background.
let seed=5;const gray=new Uint8Array(w*h);for(let i=0;i<gray.length;i++){seed=(seed*1664525+1013904223)>>>0;gray[i]=seed%256}const radius=3,actual=core.adaptive(gray,w,h,radius);
for(let y=0;y<h;y++)for(let x=0;x<w;x++){let sum=0,count=0;for(let yy=Math.max(0,y-radius);yy<=Math.min(h-1,y+radius);yy++)for(let xx=Math.max(0,x-radius);xx<=Math.min(w-1,x+radius);xx++){sum+=gray[yy*w+xx];count++}assert.equal(actual[y*w+x],gray[y*w+x]<sum/count-8?0:255)}
const low=core.result('Texto ruim',20),high=core.result('Texto recuperado com mais palavras',80);assert.equal(core.better(low,high),high);assert.equal(core.better(high,core.result('X',95)),high);
const skewed=new Uint8Array(600*400).fill(255);for(let y=50;y<350;y+=35)for(let x=40;x<550;x++){const yy=Math.round(y+x*Math.tan(3*Math.PI/180));for(let d=0;d<3;d++)skewed[(yy+d)*600+x]=0}assert(Math.abs(core.skew(skewed,600,400)+3)<=.5);
console.log('OCR: contraste claro/escuro, limiar adaptativo conferido por pixel, bordas, página vazia, inclinação e escolha de candidatos: OK');
