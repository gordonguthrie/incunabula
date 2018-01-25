import {Socket, LongPoller} from "phoenix"

class Book {
    static init() {
        let socket = new Socket("/socket", {
            logger: ((kind, msg, data) => {console.log(`${kind}: ${msg}`, data) })
        })

        console.log("in init")

        socket.connect()

        var booktitle = $("#booktitle")

        socket.onOpen(ev  => console.log("OPEN", ev))
        socket.onError(ev => console.log("ERROR", ev))
        socket.onClose(ev => console.log("CLOSE", ev))

        chan.join()
            .receive("ignore", () => console.log("auth error"))
            .receive("ok",     () => console.log("join ok"))
            .after(10000,      () => console.log("Connection interruption"))

        chan.onError(e => console.log("something went wrong", e))
        chan.onClose(e => console.log("channel closed",       e))

    chan.on("new:title", msg => {
        console.log("got book title msg", msg)
        $booktitle.append(msg)
    })
    }
}

$( () => Book.init())

export default Book
