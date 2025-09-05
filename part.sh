start=$(date +%s%3N)
# ... some operation ...
end=$(date +%s%3N)
offset=$((end - start))
echo "Time offset: ${offset} ms"
