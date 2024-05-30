#!/bin/bash

BASHPATH=/opt/scripts/copyrules

# Hari ini
today=$(date +%Y-%m-%d)

clear

echo "Masukan Alamat Email"
read email

echo "Masukan Alamat Email Tujuan"
read tujuan

echo "Processing..."

#export rules
su - zimbra -c "zmprov -l ga $email zimbraMailSieveScript" > "$BASHPATH/exported/$email.txt"

#proses exported rules
sed -i -e "1d" "$BASHPATH/exported/$email.txt"
sed -i -e 's/zimbraMailSieveScript: //g' "$BASHPATH/exported/$email.txt"

#extract folder name
grep 'fileinto ' "$BASHPATH/exported/$email.txt" > "$BASHPATH/exported/${email}-folder.txt"

#proses folder pada email tujuan
# Remove the word 'fileinto'
sed -i 's/fileinto//g' "$BASHPATH/exported/${email}-folder.txt"

# Remove trailing semicolons
sed -i 's/;$//' "$BASHPATH/exported/${email}-folder.txt"

# Remove leading spaces
sed -i 's/^ *//' "$BASHPATH/exported/${email}-folder.txt"

# Remove double quotes
sed -i 's/"//g' "$BASHPATH/exported/${email}-folder.txt"

# Normalize folder names (remove leading slashes) and remove duplicates
sed -i 's|^/||' "$BASHPATH/exported/${email}-folder.txt"
sort "$BASHPATH/exported/${email}-folder.txt" | uniq > "$BASHPATH/exported/${email}-folder-unique.txt"

#loop create email folder pada email tujuan
while IFS= read -r folder; do
    echo "Creating Folder: $folder"
    su - zimbra -c "zmmailbox -z -m $tujuan cf -V message \"/$folder\""
done < "$BASHPATH/exported/${email}-folder-unique.txt"

# Update the sieve script for the destination email
su - zimbra -c "zmprov ma $tujuan zimbraMailSieveScript \"\$(cat $BASHPATH/exported/$email.txt)\""

echo "Done"
