(function(){

// ============================================================
// BLOQUE A — buscar iframes y entrar en su documento
// ============================================================
var R=[];
var SEP='--------------------------------------------------';
function t(s){R.push(SEP);R.push(s);R.push(SEP);}
function L(s){R.push(s);}

t('A. IFRAMES Y DOCUMENTOS EMBEBIDOS');
var frames=document.getElementsByTagName('iframe');
L('iframes encontrados: '+frames.length);
for(var i=0;i<frames.length;i++){
  var fr=frames[i];
  L('iframe['+i+'] id='+fr.id+' name='+fr.name+' src='+fr.src);
  try{
    var fd=fr.contentDocument||fr.contentWindow.document;
    var finputs=fd.getElementsByTagName('input');
    L('  inputs dentro: '+finputs.length);
    for(var j=0;j<finputs.length;j++){
      var el=finputs[j];
      L('  ['+el.type+'] id='+el.id+' name='+el.name+' val='+el.value+' checked='+(el.checked||'n/a')+' onclick='+(el.getAttribute('onclick')||'')+' onchange='+(el.getAttribute('onchange')||''));
    }
    var fbtns=fd.getElementsByTagName('input');
    var fsc=fd.getElementsByTagName('script');
    L('  scripts inline en iframe: '+fsc.length);
    for(var s=0;s<fsc.length;s++){
      if(!fsc[s].src){
        var stxt=fsc[s].text||fsc[s].textContent||fsc[s].innerText||'';
        var slines=stxt.split('\n');
        for(var sl=0;sl<slines.length;sl++){
          if(/selected|checked|push|hidden|setevent|grid|consult/i.test(slines[sl])&&slines[sl].trim().length>3){
            L('  script['+s+'] L'+sl+': '+slines[sl].trim().substring(0,130));
          }
        }
      }
    }
  }catch(e){
    L('  BLOQUEADO (cross-origin): '+e.message);
  }
}

// frames dentro de frames (un nivel más)
t('A2. FRAMES ANIDADOS (framesets)');
var allFrames=window.frames;
L('window.frames.length: '+allFrames.length);
for(var i=0;i<allFrames.length;i++){
  try{
    var fw=allFrames[i];
    var fd2=fw.document;
    L('frame['+i+'] title='+fd2.title+' inputs='+fd2.getElementsByTagName('input').length);
  }catch(e){L('frame['+i+'] bloqueado: '+e.message);}
}

// ============================================================
// BLOQUE B — interceptar XMLHttpRequest (AJAX)
// ============================================================
t('B. INTERCEPTOR XHR (AJAX)');
if(!window.__xhrIntercepted){
  var OrigXHR=window.XMLHttpRequest;
  function XHRProxy(){
    var real=new OrigXHR();
    var self=this;
    this.open=function(method,url){
      self.__url=url;
      self.__method=method;
      return real.open.apply(real,arguments);
    };
    this.send=function(body){
      console.warn('[XHR] '+self.__method+' '+self.__url);
      if(body)console.warn('[XHR] BODY: '+String(body).substring(0,500));
      real.onreadystatechange=function(){
        if(real.readyState===4){
          console.warn('[XHR] RESP '+real.status+': '+real.responseText.substring(0,300));
        }
        if(self.onreadystatechange)self.onreadystatechange.apply(self,arguments);
      };
      return real.send.apply(real,arguments);
    };
    this.setRequestHeader=function(k,v){
      console.warn('[XHR] HEADER: '+k+': '+v);
      return real.setRequestHeader.apply(real,arguments);
    };
    // proxiar el resto de propiedades
    var props=['readyState','status','statusText','responseText','responseXML','response','responseType','timeout','withCredentials','upload','onreadystatechange','onload','onerror','ontimeout'];
    for(var pi=0;pi<props.length;pi++){
      (function(p){
        try{
          Object.defineProperty(self,p,{
            get:function(){return real[p];},
            set:function(v){real[p]=v;},
            configurable:true
          });
        }catch(e){}
      })(props[pi]);
    }
    this.abort=function(){return real.abort();};
    this.getAllResponseHeaders=function(){return real.getAllResponseHeaders();};
    this.getResponseHeader=function(h){return real.getResponseHeader(h);};
  }
  window.XMLHttpRequest=XHRProxy;
  window.__xhrIntercepted=true;
  L('XHR interceptado. Proxima peticion AJAX aparecera en consola.');
}else{L('XHR ya interceptado.');}

// ============================================================
// BLOQUE C — interceptar navegacion por formulario (submit)
// ============================================================
t('C. INTERCEPTOR SUBMIT DE FORMULARIOS');
if(!window.__submitIntercepted){
  var allForms=document.forms;
  for(var fi=0;fi<allForms.length;fi++){
    (function(form){
      if(form.__subMon)return;
      form.__subMon=true;
      form.attachEvent?
        form.attachEvent('onsubmit',logSubmit):
        form.addEventListener('submit',logSubmit,false);
    })(allForms[fi]);
  }
  // tambien intentar en iframes
  for(var fri=0;fri<frames.length;fri++){
    try{
      var ffd=frames[fri].contentDocument||frames[fri].contentWindow.document;
      var fffforms=ffd.forms;
      for(var fi2=0;fi2<fffforms.length;fi2++){
        (function(form){
          if(form.__subMon)return;
          form.__subMon=true;
          form.attachEvent?
            form.attachEvent('onsubmit',logSubmit):
            form.addEventListener('submit',logSubmit,false);
        })(fffforms[fi2]);
      }
    }catch(e){}
  }
  window.__submitIntercepted=true;
  L('Submit interceptado en '+allForms.length+' formularios del doc principal.');
}else{L('Submit ya interceptado.');}

function logSubmit(e){
  console.warn('[SUBMIT] formulario enviado: '+(this.action||''));
  var els=this.elements;
  for(var i=0;i<els.length;i++){
    if(els[i].value)
      console.warn('[SUBMIT] '+els[i].name+'='+els[i].value.substring(0,200));
  }
}

// ============================================================
// BLOQUE D — interceptar document.location y GX_setevent
// ============================================================
t('D. INTERCEPTOR GX_setevent Y NAVEGACION');
if(typeof window.GX_setevent==='function'&&!window.__gxi){
  var _ogx=window.GX_setevent;
  window.GX_setevent=function(){
    var args=[];
    for(var i=0;i<arguments.length;i++)args.push(arguments[i]);
    console.warn('[GX] GX_setevent: '+args.join(' | '));
    return _ogx.apply(this,args);
  };
  window.__gxi=true;
  L('GX_setevent interceptado.');
}else if(window.__gxi){L('GX_setevent ya interceptado.');}
else{L('GX_setevent no encontrado en window.');}

// Intentar en iframes tambien
for(var fri2=0;fri2<frames.length;fri2++){
  try{
    var fw2=frames[fri2];
    if(typeof fw2.GX_setevent==='function'&&!fw2.__gxi){
      (function(fw){
        var _ogx2=fw.GX_setevent;
        fw.GX_setevent=function(){
          var args=[];
          for(var i=0;i<arguments.length;i++)args.push(arguments[i]);
          console.warn('[GX iframe] GX_setevent: '+args.join(' | '));
          return _ogx2.apply(fw,args);
        };
        fw.__gxi=true;
      })(fw2);
      L('GX_setevent interceptado en frame['+fri2+']');
    }
  }catch(e){L('frame['+fri2+'] GX: bloqueado '+e.message);}
}

// ============================================================
// SALIDA
// ============================================================
R.push(SEP);
R.push('FIN FASE 2. Interceptores activos.');
R.push('Ahora: marca checkboxes y pulsa Consultar.');
R.push('Los mensajes [XHR] [SUBMIT] [GX] apareceran en consola en tiempo real.');
R.push('Luego ejecuta:  copy(window.__diag2)');
window.__diag2=R.join('\n');
console.log(window.__diag2);

})();
