// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let incunabula = {}

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

function draw_reviews(id, msg) {
    // need to setup up the reviews
    // draw them first, then bind functions
    draw(id, msg)
    incunabula.bind_review_buttons()
}

function draw_reviewers(id, msg) {
    // need to set up modals
    // draw them first, then bind functions
    draw(id, msg)
    incunabula.bind_delete_icons()
}

function draw_users(id, msg) {
    // need to set up modals
    // draw them first, then bind functions
    draw(id, msg)
    incunabula.bind_delete_icons()
    incunabula.setup_modals()
}

function draw(id, msg) {
    // console.log("got new thing to draw", id, msg)
    $("#" + id).html(msg)
}

function draw_many(klass, msg) {
    // console.log("got new thing to draw", klass, msg)
    $("." + klass).html(msg)
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
        // console.log(topic)
        let key = make_key(topic)
        // console.log(key)
        let route = router.get(key)
        // console.log(route)
        channel.join()
            .receive("ok", resp => {
                // console.log("got response back")
                // console.log(topic)
                // console.log(resp)
                // console.log(route.id)
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

// router for admin
router.set("admin:get_users",
           {id: "admin-get_users",
            draw_fn: function(id, msg) {draw_users(id, msg)}})
router.set("admin:get_users_dropdown",
           {id: "admin-get_users_dropdown",
            draw_fn: function(id, msg) {draw(id, msg)}})

// router for a particular book
router.set("book:get_reviews",
           {id:      "book-get_reviews",
            draw_fn: function(id, msg) {draw_reviews(id, msg)}})
router.set("book:get_reviewers",
           {id:      "book-get_reviewers",
            draw_fn: function(id, msg) {draw_reviewers(id, msg)}})
router.set("book:get_possible_reviewers_dropdown",
           {id:      "book-get_possible_reviewers_dropdown",
            draw_fn: function(id, msg) {draw_reviewers(id, msg)}})
router.set("book:get_reviewers_dropdown",
           {id:      "book-get_reviewers_dropdown",
            draw_fn: function(id, msg) {draw_reviewers(id, msg)}})
router.set("book:get_chaffs",
           {id:      "book-get_chaffs",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_chapters_dropdown",
           {id:      "book-get_chapters_dropdown",
            draw_fn: function(id, msg) {draw_many(id, msg)}})
router.set("book:get_chapters",
           {id:      "book-get_chapters",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_images",
           {id:      "book-get_images",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_chaff_title",
           {id:      "book-get_chaff_title",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_chapter_title",
           {id:      "book-get_chapter_title",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:get_book_title",
           {id:      "book-get_book_title",
            draw_fn: function(id, msg) {draw(id, msg)}})

// some update routes
router.set("book:save_review_edits",
           {id:      "book-save_edits",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:save_chaff_edits",
           {id:      "book-save_edits",
            draw_fn: function(id, msg) {draw(id, msg)}})
router.set("book:save_chapter_edits",
           {id:      "book-save_edits",
            draw_fn: function(id, msg) {draw(id, msg)}})
// note that in the chapter and chaff titles we
// have already 'got them' so we want to update them in-place
// hence the IDs we call the draw_fn on are different
router.set("book:update_chapter_title",
           {id:      "book-get_chapter_title",
            draw_fn: function(id, msg) {}})
router.set("book:update_chaff_title",
           {id:      "book-get_chaff_title",
            draw_fn: function(id, msg) {}})
// some updates we do nothing on return
router.set("book:update_book_title",
           {id:      "book-update_title",
            draw_fn: function(id, msg) {}})

socket.connect()

topic_router = make_topic_router(topics)

export function socket_push(topic, msg) {
    // console.log("pushing on socket")
    // console.log(topic)
    let key = make_key(topic)
    // console.log(key)
    topic_router[key].push(topic, msg)
        .receive("ok", resp => {console.log("got ok")})
        .receive("error", e => console.log(e))
}

export function socket_init(external_object) {
    incunabula = external_object
}

export default socket
