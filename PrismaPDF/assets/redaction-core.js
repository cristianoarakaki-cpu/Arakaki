'use strict';
const PrismaRedactionCore=(()=>{
 const norm=s=>String(s).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
 function terms(value){const list=String(value).split(/[\r\n]+/).map(s=>s.trim()).filter(Boolean);if(list.length>100||list.some(s=>s.length<2||s.length>200))throw Error('Informe até 100 termos, de 2 a 200 caracteres, um por linha.');return [...new Set(list)];}
 function find(text,options={},extra=[]){const matches=[];const add=(type,start,end)=>{if(end>start)matches.push({type,start,end,value:text.slice(start,end)})};
 const scan=(type,regex,group=0)=>{for(const m of text.matchAll(regex)){const value=m[group];if(value){const start=m.index+(group?m[0].lastIndexOf(value):0);add(type,start,start+value.length)}}};
 if(options.cpf)scan('Possível CPF',/(?<!\d)\d{3}[ .]*\d{3}[ .]*\d{3}[ -]*\d{2}(?!\d)/g);
 if(options.cnpj)scan('Possível CNPJ',/(?<!\d)\d{2}[ .]*\d{3}[ .]*\d{3}[ /]*\d{4}[ -]*\d{2}(?!\d)/g);
 if(options.rg){scan('Possível RG',/\b(?:RG|R\.?G\.?|registro geral|identidade)[ :nº°o.\-]*([0-9][0-9. \-]{4,19}[0-9Xx])/gi,1);scan('Possível RG',/(?<!\d)\d{2}\.\d{3}\.\d{3}-[\dXx](?!\d)/g);}
 if(options.email)scan('E-mail',/[\p{L}\d.!#$%&'*+\/=?^_`{|}~\-]+@[\p{L}\d\-]+(?:\.[\p{L}\d\-]+)+/gu);
 if(options.phone)scan('Possível telefone',/(?<!\d)(?:\+55[ .-]*)?(?:\(\d{2}\)|\d{2})[ .-]*(?:9[ .-]*)?\d{4}[ .-]*\d{4}(?!\d)/g);
 if(options.professional)scan('Possível registro profissional',/\b(?:CRM|COREN|CRO|CRP|CREA|OAB|CREFITO|CRF|CRMV|CREF|CRN)(?:[ \/.\-]*(?:[A-Z]{2}))?[ :nº°o.\/\-]*\d[\d. \/\-]{0,25}\d(?:[ \/\-]*[A-Z]{2})?\b/gi);
 if(options.cep)scan('Possível CEP',/(?<!\d)\d{5}-\d{3}(?!\d)/g);
 if(options.names){scan('Possível nome em campo',/\b(?:nome(?: completo)?|titular|benefici[aá]rio|requerente|paciente|respons[aá]vel|contratante|contratad[oa]|assinante)\s*[:\-]\s*([\p{L}][\p{L}.'’ -]{2,100}?)(?=[ \t]+(?:CPF|RG|CNPJ|E-?mail|Telefone|Endere[cç]o)\b|[\n\r;:|]|$)/giu,1);scan('Possível nome no texto',/\b[A-ZÁÀÂÃÉÊÍÓÔÕÚÜÇ][a-záàâãéêíóôõúüç]{1,}(?:[ \t]+(?:d[aeo]s?|e))?(?:[ \t]+[A-ZÁÀÂÃÉÊÍÓÔÕÚÜÇ][a-záàâãéêíóôõúüç]{1,}){1,4}\b/gu);}
 let hay='',position=0;const starts=[],ends=[];for(const char of text){const value=norm(char);for(let n=0;n<value.length;n++){starts.push(position);ends.push(position+char.length)}hay+=value;position+=char.length}for(const term of extra){const needle=norm(term).replace(/\s+/g,' ');if(!needle)continue;const escaped=needle.replace(/[.*+?^${}()|[\]\\]/g,'\\$&').replace(/ /g,'[ \\t\\r\\n]+');const re=new RegExp(escaped,'g');for(const m of hay.matchAll(re)){const before=hay[m.index-1]||'',after=hay[m.index+m[0].length]||'';if(!/[\p{L}\d]/u.test(before)&&!/[\p{L}\d]/u.test(after))add('Termo informado / nome repetido',starts[m.index],ends[m.index+m[0].length-1])}}
 return matches.filter((m,i,a)=>a.findIndex(x=>x.start===m.start&&x.end===m.end&&x.type===m.type)===i);
 }
 function rect(box){const x=Math.max(0,Math.min(1,box.x)),y=Math.max(0,Math.min(1,box.y)),right=Math.max(x,Math.min(1,box.x+box.w)),bottom=Math.max(y,Math.min(1,box.y+box.h));if(![x,y,right,bottom].every(Number.isFinite)||right<=x||bottom<=y)return null;return{x,y,w:right-x,h:bottom-y};}
 function regions(match,spans){return spans.filter(s=>s.start<match.end&&s.end>match.start).map(s=>rect(s.box)).filter(Boolean);}
 return{norm,terms,find,rect,regions};
})();
if(typeof module!=='undefined')module.exports=PrismaRedactionCore;
