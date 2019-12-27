import css from "../css/app.css";
import { Socket } from "phoenix"
import LiveSocket from "phoenix_live_view"

import 'bootstrap';

let liveSocket = new LiveSocket("/live", Socket)
liveSocket.connect()
