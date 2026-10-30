'use strict';
const PrismaCompressionCore=(()=>{
 const presets={light:{edge:2400,quality:.85},balanced:{edge:1800,quality:.72},strong:{edge:1200,quality:.5}};
 function plan(width,height,key){const p=presets[key];if(!p)throw Error('Escolha um nível de compressão.');if(!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||width*height>16000000)return null;const scale=Math.min(1,p.edge/Math.max(width,height));return{width:Math.max(1,Math.round(width*scale)),height:Math.max(1,Math.round(height*scale)),quality:p.quality};}
 function rgba(bytes,channels,target){if(![1,3].includes(channels)||bytes.length%channels)throw Error('Imagem incompatível.');const out=target||new Uint8ClampedArray(bytes.length/channels*4);if(out.length!==bytes.length/channels*4)throw Error('Tamanho de imagem incompatível.');for(let p=0,i=0;i<bytes.length;i+=channels,p+=4){out[p]=bytes[i];out[p+1]=bytes[i+(channels===3?1:0)];out[p+2]=bytes[i+(channels===3?2:0)];out[p+3]=255}return out;}
 function hasJpegMetadata(bytes){const marker=new TextDecoder('latin1').decode(bytes.subarray(0,Math.min(bytes.length,65536)));return marker.includes('Exif\x00\x00')||marker.includes('ICC_PROFILE');}
 function reduction(before,after){return after<before?100*(before-after)/before:0;}
 return{plan,rgba,hasJpegMetadata,reduction};
})();
if(typeof module!=='undefined')module.exports=PrismaCompressionCore;
