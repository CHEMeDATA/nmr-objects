#!/usr/bin/env zsh

# Define source paths
SRC_DIR="src"

DIST_DIR="dist"
rm -r "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Here will loop OBJ over different reader, writer, viewer
SCRATCH_DIR="scratch"
BODYStatement="extraMethodsStatements"
echo ""
echo "**************************************************** "
echo "**************************************************** "
echo "**************************************************** "
echo "**************************************************** "
echo "****** Start scripts/transform.zsh "


# Define types and their corresponding files
for TYPE in import export viewer; do
    FILE_IN_SCRATCH="$SCRATCH_DIR/$TYPE.txt"
    echo "** Processing <$TYPE> objects from $FILE_IN_SCRATCH **"
    # Skip if file does not exist or is empty
    [[ ! -s "$FILE_IN_SCRATCH" ]] && continue
    
    
    while IFS= read -r OBJ || [[ -n "$OBJ" ]]; do
        [[ -z "$OBJ" ]] && continue
        [[ "$OBJ" == '//'** || "$OBJ" == \#* ]] && continue
        
        echo "    Processing <$TYPE> object: $OBJ"
        
		# search the ./extraMethodsStatements.json file
		# OBJ_GIT_POINTER="https://chemedata.github.io/$OBJ/$BODYStatement.txt"
		OBJ_GIT_POINTER="https://raw.githubusercontent.com/CHEMeDATA/$OBJ/main"
		OBJ_File="$SRC_DIR/$OBJ"
		mkdir -p "$SRC_DIR/$OBJ"
		wget -q -O "$OBJ_File/$BODYStatement.json" "$OBJ_GIT_POINTER/$BODYStatement.json"
		if [ ! -s "$OBJ_File/$BODYStatement.json" ]; then
		echo "-----failerd to get $OBJ_GIT_POINTER/$BODYStatement.json"
			continue
		fi

		jq -r '.listObject[] | "\(.object) \(.type)"' "$OBJ_File/$BODYStatement.json" > "$OBJ_File/$BODYStatement.txt"
		
		echo "  OK to have error here if <viewer>"
		jq -r '.jsLibrary[]' "$OBJ_File/$BODYStatement.json" | while IFS= read -r lib; do
			echo "         Processing library: $lib"
			if [[ ! -f "$DIST_DIR/$lib" ]]; then
				wget -q -O "$DIST_DIR/$lib" "$OBJ_GIT_POINTER/src/$lib"
			else
				echo "$lib already exists in $DIST_DIR, skipping."
			fi

			# add comment in library
			editor=$(jq -r '.creatorParam.editor' "$OBJ_File/$BODYStatement.json")
			version=$(jq -r '.creatorParam.version' "$OBJ_File/$BODYStatement.json")
			source=$(jq -r '.creatorParam.source' "$OBJ_File/$BODYStatement.json")
			id=$(jq -r '.creatorParam.id' "$OBJ_File/$BODYStatement.json")
			result="Editor${editor}_Version${version}_Source${source}_ID${id}"
			echo "// for $result" >> "$DIST_DIR/$lib"

		done
		echo "  jq end"

		if [ -s "$OBJ_File/$BODYStatement.txt" ]; then
			while IFS=' ' read -r OBJECT_STATEMENTS TYPE_STATEMENT 
			do
				if [[ "$TYPE_STATEMENT" != "$TYPE" ]]; then
					continue
				fi
				if [[ "$TYPE_STATEMENT" == "viewer" ]]; then
					continue
				fi
				# Skip empty line
				[[ -z "$OBJECT_STATEMENTS" ]] && continue
		  		# Skip comment lines starting with // or #
				[[ "$OBJECT_STATEMENTS" == '//'** ]] && continue

				echo "                          Object : $OBJECT_STATEMENTS"

				# Skip comment lines (// at the start)

				# continue if not one of the three types
				[[ "$TYPE_STATEMENT" != "import" && "$TYPE_STATEMENT" != "export" && "$TYPE_STATEMENT" != "viewer" ]] && continue

				wget -q -O "$OBJ_File/${TYPE_STATEMENT}Statements.js" "$OBJ_GIT_POINTER/src/${TYPE_STATEMENT}Statements.js"
				wget -q -O "$OBJ_File/${TYPE_STATEMENT}Method.js" "$OBJ_GIT_POINTER/src/${TYPE_STATEMENT}Method.js"

				if [ ! -s "$OBJ_File/${TYPE_STATEMENT}Statements.js" ]; then
					echo "ERROR : File $OBJ_File/${TYPE_STATEMENT}Statements.js missing or empty"
					echo "ERROR $OBJ_GIT_POINTER/src/${TYPE_STATEMENT}Statements.js"
					continue;
				fi
				if [ ! -s "$OBJ_File/${TYPE_STATEMENT}Method.js" ]; then
					echo "ERROR : File $OBJ_File/${TYPE_STATEMENT}Method.js missing or empty"
					echo "ERROR $OBJ_GIT_POINTER/src/${TYPE_STATEMENT}Method.js"
					continue;
				fi

				if [ ! -s "$SRC_DIR/$OBJECT_STATEMENTS.js" ]; then
					echo "ERROR : File $SRC_DIR/$OBJECT_STATEMENTS.txt missing or empty : the target class does not exists"
					continue;
				fi

				if [ ! -s "$DIST_DIR/$OBJECT_STATEMENTS.js" ]; then
					echo "             Copy $DIST_DIR/$OBJECT_STATEMENTS.js in dist folder"

					cp "$SRC_DIR/$OBJECT_STATEMENTS.js" "$DIST_DIR/$OBJECT_STATEMENTS.js"
				fi
				

				# Build dist/nmrSpectrumObject.js
				echo ""
				echo "             Insertions of $SRC_DIR/$OBJ/${TYPE_STATEMENT}Statements.js"
				echo "                       and $SRC_DIR/$OBJ/${TYPE_STATEMENT}Method.js"
				echo "                        in $DIST_DIR/$OBJECT_STATEMENTS.js"
				echo ""

				cat "${DIST_DIR}/${OBJECT_STATEMENTS}.js" \
				  | sed '/\/\/ AUTOMATIC IMPORT INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/${TYPE_STATEMENT}Statements.js" \
				  | sed '/\/\/ AUTOMATIC METHOD INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/${TYPE_STATEMENT}Method.js" \
				  > "${DIST_DIR}/${OBJECT_STATEMENTS}tmp.js"
				mv "${DIST_DIR}/${OBJECT_STATEMENTS}tmp.js" "${DIST_DIR}/${OBJECT_STATEMENTS}.js"

			done < "$OBJ_File/$BODYStatement.txt"

		else
			echo "❌ Download of file $OBJ_GIT_POINTER failed (or file is empty) for object : $OBJ"
		fi

	done < "$FILE_IN_SCRATCH"

done

echo