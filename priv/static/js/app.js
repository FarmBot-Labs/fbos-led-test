// for phoenix_html support, including form and button helpers
// copy the following scripts into your javascript bundle:
// * https://raw.githubusercontent.com/phoenixframework/phoenix_html/v2.10.0/priv/static/phoenix_html.js
let socket = new Phoenix.Socket("/socket", {
  logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
})
socket.connect({user_id: "123"})
var chan = socket.channel("rooms:lobby", {})
chan.join()
// .receive("ignore", () => console.log("auth error"))
// .receive("ok", () => console.log("join ok"))
           // .after(10000, () => console.log("Connection interruption"))
chan.onError(e => console.log("something went wrong", e))
chan.onClose(e => console.log("channel closed", e))

chan.on("gpio_interupt:change", msg => {
  console.log("gpio: " + msg.pin + " level: " + msg.level);
  var elem = document.getElementById("pin_state." + msg.pin);
  if(elem) {
    elem.innerHTML = msg.level;
  }

  var elem = document.getElementById("led_state." + msg.pin);
  if (elem) {
    var level;
    if(msg.level == 1) {level = true} else {level = false}
    elem.checked = level
  }
})

function toggle(pin) {
  var elem = document.getElementById("led_state." + pin);
  var num = elem.checked ? 1 : 0;
  chan.push("led_toggle", {pin: pin, level: num});
  console.log(pin + " toggled + " + num);
}

function dance() {
  chan.push("dance", {});
}
