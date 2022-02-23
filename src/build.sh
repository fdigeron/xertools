#!/bin/bash

echo "building xerdiff (linux)..."
v -prod xerdiff.v -o ../bin/linux/xerdiff

echo "building xerdump (linux)..."
v -prod xerdump.v -o ../bin/linux/xerdump

echo "building xertask (linux)..."
v -prod xertask.v -o ../bin/linux/xertask

echo "building xerpred (linux)..."
v -prod xerpred.v -o ../bin/linux/xerpred

echo "building xerdiff (windows)..."
v -prod xerdiff.v -os windows -o ../bin/windows/xerdiff

echo "building xerdump (windows)..."
v -prod xerdump.v -os windows -o ../bin/windows/xerdump

echo "building xertask (windows)..."
v -prod xertask.v -os windows -o ../bin/windows/xertask

echo "building xerpred (windows)..."
v -prod xerpred.v -os windows -o ../bin/windows/xerpred