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

incunabula.show_modal = function () {
    $(".ui.modal").modal("show");
};

incunabula.edit_link = function (event) {
    console.log($(event.target.value()));
    $(".incunabula-new-book").attr('href', '/books/bingo');
}

$(".incunabula-show").on('click', incunabula.show_modal);

$(".incunabula-book-title").on('change', incunabula.edit_link);
