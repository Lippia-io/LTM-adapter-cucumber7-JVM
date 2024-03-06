#!/bin/sh
#
# Variables to ensure that we read and write out files to the source directory even if we execute from outside.
#
DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_FILE=$DIR/settings.template.xml
DEST_FILE_NAME=settings.xml
DESTINATION_FILE=$DIR/$DEST_FILE_NAME
GITIGNORE=$DIR/.gitignore

# Install necessary packages
apt-get update
apt-get install -y gnupg maven

echo "Checking for presence of NEXUS_USERNAME environment variable...."
if [ $NEXUS_USERNAME ];
then
  echo "Success - Found Nexus Username in environment variables...";
else
  >&2 echo "Failure - NEXUS_USERNAME environment variable not set.  Please set this environment variable and try again."
  exit 1
fi;

echo "Checking for presence of NEXUS_PASSPHRASE environment variable...."
if [ $NEXUS_PASSPHRASE ];
then
  echo "Success - Found Nexus Passphrase in environment variables...";
else
  >&2 echo "Failure - NEXUS_PASSPHRASE environment variable not set.  Please set this environment variable and try again."
  exit 2
fi;

echo "Environment Variables Set, Creating $DESTINATION_FILE file..."

if [ -f $TEMPLATE_FILE ]; then
   if cat $TEMPLATE_FILE | sed  "s/%NEXUS_USERNAME%/$NEXUS_USERNAME/g"  | sed "s/%NEXUS_PASSPHRASE%/$NEXUS_PASSPHRASE/g" | sed "s/generation text/ATTENTION: This file was generated by the create-settings.sh script.  Do not commit it to version control as it contains credentials!/" > $DESTINATION_FILE; then

      #
      # Let's warn users if they don't have the generated settings.xml file in their .gitignore file.
      #
      # If you don't put the settings.xml file in .gitignore, the maven release plugin will fail during the `mvn release:prepare` step.
      #
      if grep -q "^$DEST_FILE_NAME$" $GITIGNORE; then
         echo "Success - $DEST_FILE_NAME found in $GITIGNORE file.  This will prevent git from saving the credentials in version control."
         else
         echo "Warning - $DEST_FILE_NAME not found in $GITIGNORE file.  Add $DEST_FILE_NAME to $GITIGNORE to ensure you don't accidently commit your credentials!"
      fi

      #
      # Success, we're done here.
      #
      echo "Success - $DESTINATION_FILE file successfully created.  Make sure you do not commit this file to source control."
      exit 0;
   else
      >&2 echo "Failure - There was an error creating the $DESTINATION_FILE";
      exit 3;

   fi;
else
   >&2 echo "Failure - $TEMPLATE_FILE does not exist";
   exit 4;
fi;
