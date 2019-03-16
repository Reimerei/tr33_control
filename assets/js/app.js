import "phoenix_html"
import {Socket} from "phoenix"
import "bootstrap-slider"

let socket = new Socket("/socket", {})
socket.connect()

let channel = socket.channel("live_forms", {})
channel.join()
  .receive("ok", resp => {
    var length = resp.msgs.length;
    for (var i = 0; i < length; i++) {
      on_msg(resp.msgs[i]);
    }
    console.log("Joined channel successfully", resp)
  })
  .receive("error", resp => { console.log("Unable to join channel", resp) })

channel.on("form", msg => { on_msg(msg); });

function on_msg(msg) {
  $("#" + msg.id).html(msg.html);

  // add event listeners
  $(".listen_form_change_" + msg.id).change(function(event){
    on_event(msg.id, "form_change");
  });

  $(".listen_form_button_" + msg.id).on('click', function () {
    on_event(msg.id, "button");
  });

  $(".listen_button_" + msg.id).on('click', function()  {
    channel.push("button", {id: msg.id})
  });

  // enable sliders
  $("[id^=slider_"  + msg.id + "]").each(function(){
    $(this).slider();
  });
}

function on_event(id, topic) {
  var form = $("#form_" + id).serializeArray();
  var data = {};
  $.each(form, function(i, v) {data[v.name] = v.value});
  channel.push(topic, data);
}




