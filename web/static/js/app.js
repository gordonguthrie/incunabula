// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"
import $ from "jquery"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

var incunabula = {};

incunabula.setup_modals = function() {
    $(".incunabula-show").on('click', function () {
        console.log();
        var modalclass = $(this).attr("modal");
        $("." + modalclass).modal("show");
    })
}

//
// Make the menus and stuff work
//

$(".menu .item").tab();
incunabula.setup_modals();

//
// Resize the text area box
//
$(window).resize(function() {
    var offset = $("#incunabula-eiderdown").offset();
    var available = window.innerHeight - offset.top - 50;
    var height = String(available) + "px";
    $("#incunabula-eiderdown").css("height", height);
});

// Now trigger the resize event on load to resize
$(window).trigger('resize');

// Set up the save edits stuff
console.log($(".incunabula-load-saves"));
$(".incunabula-load-saves").on('click', function() {
    var edits= $(".incunabula-eiderdown, textarea").val();
    $(".incunabula-edits-hidden").val(edits);
});
