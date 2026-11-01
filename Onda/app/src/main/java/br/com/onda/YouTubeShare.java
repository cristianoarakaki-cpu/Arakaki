package br.com.onda;

import java.net.URI;

/** A foreground, user-triggered bridge for public video links, never file access. */
final class YouTubeShare {
 static boolean isAction(String value){try{return "onda-share".equalsIgnoreCase(new URI(value).getScheme());}catch(Exception e){return false;}}
 static String action(String value){try{URI u=new URI(value);if(value.length()>128||!"onda-share".equals(u.getScheme())||!"youtube".equals(u.getHost())||u.getUserInfo()!=null||u.getPort()!=-1||u.getRawQuery()!=null||u.getFragment()!=null||!u.getPath().matches("/[A-Za-z0-9_-]{11}"))return "";return DownloadLinks.canonical("https://www.youtube.com/watch?v="+u.getPath().substring(1));}catch(Exception e){return "";}}
 static String video(String value){try{return DownloadLinks.canonical(value);}catch(Exception e){return "";}}
 static String page(String value){String selected=video(value);if(!selected.isEmpty())return selected;try{return DownloadLinks.playlist(value);}catch(Exception ignored){return "";}}
 static String script(){return """
 (function(){
  function searching(){return location.protocol==='https:'&&/^(m\\.|www\\.)?youtube\\.com$/.test(location.hostname)&&location.pathname==='/results'&&document.visibilityState!=='hidden';}
  if(!searching())return;
  if(window.__ondaResultSharing){window.__ondaResultSharing.scan();return;}
  var selector='ytm-video-with-context-renderer,ytm-compact-video-renderer,ytm-video-renderer,ytm-rich-item-renderer,ytm-shorts-lockup-view-model,ytd-video-renderer';
  function idOf(raw){try{var u=new URL(raw,location.href),id='';if(u.protocol!=='https:'||u.username||u.password||u.port)return '';if(/^(m\\.|www\\.)?youtube\\.com$/.test(u.hostname)){if(u.pathname==='/watch'&&u.searchParams.getAll('v').length===1)id=u.searchParams.get('v');else{var m=u.pathname.match(/^\\/shorts\\/([A-Za-z0-9_-]{11})\\/?$/);if(m)id=m[1];}}else if(u.hostname==='youtu.be')id=u.pathname.slice(1);return /^[A-Za-z0-9_-]{11}$/.test(id)?id:'';}catch(e){return '';}}
  function selection(card){if(!card)return null;var links=card.querySelectorAll('a[href]'),ids={},id='',label='';for(var j=0;j<Math.min(links.length,32);j++){var candidate=idOf(links[j].getAttribute('href'));if(candidate){ids[candidate]=true;id=candidate;if(links[j].textContent.trim())label=links[j].textContent.trim();}}return Object.keys(ids).length===1?{id:id,label:label}:null;}
  function icon(){var ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');svg.setAttribute('viewBox','0 0 24 24');svg.setAttribute('width','24');svg.setAttribute('height','24');svg.setAttribute('aria-hidden','true');[[6,12,18,5],[6,12,18,19]].forEach(function(p){var l=document.createElementNS(ns,'line');['x1','y1','x2','y2'].forEach(function(k,i){l.setAttribute(k,p[i]);});l.setAttribute('stroke','currentColor');l.setAttribute('stroke-width','2');svg.appendChild(l);});[[6,12],[18,5],[18,19]].forEach(function(p){var c=document.createElementNS(ns,'circle');c.setAttribute('cx',p[0]);c.setAttribute('cy',p[1]);c.setAttribute('r','3');c.setAttribute('fill','currentColor');svg.appendChild(c);});return svg;}
  function scan(){if(!searching())return;
   if(!document.getElementById('onda-result-share-style')){var style=document.createElement('style');style.id='onda-result-share-style';style.textContent='.onda-share-bar{display:flex!important;justify-content:flex-end!important;clear:both;margin:4px 8px!important}.onda-share-link{display:inline-flex!important;align-items:center!important;justify-content:center!important;box-sizing:border-box!important;min-width:48px!important;width:48px!important;min-height:48px!important;height:48px!important;color:inherit!important;background:transparent!important;border:1px solid currentColor!important;border-radius:12px!important;opacity:.85;text-decoration:none!important}';(document.head||document.documentElement).appendChild(style);}
   var cards=document.querySelectorAll(selector),processed=0;for(var i=0;i<cards.length&&processed<80;i++){var card=cards[i],rect=card.getBoundingClientRect();if(rect.bottom < -128||rect.top > innerHeight+128)continue;if(card.querySelector(selector))continue;processed++;var chosen=selection(card),bar=card.querySelector('.onda-share-bar');if(!chosen){if(bar)bar.remove();continue;}if(!bar){bar=document.createElement('div');bar.className='onda-share-bar';var button=document.createElement('a');button.className='onda-share-link';button.setAttribute('role','button');button.appendChild(icon());button.addEventListener('click',function(event){if(!event.isTrusted){event.preventDefault();return;}event.stopPropagation();var chosen=selection(event.currentTarget.closest(selector));if(!chosen){event.preventDefault();return;}event.currentTarget.setAttribute('href','onda-share://youtube/'+chosen.id);},true);bar.appendChild(button);card.appendChild(bar);}var button=bar.firstElementChild;button.setAttribute('href','onda-share://youtube/'+chosen.id);button.setAttribute('aria-label','Compartilhar vídeo: '+(chosen.label.slice(0,120)||chosen.id));button.setAttribute('title','Compartilhar link do vídeo');}
  }
  var pending=0;function queue(){if(!searching())return;clearTimeout(pending);pending=setTimeout(function(){pending=0;scan();},250);}
  window.__ondaResultSharing={scan:scan};window.addEventListener('scroll',queue,{passive:true});document.addEventListener('visibilitychange',function(){if(document.visibilityState==='hidden'){clearTimeout(pending);pending=0;}else queue();});scan();queue();
 })();
 """;}
}
