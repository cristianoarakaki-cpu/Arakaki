'use strict';
const assert=require('node:assert/strict'),core=require('../assets/scan-core.js');
const q=[{x:.2,y:.1},{x:.8,y:.1},{x:.9,y:.9},{x:.1,y:.9}],m=core.transform(q);
for(const [i,[u,v]]of [[0,[0,0]],[1,[1,0]],[2,[1,1]],[3,[0,1]]]){const p=core.map(m,u,v);assert(Math.abs(p.x-q[i].x)<1e-10&&Math.abs(p.y-q[i].y)<1e-10)}
const center=core.map(m,.5,.5);assert(Math.abs(center.x-.5)<1e-10);assert(Math.abs(center.y-.442857142857)<1e-10);
for(const bad of [[q[0],q[2],q[1],q[3]],q.map(p=>({...p,x:NaN})),[{x:0,y:0},{x:.01,y:0},{x:.01,y:.01},{x:0,y:.01}],[q[0],q[0],q[2],q[3]],q.map(p=>({...p,x:p.x+1}))])assert.throws(()=>core.validate(bad));
// Independent analytic trapezoid: source encodes the paper's horizontal/vertical coordinates as R/G.
const width=800,height=800,data=new Uint8ClampedArray(width*height*4);
for(let y=0;y<height;y++)for(let x=0;x<width;x++){const px=x/(width-1),py=y/(height-1),v=(py-.1)/(.575+.25*py),u=(px*(1-.25*v)+.125*v-.2)/.6,k=(y*width+x)*4;data[k]=Math.max(0,Math.min(255,u*255));data[k+1]=Math.max(0,Math.min(255,v*255));data[k+2]=40;data[k+3]=255}
const p=core.plan(width,height,q),out=new Uint8ClampedArray(p.width*p.height*4);for(let y=0;y<p.height;y+=37)core.sampleRows({width,height,data},p,out,y,y+37);
for(const u of [.1,.3,.5,.7,.9])for(const v of [.1,.3,.5,.7,.9]){const x=Math.floor(p.width*u),y=Math.floor(p.height*v),i=(y*p.width+x)*4;assert(Math.abs(out[i]-255*(x+.5)/p.width)<=2);assert(Math.abs(out[i+1]-255*(y+.5)/p.height)<=2);assert.equal(out[i+2],40);assert.equal(out[i+3],255)}
const bounded=core.plan(4000,4000,[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}]);assert.equal(bounded.width,2600);assert.equal(bounded.height,2600);assert.throws(()=>core.plan(10000,10000,q));
console.log('OK: homografia com referência analítica independente, cantos/centro, reamostragem bilinear, limites e rejeição de cruzamentos/áreas degeneradas.');
