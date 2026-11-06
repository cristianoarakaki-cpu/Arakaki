'use strict';
window.PrismaVoiceOCR=(()=>{
 const core=window.PrismaVoiceOcrCore;
 function aborted(){const e=Error('Reconhecimento cancelado.');e.name='AbortError';return e}
 function check(alive){if(!alive())throw aborted()}
 function rotate(source,degrees){const radians=degrees*Math.PI/180,cos=Math.abs(Math.cos(radians)),sin=Math.abs(Math.sin(radians)),canvas=document.createElement('canvas');canvas.width=Math.ceil(source.width*cos+source.height*sin)+24;canvas.height=Math.ceil(source.height*cos+source.width*sin)+24;const ctx=canvas.getContext('2d');ctx.fillStyle='#fff';ctx.fillRect(0,0,canvas.width,canvas.height);ctx.translate(canvas.width/2,canvas.height/2);ctx.rotate(radians);ctx.drawImage(source,-source.width/2,-source.height/2);return canvas}
 async function recognize(page,worker,{precise=true,alive=()=>true,progress=()=>{}}={}){
  const owned=[];let render;
  try{
   const base=page.getViewport({scale:1}),maxSide=precise?3200:2500,budget=precise?7000000:4000000;
   const scale=Math.min(precise?3.8:2.5,maxSide/Math.max(base.width,base.height),Math.sqrt(budget/(base.width*base.height)));
   const view=page.getViewport({scale}),canvas=document.createElement('canvas');owned.push(canvas);canvas.width=Math.ceil(view.width);canvas.height=Math.ceil(view.height);
   const context=canvas.getContext('2d',{willReadFrequently:true});render=page.render({canvasContext:context,viewport:view,background:'rgb(255,255,255)'});await render.promise;check(alive);
   let source=canvas,angle=0;
   {
    const pixels=context.getImageData(0,0,canvas.width,canvas.height),normal=core.normalize(pixels.data,canvas.width,canvas.height);
    if(normal.extent<4)return{text:'',confidence:100,letters:0,bad:0,deskew:0,uncertain:false};
    context.putImageData(new ImageData(core.rgba(normal.gray),canvas.width,canvas.height),0,0);
    angle=precise?core.skew(normal.gray,canvas.width,canvas.height):0;
    if(angle){source=rotate(canvas,angle);owned.push(source);canvas.width=canvas.height=0}
   }
   await worker.setParameters({tessedit_pageseg_mode:'3',preserve_interword_spaces:'1',user_defined_dpi:'300'});check(alive);
   async function pass(image,label,psm='3'){check(alive);progress(label);await worker.setParameters({tessedit_pageseg_mode:psm});check(alive);const {data}=await worker.recognize(image,{}, {text:true});check(alive);return core.result(data.text,data.confidence)}
   let best=await pass(source,'Reconhecendo texto e layout…');
   const weak=()=>best.confidence<70||best.letters<24;
   if(precise&&weak()){
    const binary=(()=>{
     const ctx=source.getContext('2d',{willReadFrequently:true}),p=ctx.getImageData(0,0,source.width,source.height),gray=core.normalize(p.data,source.width,source.height).gray;
     const candidate=document.createElement('canvas');candidate.width=source.width;candidate.height=source.height;
     candidate.getContext('2d').putImageData(new ImageData(core.rgba(core.adaptive(gray,source.width,source.height,Math.max(10,Math.min(24,Math.round(source.width/100))))),source.width,source.height),0,0);
     return candidate;
    })();owned.push(binary);
    best=core.better(best,await pass(binary,'Realçando letras claras e fundos irregulares…'));binary.width=binary.height=0;
    if(weak())best=core.better(best,await pass(source,'Procurando trechos pequenos e texto disperso…','11'));
    if(best.letters<8||best.confidence<40){for(const degrees of [90,270,180]){const oriented=rotate(source,degrees);owned.push(oriented);try{best=core.better(best,await pass(oriented,'Conferindo orientação da página…'));}finally{oriented.width=oriented.height=0}if(best.confidence>=70&&best.letters>=24)break}}
   }
   return{...best,deskew:angle,uncertain:best.confidence<55};
  }finally{if(!alive()&&render)try{render.cancel()}catch{}for(const canvas of owned)canvas.width=canvas.height=0}
 }
 return{recognize};
})();
