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

import {socket, socket_push, socket_init} from "./socket"

var incunabula = {};

incunabula.bind_review_buttons = function () {
    $(".incunabula-review-button").on("click", function () {
        var url = $(this).attr("data-url");
        var nextstatus = $(this).attr("data-next");
        // gotta steal a csrf token ma man
        var inputs = $("input[name='_csrf_token']");
        var csrf_token = $(inputs[0]).val();
        var json = {"newstatus":   nextstatus,
                    "_csrf_token": csrf_token};
    $.post(url,
           json,
           function (resp) {
               // console.log("got response");
               // console.log(resp);
           });
    })
};

incunabula.setup_modals = function() {
    // for each bound modal form we need to bind the submit button
    var modals = $(".incunabula-show");
    $(modals).each(function () {
        if ($(this).hasClass("incunabula-bound")) {
            var inputbinding = $(this).attr("data-fieldbinding");
            var button = $("[data-fieldtarget='" + inputbinding + "'] button")
            var topic  = $("[data-fieldtarget='" + inputbinding + "']")
                .attr("topic");
            $(button).on('click', function () {
                var val = $("[data-fieldtarget='" + inputbinding
                            + "'] input").val();
                socket_push(topic, {field: val});
                // no, even I do not think this is elegant
                $(this).
                    parent().
                    parent().
                    parent().
                    parent().
                    parent().
                    modal("hide");
            });
        };
    });

    // for bound field modals we need to copy the value
    // that we are editing over to the modal dialog box
    // we do this at open dialog time because the value we wish
    // to edit is - by definition - coming via a channel and won't be here
    // at load time
    $(".incunabula-show").on('click', function () {
        var modalclass = $(this).attr("modal");
        if ($(this).hasClass("incunabula-bound")) {
            var inputbinding = $(this).attr("data-fieldbinding");
            var input  = $("[data-fieldtarget='" + inputbinding + "'] input")
            var source = $("[data-fieldsource='" + inputbinding + "']");
            input.val(source.html());
        };

        $("." + modalclass).modal("show");
    })
}
incunabula.setup_modals();

//
// Make the menus and stuff work
//

$(".menu .item").tab();

//
// Resize the text area box
//

if ($("#incunabula-eiderdown").length) {

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
        var topic = $("#book-save_edits").attr("topic");
        socket_push(topic, {commit_title: title,
                            commit_msg:   msg,
                            data:         data,
                            tag_bump:     tag_bump});
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

//
// set the tabs menus up
//
if ($(".tabular.menu").length) {
    if (window.location.hash == "#images") {
        $(".active.item").removeClass("active");
        $("a[data-tab='images']").addClass("active");
        $(".active.segment").removeClass("active");
        $("div[data-tab='images']").addClass("active");
    } else if (window.location.hash == "#chaff") {
        $(".active.item").removeClass("active");
        $("a[data-tab='chaff']").addClass("active");
        $(".active.segment").removeClass("active");
        $("div[data-tab='chaff']").addClass("active");
    } else if (window.location.hash == "#reviewing") {
        $(".active.item").removeClass("active");
        $("a[data-tab='reviewing']").addClass("active");
        $(".active.segment").removeClass("active");
        $("div[data-tab='reviewing']").addClass("active");
    }
}

//
// handle chapter order
//

incunabula.chapters = {};
incunabula.no_of_chapters = 0;

// get the chapters as json and stash them

incunabula.get_chapters_fn = function () {
    if ($(".incunabula-show-order-button").length) {

        var book = $(".incunabula-show-order-button").attr("data-book");
        var url = "/books/" + book + "/chapter_order";

        // get the chapter order
        $.getJSON(url, function (data) {

            incunabula.chapters = data["chapters"];
            incunabula.no_of_chapters = Object.keys(incunabula.chapters).length;

            $(".incunabula-show-order-button")
            if (incunabula.no_of_chapters > 1) {
                $(".incunabula-show-order-button").on('click', function () {

                    var submit_fn = function () {

                        // there are three other forms on this page
                        // steal a _csrf token affa wan of them
                        var url = "/books/" + book + "/chapter_order";
                        var inputs = $("input[name='_csrf_token']");
                        var csrf_token = $(inputs[0]).val();
                        var json = {"_csrf_token": csrf_token,
                                    "chapters":    incunabula.chapters};
                        $.post(url,
                               json,
                               function (resp) {
                                   $(".incunabula-chapter-order").modal("hide");
                               });
                    };
                    $(".incunabula-order-submit").on('click', submit_fn);
                    $(".incunabula-chapter-order-table").on('click',
                                                            incunabula.on_reorder_click_fn);
                    incunabula.draw_chapters_table_fn();
                });
                $(".incunabula-show-order-button").css("display", "inline-block");

            };
        });
    };
};

incunabula.get_chapters_fn();

// define some functions

incunabula.debug = function () {
    $.each(incunabula.chapters, function (c) {
        console.log(incunabula.chapters[c].chapter_title);
    });
};

incunabula.on_reorder_click_fn = function (event) {

    var direction = $(event.target).attr("data-direction");
    var row = $(event.target).attr("data-row");

    incunabula.reorder_chapters_fn(direction, row);
    incunabula.draw_chapters_table_fn();
    };

incunabula.draw_chapters_table_fn = function () {

    var row = "";
    var html = ""

    for (var i = 0; i < incunabula.no_of_chapters; i++) {
        row += "<tr>"
            + "<td>"
            + "<i class='arrow up icon'"
            + "data-direction='up' data-row='" + String(i) + "'></i>"
            + "<i class='arrow down icon'"
            + "data-direction='down' data-row='" + String(i) + "'></i>"
            + "</td>"
            + "<td>" + incunabula.chapters[i].chapter_title + "</td>"
            + "</tr>";
    };

    html = "<table class='ui striped table'>"
        + row
        + "</table>";
    $(".incunabula-chapter-order-table").html(html);
};

incunabula.reorder_chapters_fn = function (direction, row) {

    var tmp;
    var swap;
    var row_index = parseInt(row, 10);

    tmp = incunabula.chapters[row_index];
    if (direction == "up") {
        swap = row_index - 1;
    } else {
        swap = row_index + 1;
    };
    if (swap < 0) {
        swap = incunabula.no_of_chapters - 1;
    } else if (swap >= incunabula.no_of_chapters) {
        swap = 0;
    };

    incunabula.chapters[row_index] = incunabula.chapters[swap];
    incunabula.chapters[swap] = tmp;
};

//
// set up delete buttons for users
//

incunabula.bind_delete_icons = function () {
    $("[data-post]").on('click', function () {
        var url = $(this).attr("data-post");
        // gotta steal a CSRF token
        var inputs = $("input[name='_csrf_token']");
        var csrf_token = $(inputs[0]).val();
        var json = {"_csrf_token": csrf_token}
        $.post(url,
               json,
               function (resp) {
               });
    });
};

//
// set the focus (if possible)
//
$(".incunabula-focus").focus()

//
// now setup the socket to have access to what we have defined
//
socket_init(incunabula);

//
// The link builder
//

$(".incunabula-link-maker").on("click", function (event) {
    event.preventDefault();
    var url = $(".incunabula-link-url").val();
    var text = $(".incunabula-link-text").val();
    var link = "&lt;a scr='" + url + "'&gt;" + text + "&lt;/a&gt;"
    $(".incunabula-show-link").html(link);
    $(".incunabula-hidden").css("display", "inline");
});
