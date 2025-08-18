#!/usr/bin/env zsh

# Define source paths
SRC_DIR="src"

DIST_DIR="dist"
rm -r "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Here will loop OBJ over different reader, writer, viewer
SRATCH_DIR="scratch"

# Define types and their corresponding files
for TYPE in import export viewer; do
    FILE_IN_SCRATCH="$SRATCH_DIR/$TYPE.txt"
    
    # Skip if file does not exist or is empty
    [[ ! -s "$FILE_IN_SCRATCH" ]] && continue
    
    echo "** Processing $TYPE objects from $FILE_IN_SCRATCH **"
    
    while IFS= read -r OBJ || [[ -n "$OBJ" ]]; do
        [[ -z "$OBJ" ]] && continue
        [[ "$OBJ" == '//'** || "$OBJ" == \#* ]] && continue
        
        echo "Processing $TYPE object: $OBJ"
        
		# OBJ_GIT_POINTER="https://chemedata.github.io/$OBJ/extraMethodsStatements.txt"
		OBJ_GIT_POINTER="https://raw.githubusercontent.com/CHEMeDATA/$OBJ/main"
		OBJ_File="$SRC_DIR/$OBJ"
		mkdir -p "$SRC_DIR/$OBJ"
		wget -q -O "$OBJ_File/extraMethodsStatements.json" "$OBJ_GIT_POINTER/extraMethodsStatements.json"
		if [ ! -s "$OBJ_File/extraMethodsStatements.json" ]; then
		    continue
		fi
		jq -r '.listObject[] | "\(.object) \(.type)"' "$OBJ_File/extraMethodsStatements.json" > "$OBJ_File/extraMethodsStatements.txt"
		
		jq -r '.jsLibrary[]' "$OBJ_File/extraMethodsStatements.json" | while IFS= read -r lib; do
		echo "Processing library: $lib"
		if [[ ! -f "$DIST_DIR/$lib" ]]; then
			wget -q -O "$DIST_DIR/$lib" "$OBJ_GIT_POINTER/src/$lib"
		else
			echo "$lib already exists in $DIST_DIR, skipping."
		fi

		# add comment in library
		editor=$(jq -r '.creatorParam.editor' "$OBJ_File/extraMethodsStatements.json")
		version=$(jq -r '.creatorParam.version' "$OBJ_File/extraMethodsStatements.json")
		source=$(jq -r '.creatorParam.source' "$OBJ_File/extraMethodsStatements.json")
		id=$(jq -r '.creatorParam.id' "$OBJ_File/extraMethodsStatements.json")
		result="Editor${editor}_Version${version}_Source${source}_ID${id}"
		echo "// for $result" >> "$DIST_DIR/$lib"

		done
		if [ -s "$OBJ_File/extraMethodsStatements.txt" ]; then
			while IFS=' ' read -r OBJECT_STATEMENTS TYPE_STATEMENT 
			do
			  	# Skip empty line
				[[ -z "$OBJECT_STATEMENTS" ]] && continue
		  		# Skip comment lines starting with // or #
				[[ "$OBJECT_STATEMENTS" == '//'** ]] && continue

			  	echo "testing on Object =$OBJECT_STATEMENTS, Type =$TYPE_STATEMENT"

			  # Skip comment lines (// at the start)

				# continue if not one of the three types
				[[ "$TYPE_STATEMENT" != "import" && "$TYPE_STATEMENT" != "export" && "$TYPE_STATEMENT" != "viewer" ]] && continue

				wget -q -O "$OBJ_File/importStatements.js" "$OBJ_GIT_POINTER/src/importStatements.js"
				wget -q -O "$OBJ_File/importMethod.js" "$OBJ_GIT_POINTER/src/importMethod.js"

				if [ ! -s "$OBJ_File/importStatements.js" ]; then
				  echo "ERROR : File $OBJ_File/importStatements.js missing or empty"
				  continue;
				fi
				if [ ! -s "$OBJ_File/importMethod.js" ]; then
				  echo "ERROR : File $OBJ_File/importMethod.js missing or empty"
				  continue;
				fi

				if [ ! -s "$SRC_DIR/$OBJECT_STATEMENTS.js" ]; then
				  echo "ERROR : File $SRC_DIR/$OBJECT_STATEMENTS.txt missing or empty : the target class does not exists"
				  continue;
				fi

				if [ ! -s "$DIST_DIR/$OBJECT_STATEMENTS.js" ]; then
				  cp "$SRC_DIR/$OBJECT_STATEMENTS.js" "$DIST_DIR/$OBJECT_STATEMENTS.js"
				fi
				

				# Build dist/nmrSpectrumObject.js
				echo "Insertions in $DIST_DIR/$OBJECT_STATEMENTS.js"
				cat "$DIST_DIR/$OBJECT_STATEMENTS.js" \
				  | sed '/\/\/ AUTOMATIC IMPORT INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/importStatements.js" \
				  | sed '/\/\/ AUTOMATIC METHOD INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/importMethod.js" \
				  > "$DIST_DIR/tmp.js"
				mv "$DIST_DIR/tmp.js" "$DIST_DIR/$OBJECT_STATEMENTS.js"

			done < "$OBJ_File/extraMethodsStatements.txt"

		else
		  echo "❌ Download of file $OBJ_GIT_POINTER failed (or file is empty) for object : $OBJ"
		fi

	done < "$FILE_IN_SCRATCH"
done
