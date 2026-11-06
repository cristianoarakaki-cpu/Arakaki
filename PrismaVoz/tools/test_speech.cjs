'use strict';
const assert=require('assert/strict');
const {pageText,chunks}=require('../assets/speech-core.js');
assert.equal(pageText([{str:'Um',hasEOL:false},{str:'texto',hasEOL:true},{str:'com\u00a0 espaço'},{notText:true}]),'Um texto\ncom espaço');
assert.deepEqual(chunks('   '),[]);
assert.throws(()=>chunks('teste',1));
for(const text of ['palavra '.repeat(2000),'a'.repeat(10000),'😀'.repeat(3000),'Primeira frase. '.repeat(500)+'Segunda!']){
 const parts=chunks(text);
 assert(parts.length>1);assert(parts.every(p=>p.length>0&&p.length<=2800));
 assert.equal(parts.join('').replace(/\s/g,''),text.replace(/\s/g,''));
 assert(parts.every(p=>!/[\ud800-\udbff]$/.test(p)&&! /^[\udc00-\udfff]/.test(p)));
}
console.log('Voz: texto PDF, páginas vazias, limites, divisão de frases/palavras e Unicode sem perda: OK');
