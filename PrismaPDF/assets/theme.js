'use strict';
(()=>{const media=window.matchMedia('(prefers-color-scheme: dark)');let mode='system';try{const saved=localStorage.getItem('prisma-appearance');if(['system','light','dark'].includes(saved))mode=saved}catch{}
 function apply(){let systemDark=media.matches;try{if(typeof window.PrismAndroid?.systemDark==='function')systemDark=window.PrismAndroid.systemDark()}catch{}const dark=mode==='dark'||mode==='system'&&systemDark;document.documentElement.dataset.theme=dark?'dark':'light';document.documentElement.style.colorScheme=dark?'dark':'light';const meta=document.querySelector('meta[name="color-scheme"]');if(meta)meta.content=dark?'dark':'light';const select=document.querySelector('#appearance');if(select)select.value=mode;const button=document.querySelector('#themeToggle');if(button){button.textContent=dark?'☀':'☾';button.setAttribute('aria-label',dark?'Ativar modo claro':'Ativar modo escuro');button.setAttribute('title',dark?'Ativar modo claro':'Ativar modo escuro')}
 try{if(typeof window.PrismAndroid?.setAppearance==='function')window.PrismAndroid.setAppearance(mode,dark)}catch{}
 }
 window.PrismaAppearance={apply,get mode(){return mode},set(value){if(!['system','light','dark'].includes(value))return false;mode=value;let saved=true;try{localStorage.setItem('prisma-appearance',mode)}catch{saved=false}apply();return saved}};
 if(media.addEventListener)media.addEventListener('change',()=>{if(mode==='system')apply()});else media.addListener(()=>{if(mode==='system')apply()});apply();
})();
