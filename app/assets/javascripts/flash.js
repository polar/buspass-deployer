/**
 * This is some javascript for dealing with the Flash messages at the top of our layouts.
 *
 * @param type
 * @param msg
 */
function setFlash(type, msg) {
    var closeBtn = "<button type='button' class='close' data-dismiss='alert' href='#'>×</button>";
    if (type == "error") {
        if (!$("#flash_error")[0]) {
            $("#notices").html("<div id='flash_error' class='alert alert-error'></div>");
        }
        $("#flash_error").html(closeBtn + msg);
    }
    if (type == "notice") {
        if (!$("#flash_notice")[0]) {
            $("#notices").html("<div id='flash_notice' class='alert alert-success'></div>");
        }
        $("#flash_notice").html(closeBtn + msg);
    }
    if (type == "alert") {
        if (!$("#flash_alert")[0]) {
            $("#notices").html("<div id='flash_alert' class='alert alert-error'></div>");
        }
        $("#flash_alert").html(closeBtn + msg);
    }
}
function clearFlash() {
    $("#notices").html("<div id='flash_inert' class='alert'>&nbsp;</div>");
}
