#!/bin/bash

echo "building xerdiff (linux)..."
DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xerdiff.v -o ../xerdiff

echo "building xerdump (linux)..."
DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xerdump.v -o ../xerdump

echo "building xertask (linux)..."
DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xertask.v -o ../xertask

echo "building xerpred (linux)..."
DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xerpred.v -o ../xerpred

echo "building xer2json (linux)..."
DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xer2json.v -o ../xer2json

echo "building sqlrunner (linux)..."
DATE=$(date +%Y-%m-%d) v -prod -d prebuilt sqlrunner.v -o ../sqlrunner

#echo "building xerdiff (windows)..."
#DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xerdiff.v -os windows -o ../xerdiff

#echo "building xerdump (windows)..."
#DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xerdump.v -os windows -o ../xerdump

#echo "building xertask (windows)..."
#DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xertask.v -os windows -o ../xertask

#echo "building xerpred (windows)..."
#DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xerpred.v -os windows -o ../xerpred

#echo "building xer2json (windows)..."
#DATE=$(date +%Y-%m-%d) v -prod -d prebuilt xer2json.v -os windows -o ../xer2json
