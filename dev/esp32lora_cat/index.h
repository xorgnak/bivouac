const char index_html[] PROGMEM = R"=====(
  <!DOCTYPE html>
  <html>
  <head>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
  <script>
  var ws = null;
    function ge(s){ return document.getElementById(s);}
    function ce(s){ return document.createElement(s);}
    function stb(){ window.scrollTo(0, document.body.scrollHeight || document.documentElement.scrollHeight); }

    function addMessage(m){
      var msg = ce("p");
      msg.innerText = m;
      ge("dbg").appendChild(msg);
      stb();
    }

    function startSocket(){
      ws = new WebSocket('ws://'+document.location.host+'/ws',['arduino']);
      ws.binaryType = "arraybuffer";
      ws.onopen = function(e){
        $('#input_el').attr('disabled', false);
      };
      ws.onclose = function(e){
        startSocket();
      };
      ws.onerror = function(e){
        console.log("ws error", e);
        addMessage("Error");
      };
      ws.onmessage = function(e){
        addMessage(e.data);
      };
      ge("input_el").onkeydown = function(e){
        stb();
        if(e.keyCode == 13 && ge("input_el").value != ""){
          ws.send(ge("input_el").value);
          ge("input_el").value = "";
        }
      }
    }
  </script>
  </head>
    <body id="body" onload="startSocket()">
    <div id="input_div" style='width: 100%; text-align: center;'>
      <input type="text" value="" id="input_el"  placeholder='usage: [!@#:]val' style='width: 95%;' disabled>
    </div>
    <pre id="dbg" style='width: 100%;'></pre>
  </body>
  </html>
)=====";
