import "phoenix_html"
import {Socket} from "phoenix"
import "bootstrap-slider"

let socket = new Socket("/socket", {})
socket.connect()

let channel = socket.channel("commands", {})
channel.join()
  .receive("ok", resp => {
    console.log("Joined commands successfully", resp)
    channel.push("init", {})
  })
  .receive("error", resp => { console.log("Unable to join commands", resp) })

channel.on("form", msg => {
  $("#" + msg.id).html(msg.html);

  // add event listeners
  $("#form_" + msg.id).change(function(event){
    on_event(msg.id, "form_change");
  });

  // enable sliders
  $("[id^=slider_"  + msg.id + "]").each(function(){
    $(this).slider();
  });

  $("#button_" + msg.id).on('click', function () {
    on_event(msg.id, "button");
  });
});

function on_event(id, topic) {
  var form = $("#form_" + id).serializeArray();
  var data = {};
  $.each(form, function(i, v) {data[v.name] = v.value});
  channel.push(topic, data);
}




