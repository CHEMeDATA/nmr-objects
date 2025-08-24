#!/usr/bin/env zsh
ORG="CHEMeDATA"
SRC_DIR="scratch"
rm -r $SRC_DIR
# Get list of repo names (public repos) from GitHub API
REPOS_RAW=$(curl -s "https://api.github.com/orgs/$ORG/repos?per_page=100" | jq -r '.[].name')
REPOS=("${(@f)REPOS_RAW}")  # Split on newlines only

for REPO in $REPOS; do
    # Skip if the repo name contains a "." or does not contain exactly one "-"
    if [[ "$REPO" == *.* ]] || [[ $(tr -cd '-' <<< "$REPO" | wc -c) -ne 1 ]]; then
        echo "Skip $REPO : invalid repository name format"
        continue
    fi

    # Construct the raw file URL
    BODYStatement="extraMethodsStatements"
    REPO_URL="https://raw.githubusercontent.com/$ORG/$REPO/main/$BODYStatement.json"
   
    # Local path
    FILE_PATH="$SRC_DIR/$REPO/$BODYStatement.txt"
    FILE_PATH_JSON="$SRC_DIR/$REPO/$BODYStatement.json"
    mkdir -p "$SRC_DIR/$REPO"
    wget -q -O "$FILE_PATH_JSON" "$REPO_URL"
		
	jq -r '.listObject[] | "\(.object) \(.type)"' "$FILE_PATH_JSON" > "$FILE_PATH"
		

    # Download quietly

    if [ -s "$FILE_PATH" ]; then
        # Split the repo name at the first "-"
        OBJ_NAME="${REPO%%-*}"      # before "-"
        OBJ_TYPE="${REPO#*-}"       # after "-"
        
        echo "For repository '$REPO' ($OBJ_NAME,$OBJ_TYPE), Found a $BODYStatement.json:"
        
        # Read the file line by line
        while IFS=' ' read -r OBJECT_STATEMENTS TYPE_STATEMENT || [[ -n "$OBJECT_STATEMENTS" ]]; do
            [[ -z "$OBJECT_STATEMENTS" ]] && continue
            [[ "$OBJECT_STATEMENTS" == '//'** || "$OBJECT_STATEMENTS" == \#* ]] && continue
            [[ "$TYPE_STATEMENT" != "import" && "$TYPE_STATEMENT" != "export" && "$TYPE_STATEMENT" != "viewer" ]] && continue
            
            echo "  Entry Object='$OBJECT_STATEMENTS', Type='$TYPE_STATEMENT'"
            
            if [[ "$TYPE_STATEMENT" == "import" ]]; then
                echo "$OBJ_NAME-reader" >> "$SRC_DIR/import.txt"
            fi
			if [[ "$TYPE_STATEMENT" == "export" ]]; then
                echo "$OBJ_NAME-writer" >> "$SRC_DIR/export.txt"
            fi
			if [[ "$TYPE_STATEMENT" == "viewer" ]]; then
                echo "$OBJ_NAME-viewer" >> "$SRC_DIR/viewer.txt"
            fi
        done < "$FILE_PATH"
    else
        rm -r "$SRC_DIR/$REPO"
        echo "Skip $REPO : No $BODYStatement.txt file"
    fi
done

for TYPE in import export viewer; do
    FILE="$SRC_DIR/$TYPE.txt"
	echo "Remove duplicates from $FILE"
    [[ -f "$FILE" ]] || continue
    awk '!seen[$0]++' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
done
