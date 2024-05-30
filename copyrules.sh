#!/bin/bash

BASHPATH=/opt/scripts/copyrules

# Hari ini
today=$(date +%Y-%m-%d)

# Clear the screen
clear

# Prompt the user to input their email address
dialog --title "Input Source Email Address" --inputbox "Please enter source email address:" 8 60 2> temp_email.txt
email=$(cat temp_email.txt)

# Prompt the user to input the destination email address
dialog --title "Input Destination Email Address" --inputbox "Please enter destination email address:" 8 60 2> temp_tujuan.txt
tujuan=$(cat temp_tujuan.txt)

# Display processing message
dialog --title "Processing" --infobox "Processing, please wait..." 5 50

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
    # Display folder creation message
    dialog --title "Creating Folder" --infobox "Creating Folder: $folder" 5 50
    su - zimbra -c "zmmailbox -z -m $tujuan cf -V message \"/$folder\""
done < "$BASHPATH/exported/${email}-folder-unique.txt"

# Update the sieve script for the destination email
su - zimbra -c "zmprov ma $tujuan zimbraMailSieveScript \"\$(cat $BASHPATH/exported/$email.txt)\""

# Display completion message
dialog --title "Done" --msgbox "Process completed successfully!" 8 50

# Clean up temporary files
rm temp_email.txt temp_tujuan.txt

#cleanup exported dir
EXPORTED_DIR="$BASHPATH/exported"
rm -rf "$EXPORTED_DIR"/*
