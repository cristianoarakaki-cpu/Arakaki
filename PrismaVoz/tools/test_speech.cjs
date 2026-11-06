'use strict';
const assert=require('assert/strict');
const {pageText,chunks}=require('../assets/speech-core.js');
assert.equal(pageText([{str:'Um',hasEOL:false},{str:'texto',hasEOL:true},{str:'com\u00a0 espaço'},{notText:true}]),'Um texto com espaço');
assert.deepEqual(chunks('   '),[]);
assert.throws(()=>chunks('teste',1));
for(const text of ['palavra '.repeat(2000),'a'.repeat(10000),'😀'.repeat(3000),'Primeira frase. '.repeat(500)+'Segunda!']){
 const parts=chunks(text);
 assert(parts.length>1);assert(parts.every(p=>p.length>0&&p.length<=2800));
 assert.equal(parts.join('').replace(/\s/g,''),text.replace(/\s/g,''));
 assert(parts.every(p=>!/[\ud800-\udbff]$/.test(p)&&! /^[\udc00-\udfff]/.test(p)));
}
console.log('Voz: texto PDF, páginas vazias, limites, divisão de frases/palavras e Unicode sem perda: OK');

const item=(str,x,y,width,height=10)=>({str,transform:[10,0,0,10,x,y],width,height});
assert.equal(pageText([item('con',0,100,15),item('ferência',15,100,35),item('normal',60,100,35)]),'conferência normal');
assert.equal(pageText([item('Primeira linha',10,100,90),item('continua aqui.',10,88,95)]),'Primeira linha continua aqui.');
assert.equal(pageText([item('Segunda linha',10,88,90),item('Primeira linha',10,100,95)]),'Primeira linha Segunda linha');
const columns=[];for(let i=0;i<5;i++){columns.push(item('Esquerda '+i+' com muitas palavras nesta linha',20,100-i*12,100));columns.push(item('Direita '+i+' com muitas palavras nesta linha',260,100-i*12,100))}
const ordered=pageText(columns,{pageWidth:400});assert(ordered.indexOf('Esquerda 4')<ordered.indexOf('Direita 0'),ordered);
assert.equal(require('../assets/speech-core.js').continuous('co\u00ad\nnectado e bem-\nvindo.\nTexto 1.234,56.'),'conectado e bem-vindo. Texto 1.234,56.');
const {quality,chooseText}=require('../assets/speech-core.js');assert(quality('Digitalizado por app').suspect);assert(quality('\ufffd'.repeat(10)+' texto com caracteres quebrados').suspect);
assert.equal(chooseText('Título',{text:'Título com o conteúdo completo reconhecido da página.',confidence:90}),'Título com o conteúdo completo reconhecido da página.');
assert.equal(chooseText('Texto correto que deve ser preservado',{text:'xx',confidence:20}),'Texto correto que deve ser preservado');
assert.equal(chooseText('Texto original',{text:'Novo OCR',confidence:90},true),'Novo OCR');
assert(chunks('palavra '.repeat(1000)).every(p=>p.length<=700));
console.log('Leitura contínua: fragmentos, linhas, ordem visual/duas colunas, ligaturas, hífens, números e escolha conservadora do OCR: OK');

const table=[];for(let i=0;i<5;i++){table.push(item('Nome '+i,20,100-i*12,100));table.push(item('12/11/2026',260,100-i*12,100))}const tableText=pageText(table,{pageWidth:400});assert(tableText.indexOf('12/11/2026')<tableText.indexOf('Nome 1'));console.log('Tabela simples não é reordenada como duas colunas de prosa: OK');

assert.equal(quality('文字'.repeat(40)).suspect,false);
