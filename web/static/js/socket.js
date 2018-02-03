// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

// Create our socket
let socket = new Socket("/socket", {params: {token: window.userToken}})

// Create a route for channel message
let router = new Map()

// Now get all the topics that the page wishes to subscribe to
let topics = document.getElementsByClassName("incunabula-topic")

// define some captures we will use later
var topic_router = []


//
// Define the functions that we are going to use
//
function sanitize(html){return $("div/>").text(html).html()}

function draw(id, msg) {
    console.log("got new thing to draw", id, msg)
    $("#" + id).html(msg)
}

function make_key(str) {
    var components = str.split(":")
    return components[0] + ":" + components[1]
}

function make_topic_router(topics) {
    let topic_router = []
    Array.from(topics).forEach((t) => {
        let topic = t.getAttribute("topic")
        let channel = socket.channel(topic, {})
        console.log(topic)
        let key = make_key(topic)
        console.log(key)
        let route = router.get(key)
        channel.join()
            .receive("ok", resp => {
                console.log("got response")
                console.log(route)
                route.draw_fn(route.id, resp)
            })
        .receive("error", resp => {
            console.log("Unable to join", topic, resp)
        })
        channel.on("ping",  ({count})   => ('ok'))
        channel.on("books", (payload) => route.draw_fn(route.id, payload.books))
        topic_router[key] = channel
    })
    return topic_router
}

//
// Now set up the socket
//

//
// First we set up our router that will map incoming messages with the draw
// functions that are called on the responses
//
// By convention the message set maps to the drawing id with a colon replace
// by a hyphen becuz css and shit
//

// router for all books
router.set("books:list",
           {id:      "books-list",
            draw_fn: function(id, msg) {draw(id, msg)}})

// router for a particular book
router.set("book:get_chapters",
           {id:      "book-get_chapters",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_images",
           {id:      "book-get_images",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_book_title",
           {id:      "book-get_book_title",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_book_title",
           {id:      "book-get_book_title",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:save_edits",
           {id:      "book-chapter-save_edits",
            draw_fn: function(id, msg) {draw(id, msg)}})

socket.connect()

console.log("about to make topic ruter")

topic_router = make_topic_router(topics)
console.log(topic_router)

export function socket_push(topic, msg) {
    console.log("pushing", msg, "to", topic)
    let key = make_key(topic)
    topic_router[key].push(topic, msg)
        .receive("ok", resp => {console.log("got ok")})
        .receive("error", e => console.log(e))
}

export default socket
