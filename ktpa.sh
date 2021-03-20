#!/bin/bash

while IFS= read -r line; do
   mv "$line" Public/
done < ktpa.txt
