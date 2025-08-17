#!/usr/bin/env zsh

# Define source paths
SRC_DIR="src"
DIST_DIR="dist"

# Ensures dist exists
mkdir -p "$DIST_DIR"

# Here will loop OBJ over different import
OBJ="MnovaJson-reader"
OBJ_DIR="/Users/djeanner/git/$OBJ/src"

mkdir -p "$SRC_DIR/$OBJ"

# Copy input files into src
cp "$OBJ_DIR/importStatements.js" "$SRC_DIR/$OBJ"
cp "$OBJ_DIR/importMethod.js" "$SRC_DIR/$OBJ"

# Build dist/nmrSpectrumObject.js
echo "create $DIST_DIR/nmrSpectrumObject.js"
cat "$SRC_DIR/nmrSpectrumObject.js" \
  | sed '/\/\/ AUTOMATIC IMPORT INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/importStatements.js" \
  | sed '/\/\/ AUTOMATIC METHOD INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/importMethod.js" \
  > "$DIST_DIR/nmrSpectrumObject.js"

# Build dist/jGraphObject.js
echo "create $DIST_DIR/jGraphObject.js"
cat "$SRC_DIR/jGraphObject.js" \
  | sed '/\/\/ AUTOMATIC IMPORT INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/importStatements.js" \
  | sed '/\/\/ AUTOMATIC METHOD INSERTION WILL BE MADE HERE/r '"$SRC_DIR/$OBJ/importMethod.js" \
  > "$DIST_DIR/jGraphObject.js"
