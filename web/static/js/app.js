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

import {socket, socket_push} from "./socket"

var incunabula = {};

incunabula.setup_modals = function() {
    $(".incunabula-show").on('click', function () {
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

if ($("#incunabula-eiderdown").length){

    $(window).resize(function() {
        // if there is an eiderdown editor resize it
        // but only if the window is more than 700 wide
        // (this is the media query width)
        if (window.innerWidth > 700) {
            var offset = $("#incunabula-eiderdown").offset();
            var available = window.innerHeight - offset.top - 50;
            var height = String(available) + "px";
            $("#incunabula-eiderdown").css("height", height);
        } else {
            $("#incunabula-eiderdown").css("height", "auto");
        }
    });

    // Now trigger the resize event on load to resize
    $(window).trigger('resize');

    // Set up the save edits stuff

    incunabula.maybe_save_edits_fn = function() {
        var is_dirty = $(".incunabula-eiderdown, textarea").attr("dirty");
        var edits= $(".incunabula-eiderdown, textarea").val();
        if (is_dirty == "true") {
            incunabula.save_edits_fn(edits, "autosaved",
                                     "autosaved in browser", "minor");
            $(".incunabula-eiderdown, textarea").attr("dirty", "false");
        }
    }

    incunabula.save_edits_fn = function (data, title, msg, tag_bump) {
        var topic = $("#book-chapter-save_edits").attr("topic");
        socket_push(topic, {commit_title: title,
                            commit_msg:   msg,
                            data:         data,
                            tag_bump:     tag_bump})
    };

    $(".incunabula-submit-edits").on('click', function () {
        var edits= $(".incunabula-eiderdown, textarea").val();
        var commit_msg = $(".incunabula-commit_msg").val();
        var commit_title = $(".incunabula-commit_title").val();
        $(".incunabula-save-edits").modal("hide");
        // clear up the old messages
        if (commit_title == "") {
            commit_title = "untitled save";
        }
        if (commit_msg == "") {
            commit_msg = "no save message";
        }
        $(".incunabula-commit_msg").val("");
        $(".incunabula-commit_title").val("");
        $(".incunabula-eiderdown, textarea").attr("dirty", "false");
        incunabula.save_edits_fn(edits, commit_title, commit_msg, "major");
    });

    //
    // This function detects change on the textarea and marks it as dirty
    // The timer function only commits changes if the textarea is dirty
    //
    // YOU NEED TWO FUNCTIONS TO BE SURE IT WORKS
    //

    $(".incunabula-eiderdown, textarea").on('keyup', function () {
        $(".incunabula-eiderdown, textarea").attr("dirty", true);
    });

    $(".incunabula-eiderdown, textarea").on('change', function () {
        $(".incunabula-eiderdown, textarea").attr("dirty", true);
    });

    // tick once a minute
    window.setInterval(incunabula.maybe_save_edits_fn, 60000);
};
