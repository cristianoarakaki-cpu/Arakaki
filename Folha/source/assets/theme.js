(()=>{
const key='folha-theme',valid=['system','light','dark'];let choice='system';try{const saved=localStorage.getItem(key);if(valid.includes(saved))choice=saved}catch{}
const media=matchMedia('(prefers-color-scheme: dark)');
function apply(){let systemDark=media.matches;try{if(window.Android&&typeof Android.isSystemDark==='function')systemDark=Android.isSystemDark()}catch{}const dark=choice==='dark'||choice==='system'&&systemDark;document.documentElement.dataset.theme=dark?'dark':'light';document.documentElement.style.colorScheme=dark?'dark':'light';try{if(window.Android&&typeof Android.setThemeMode==='function')Android.setThemeMode(choice,dark)}catch{}const input=document.querySelector('#theme');if(input)input.value=choice}
apply();if(media.addEventListener)media.addEventListener('change',apply);else media.addListener(apply);
document.addEventListener('DOMContentLoaded',()=>{const input=document.querySelector('#theme');input.value=choice;input.addEventListener('change',()=>{choice=valid.includes(input.value)?input.value:'system';try{localStorage.setItem(key,choice)}catch{}apply()})});
})();
