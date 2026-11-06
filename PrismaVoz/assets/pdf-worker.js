'use strict';
if(!Promise.withResolvers)Promise.withResolvers=function(){let resolve,reject;const promise=new Promise((a,b)=>{resolve=a;reject=b});return{promise,resolve,reject}};
await import('./vendor/pdf.worker.mjs');
