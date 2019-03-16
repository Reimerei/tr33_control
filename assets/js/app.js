import css from "../css/app.css";
import "phoenix_html"
import LiveSocket from "phoenix_live_view"

import 'bootstrap';

let liveSocket = new LiveSocket("/live")
liveSocket.connect()
