function libgen
    if test (count $argv) -ne 1
        echo "Usage: libgen <URL>"
        return 1
    end

    # Base settings
    set base_url "https://libgen.st"
    set base_path "/mnt/SECONDARY/downloads/.tmp/"

    # Get URL and extract the md5 value (assumes URL contains '?md5=')
    set page_url $argv[1]
    set md5 (string lower (echo $page_url | awk -F'?md5=' '{print $NF}'))

    # Fetch the HTML content from the page
    set html_content (curl -s $page_url)

    # Use xmllint with XPath to extract title and authors
    set title (echo "$html_content" | xmllint --html --xpath "string(//td[contains(., 'Title:')]/following::b[1])" - 2>/dev/null | string trim)
    set authors (echo "$html_content" | xmllint --html --xpath "string(//td[contains(., 'Author(s):')]/following::b[1])" - 2>/dev/null | string trim)

    # Extract the href attribute of the <a> tag containing "repository_torrent" and ".torrent"
    set href (echo "$html_content" | xmllint --html --xpath "string(//a[contains(@href, 'repository_torrent') and contains(@href, '.torrent')]/@href)" - 2>/dev/null)
    # Remove the leading "./" and prepend the base_url
    set link_path (string sub -s 3 "$href")
    set link "$base_url$link_path"

    echo "Torrent link: $link"

    # Determine the torrent filename and full path
    set torrent_filename (basename $link)
    set torrent_file_path "$base_path$torrent_filename"

    # Download the torrent file with aria2c
    aria2c --follow-torrent=false $link

    # Show files in the torrent and capture output
    set result (aria2c --show-files $torrent_file_path)

    # Loop through output lines to find the file with the md5 string
    set file_index ""
    set found 0
    for line in (echo "$result" | string split "\n")
        if echo "$line" | grep -qi "$md5"
            set file_index (echo "$line" | awk -F'|' '{print $1}' | xargs)
            echo "Selected file index: $file_index - " (echo "$line" | awk -F'|' '{print $2}' | xargs)
            set found 1
            break
        end
    end

    if test $found -eq 0
        echo "File with the specified md5 not found"
        return 1
    end

    # Download the selected file from the torrent
    aria2c --select-file "$file_index" --seed-time=0 "$torrent_file_path"

    # Extract the number from the torrent filename (e.g. from "r_123456.torrent")
    set num (echo $torrent_filename | sed -E 's/r_([0-9]+)\.torrent/\1/')

    ##########################################################################
    # Process authors: split and abbreviate (only process the first 2 authors)
    ##########################################################################
    # Try splitting on comma first; if not, then on semicolon.
    set author_list (string split ", " "$authors")
    if test (count $author_list) -eq 1
        set author_list (string split ";" "$authors")
    end

    # Only use the first 2 authors
    if test (count $author_list) -ge 2
        set selected_authors $author_list[1] $author_list[2]
    else
        set selected_authors $author_list[1]
    end

    set abbr_authors ""
    for auth in $selected_authors
        set auth (string trim "$auth")
        set words (string split " " "$auth")
        set n (count $words)
        if test $n -gt 1
            set abbr ""
            for i in (seq 1 (math $n - 1))
                set token $words[$i]
                # Get the first character of the token
                set initial (string sub -s 1 -l 1 "$token")
                set abbr "$abbr$initial."
            end
            set abbr "$abbr$words[$n]"
        else
            set abbr "$auth"
        end

        if test -z "$abbr_authors"
            set abbr_authors "$abbr"
        else
            set abbr_authors "$abbr_authors, $abbr"
        end
    end

    # Create the new filename as "{Title} [AbbrAuthor1, AbbrAuthor2].pdf"
    set new_filename "$title [$abbr_authors].pdf"

    # Move the downloaded file to ~/Downloads with the new filename
    set downloaded_file "$base_path$num/$md5"
    set destination "$HOME/Downloads/$new_filename"
    mv "$downloaded_file" "$destination"

    # Clean up temporary files and directories
    rm -rf "$base_path$num"
    rm "$torrent_file_path"
    rm "$base_path$num.aria2"

    echo "Downloaded and moved: $destination"
end
