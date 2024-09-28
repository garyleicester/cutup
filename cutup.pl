#!/usr/bin/perl

use strict;
use warnings;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use LWP::Simple qw(get);
use List::Util qw(shuffle);
use Encode qw(decode encode);
use JSON;
use utf8;

# Define RSS feeds for news sources
my @rss_feeds = (
    'https://www.theguardian.com/uk/culture/rss',
    'https://www.theguardian.com/uk/lifeandstyle/rss',
    'https://www.dailymail.co.uk/articles.rss',
);

# Stop punctuation for splitting tokens further
my $stop_punctuation = qr/[.!?;:"”\]\)]/;

# Function to tokenize the input text using golden ratio-like logic
sub tokenize_golden_ratio {
    my ($text) = @_;
    
    $text = decode('UTF-8', $text);  # Ensure the input text is decoded properly
    my @words = split(/\s+/, $text);  # Split input text by spaces
    my @tokens;
    my @token_sizes = (10, 7, 3, 1);  # Fibonacci-like sequence

    while (@words) {
        foreach my $size (@token_sizes) {
            last if scalar(@words) == 0;  # Stop when no words are left
            my $chunk_size = ($size > scalar(@words)) ? scalar(@words) : $size;
            my $token = join(' ', splice(@words, 0, $chunk_size));
            push @tokens, $token;
        }
    }

    my @final_tokens;
    foreach my $token (@tokens) {
        if ($token =~ $stop_punctuation) {
            my @sub_tokens = split(/$stop_punctuation/, $token);
            push @final_tokens, @sub_tokens;
        } else {
            push @final_tokens, $token;
        }
    }

    return @final_tokens;
}

# Function to fetch and clean a random news description
sub fetch_random_news_description {
    my @all_descriptions;

    foreach my $feed (@rss_feeds) {
        my $content = get($feed);
        if ($content) {
            my @descriptions = ($content =~ /<description>(.+?)<\/description>/g);

            grep(s/&lt;.+?&gt;/ /g, @descriptions);
            grep(s/&amp;[^;]+?;/ /g, @descriptions);
            grep(s/<[^>]*>//g, @descriptions);
            grep(s/Continue reading.+?$//, @descriptions);
            @descriptions = grep { $_ ne '' } @descriptions;
            push @all_descriptions, @descriptions;
        }
    }

    @all_descriptions = shuffle(@all_descriptions);
    return $all_descriptions[0] || 'No description available.';
}

# Handle the AJAX request
if (param('ajax')) {
    my $action = param('action') || '';

    if ($action eq 'tokenize') {
        my $input_text = param('input_text');
        my @tokens = tokenize_golden_ratio($input_text);
        print header(-type => 'application/json', -charset => 'UTF-8');
        print encode_json(\@tokens);
        exit;
    }
    
    if ($action eq 'fetch_news') {
        my $news_description = fetch_random_news_description();
        print header(-type => 'application/json', -charset => 'UTF-8');
        print encode_json({ description => $news_description });
        exit;
    }
}

# CGI start (HTML page rendering)
print header(-type => 'text/html', -charset => 'UTF-8');
print start_html(
    -title => 'Cut Up',
    -meta => { 
        charset => 'UTF-8',
        viewport => 'width=device-width, initial-scale=1.0',
    },
    -style => {
        -code => '
            body {
                font-family: Arial, sans-serif;
                padding: 0;
                margin: 10;
                box-sizing: border-box;
            }
            .container {
                display: flex;
                flex-direction: column;
                padding: 10px;
                width: 100%;
                max-width: 100%;
                box-sizing: border-box;
            }
            .section {
                border: 2px solid #000;
                border-radius: 10px;
                padding: 20px;
                margin-bottom: 20px;
                position: relative;
                width: 100%;
                box-sizing: border-box;
                background-color: #fff;
            }
            .legend {
                position: absolute;
                top: -10px;
                left: 20px;
                background-color: #fff;
                padding: 0 10px;
                font-weight: bold;
            }
            .rearrange-area {
                background-color: #f9f9f9;
                min-height: 0px;
            }
            .word {
                background-color: #f2f2f2;
                border: 1px solid #000;
                padding: 8px;
                margin: 4px;
                display: inline-block;
                cursor: move;
                user-select: none;
                text-align: center;
                position: relative;
                outline: none;
                width: auto;
                max-width: 100%;
                word-wrap: break-word;
                white-space: normal;
                overflow-wrap: break-word;
            }
            .token-text {
                display: inline-block;
                padding-right: 0px;
            }
            .delete-circle, .edit-circle {
                position: absolute;
                width: 14px;
                height: 14px;
                background-color: #f2f2f2;
                color: black;
                border: 1px solid #000;
                border-radius: 50%;
                text-align: center;
                line-height: 12px;
                cursor: pointer;
                font-size: 12px;
                font-weight: bold;
            }
            .delete-circle {
                top: -7px;
                right: -7px;
            }
            .edit-circle {
                bottom: -7px;
                right: -7px;
            }
            .line {
                border: 2px solid #000;
                min-height: 50px;
                padding: 8px;
                margin: 10px 0;
                background-color: white;
                position: relative;
            }
            .delete-line {
                position: absolute;
                top: -10px;
                right: -10px;
                background-color: black;
                color: white;
                width: 20px;
                height: 20px;
                border-radius: 50%;
                text-align: center;
                line-height: 18px;
                cursor: pointer;
            }
            .input-area textarea {
                border: 2px solid #000;
                width: 100%;
                padding: 8px;
                font-size: 16px;
                box-sizing: border-box;
            }
            .button-container {
                display: flex;
                justify-content: space-between;
                gap: 10px;
                margin-top: 10px;
            }
            .button-container button, .button-container input[type="submit"] {
                flex: 1;
                padding: 10px;
                font-size: 16px;
                cursor: pointer;
                box-sizing: border-box;
                position: relative;
                display: flex;
                align-items: center;
                justify-content: center;
                border: 0px solid #000;
                color: white;
                background-color: black;
            }
            .button-container button:disabled {
                background-color: #666;
                color: #ccc;
                cursor: not-allowed;
                opacity: 0.6;
            }
            .spinner {
                display: none;
                position: absolute;
                width: 16px;
                height: 16px;
                border: 2px solid #f3f3f3;
                border-top: 2px solid #000;
                border-right: 2px solid #888;
                border-bottom: 2px solid #ccc;
                border-radius: 50%;
                animation: spin 0.8s linear infinite;
                top: 25%;
                left: 50%;
                transform: translate(-50%, -50%);
            }
            .button-container button:active, .button-container input[type="submit"]:active {
                transform: translateY(1px);  /* Move the button down slightly */
                box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);  /* Slight shadow */
                background-color: #333; /* Slightly darker background */
            }

            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            .modal {
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                background: rgba(0, 0, 0, 0.5);
                display: none;
                justify-content: center;
                align-items: center;
                z-index: 9999;
            }
            .modal.active {
                display: flex;
            }
            .modal-content {
                background-color: #f2f2f2;
                border: 1px solid #000;
                padding: 8px;
                margin: 4px;
                display: inline-block;
                position: relative;
                text-align: center;
                border-radius: 0px;
            }
            .close-modal, .submit-modal {
                position: absolute;
                width: 14px;
                height: 14px;
                background-color: #f2f2f2;
                color: black;
                border: 1px solid #000;
                border-radius: 50%;
                text-align: center;
                line-height: 12px;
                cursor: pointer;
                font-size: 12px;
                font-weight: bold;
            }
            .close-modal {
                top: -7px;
                right: -7px;
            }
            .submit-modal {
                bottom: -7px;
                right: -7px;
            }
            #modalToken {
                outline: none;
                border: none;
                background-color: transparent;
                font-size: inherit;
                width: 100%;
                text-align: center;
                padding: 0;
            }
            .content-blur {
                filter: blur(8px);
            }
        ',
    },
    -script => [
        { -src => 'https://code.jquery.com/jquery-3.6.0.min.js' },
        { -src => 'https://code.jquery.com/ui/1.12.1/jquery-ui.js' },
        { -src => './jquery.ui.touch-punch.min.js' }  # Assuming it's locally hosted
    ]
);

# HTML structure
print "<div class='container' id='mainContent'>";

# Rearrange area
print "<div class='section'>";
print "<div class='legend'>Arrange</div>";
print "<div class='rearrange-area'>";
print "<div class='line-container'>";
print "<div class='line'><div class='delete-line'>x</div></div>";  # Initial line
print "</div>";
print "<div class='button-container'>";
print "<button id='addLineBtn'>Line</button>";
print "<button id='downloadBtn'>Export</button>";
print "</div>";
print "</div>";
print "</div>";

# Holding area for original tokens
print "<div class='section'>";
print "<div class='legend'>Cut Up</div>";
print "<div class='holding-area'>";
print "<div class='paragraph' id='sortableParagraph'></div>";
print "<div class='button-container'>";
print "<button type='button' id='reshuffleBtn'>Shuffle</button>"; # Reshuffle button
print "<button type='button' id='clearCutUpBtn'>Clear</button>"; # Clear cut up area button
print "<button type='button' id='decimateBtn'>Decimate</button>"; # Decimate button
print "</div>";
print "</div>";
print "</div>";

# Input area for new text
print "<div class='section'>";
print "<div class='legend'>Add</div>";
print "<div class='input-area'>";
print "<form id='inputForm' method='post'>";
print "<textarea id='input_text' name='input_text' rows='6' placeholder='Enter text to cut up and rearrange here ...'></textarea><br>";
print "<div class='button-container'>";
print "<input type='submit' value='Add'>";
print "<button id='fetchNewsBtn'>Grab<span class='spinner'></span></button>";
print "<button id='clearInputBtn'>Clear</button>"; # Clear button for Add textarea
print "</div>";
print "</form>";
print "</div>";
print "</div>";

print "</div>";  # End container

# Modal for editing
print <<'END_HTML';
<div class="modal" id="editModal">
    <div class="modal-content">
        <div class="close-modal" id="closeModal">x</div>
        <div id="modalToken" contenteditable="true"></div>
        <div class="submit-modal" id="submitModalEdit">e</div>
    </div>
</div>
END_HTML

print end_html();

# JavaScript section
print <<'END_JS';
<script>
$(function() {
    // Make tokens draggable
    function makeTokensDraggable() {
        $(".word").draggable({
            connectToSortable: ".line",
            helper: "clone",
            revert: "invalid",
        });
    }

    makeTokensDraggable();

    // Make paragraph sortable
    $("#sortableParagraph").sortable({
        connectWith: ".line",
        items: ".word",
        placeholder: "word-placeholder",
        forcePlaceholderSize: true
    }).disableSelection();

    // Make lines sortable
    $(".line").sortable({
        connectWith: "#sortableParagraph, .line",
        items: ".word",
        placeholder: "word-placeholder",
        forcePlaceholderSize: true
    }).disableSelection();

    // Add new line
    $("#addLineBtn").click(function() {
        var newLine = $("<div>").addClass("line").append("<div class='delete-line'>x</div>");
        $(".line-container").append(newLine);
        newLine.sortable({
            connectWith: "#sortableParagraph, .line",
            items: ".word",
            placeholder: "word-placeholder",
            forcePlaceholderSize: true
        }).disableSelection();
    });

    // Delete line button functionality
    $(document).on('click', '.delete-line', function() {
        $(this).closest('.line').remove();
    });

    let currentEditToken;

    // Show modal for editing
    $(document).on('click', '.edit-circle', function(event) {
        event.stopPropagation();
        currentEditToken = $(this).siblings('.token-text');
        const tokenText = currentEditToken.text();
        $("#modalToken").text(tokenText);
        $("#editModal").addClass("active");
        $("#mainContent").addClass("content-blur");
        $("#modalToken").focus();
    });

    // Close modal without saving
    $("#closeModal").click(function() {
        $("#editModal").removeClass("active");
        $("#mainContent").removeClass("content-blur");
    });

    // Function to reset inline styles after editing
    function resetInlineStyles(token) {
        token.css({
            width: '',
            height: ''
        });
    }

    // Submit modal edit
    function submitModalEdit() {
        const newText = $("#modalToken").text();
        const parentWord = currentEditToken.closest('.word');
        const deleteCircle = parentWord.find('.delete-circle');
        const editCircle = parentWord.find('.edit-circle');

        const newTokenHTML = "<span class='token-text'>" + newText + "</span>";
        parentWord.html(newTokenHTML);
        parentWord.append(deleteCircle);
        parentWord.append(editCircle);

        currentEditToken = parentWord.find('.token-text');
        resetInlineStyles(parentWord);

        $("#editModal").removeClass("active");
        $("#mainContent").removeClass("content-blur");
    }

    $("#submitModalEdit").click(function() {
        submitModalEdit();
    });

    $(document).on('keydown', function(e) {
        if ($("#editModal").hasClass("active") && e.key === "Enter") {
            e.preventDefault();
            submitModalEdit();
        }
    });

    // Export rearranged text
    $("#downloadBtn").click(function() {
        var exportedLines = [];
        $(".line").each(function() {
            var lineWords = [];
            $(this).find(".token-text").each(function() {
                lineWords.push($(this).text());
            });
            exportedLines.push(lineWords.join(' '));
        });
    
        // Create a timestamp
        var timestamp = new Date().toISOString().replace(/[:\-T]/g, '').split('.')[0]; // YYYYMMDDHHMMSS format

        // Generate the blob and filename
        var blob = new Blob([exportedLines.join('\n')], { type: 'text/plain' });
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = 'cutup_' + timestamp + '.txt';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    });


    // Reshuffle functionality
    $("#reshuffleBtn").click(function() {
        var tokens = $(".paragraph .word").toArray();
        tokens = tokens.sort(function() { return 0.5 - Math.random(); });

        $(".paragraph").empty();
        $(tokens).each(function() {
            $(".paragraph").append($(this));
        });
    });

    // Clear Cut Up area
    $("#clearCutUpBtn").click(function() {
        $(".paragraph").empty();
    });

    // Decimate Cut Up area
    $("#decimateBtn").click(function() {
        $(".paragraph .word").each(function(index) {
            if (index % 10 === 0) {
                $(this).remove();
            }
        });
    });

    // Clear input textarea
    $("#clearInputBtn").click(function(event) {
        event.preventDefault();
        $("#input_text").val('');
    });

    // Handle form submission
    $("#inputForm").submit(function(event) {
        event.preventDefault();
        var newText = $("#input_text").val();

        $.ajax({
            url: '',
            type: 'POST',
            data: {
                ajax: 1,
                action: 'tokenize',
                input_text: newText
            },
            success: function(data) {
                data.forEach(function(token) {
                    $("#sortableParagraph").append("<span class='word'><span class='token-text'>" + token + "</span><span class='delete-circle'>x</span><span class='edit-circle'>e</span></span>");
                });

                makeTokensDraggable();

                // Simulate a click on the reshuffle button
                $("#reshuffleBtn").click();
            },
            error: function(xhr, status, error) {
                console.log("Error during AJAX request:", status, error);
            }
        });

        $("#input_text").val('');
    });

    // Handle fetching news description
    $("#fetchNewsBtn").click(function(event) {
        event.preventDefault();
        $("#fetchNewsBtn").prop('disabled', true);
        $(".spinner").show();

        $("#input_text").val('');

        $.ajax({
            url: '',
            type: 'POST',
            data: {
                ajax: 1,
                action: 'fetch_news'
            },
            success: function(data) {
                $("#input_text").val(data.description);
            },
            error: function(xhr, status, error) {
                console.log("Error fetching news:", status, error);
            },
            complete: function() {
                $("#fetchNewsBtn").prop('disabled', false);
                $(".spinner").hide();
            }
        });
    });

    // Handle the deletion of tokens
    $(document).on('click', '.delete-circle', function(event) {
        event.stopPropagation();
        $(this).parent('.word').remove();
    });

    // Ensure that edited tokens in the arrange area resize correctly
    $(document).on('blur', '.token-text', function() {
        const parentWord = $(this).closest('.word');
        resetInlineStyles(parentWord);
    });
});
</script>
END_JS
