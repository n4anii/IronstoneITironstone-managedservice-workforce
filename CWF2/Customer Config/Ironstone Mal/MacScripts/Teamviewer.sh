#!/bin/bash

# Variables
weburl="https://istpnweityesa.blob.core.windows.net/applications/TeamViewer_Host-idc6mqnzwa.pkg"
pkg_name="TeamViewer_Host-idc6mqnzwa.pkg"
pkg_path="/tmp/$pkg_name"
log_dir="/Library/Logs/TeamViewerHost"
log_file="$log_dir/install.log"
host_app_path="/Applications/TeamViewer.app"
full_app_path="/Applications/TeamViewer Full.app"
config_id="6mqnzwa" # Your TeamViewer Configuration ID
config_file="/Library/Preferences/com.teamviewer.teamviewerhost.plist"
xml_url="https://istpnweityesa.blob.core.windows.net/applications/config.xml"
xml_path="/tmp/config.xml"

# Create log directory
if [ ! -d "$log_dir" ]; then
    mkdir -p "$log_dir"
    echo "$(date) - Created log directory at $log_dir" >> "$log_file"
fi

# Log function
log() {
    echo "$(date) - $1" >> "$log_file"
}

# Start logging
log "Starting TeamViewer Host installation script."

# Check for TeamViewer Full version
if [ -d "$full_app_path" ]; then
    log "TeamViewer Full version is already installed at $full_app_path. Skipping installation of TeamViewer Host."
    exit 0
fi

# Download TeamViewer Host package
log "Downloading TeamViewer Host package from $weburl."
curl -L -o "$pkg_path" "$weburl" >> "$log_file" 2>&1
if [ $? -ne 0 ]; then
    log "Warning: Failed to download the package from $weburl. Continuing."
else
    log "Package downloaded successfully to $pkg_path. Size: $(stat -f%z "$pkg_path") bytes."
fi

# Verify the package
log "Checking validity of the .pkg file."
pkgutil --check-signature "$pkg_path" >> "$log_file" 2>&1
if [ $? -ne 0 ]; then
    log "Warning: Package signature validation failed. Proceeding with installation."
fi

# Install the package silently
log "Installing TeamViewer Host package silently."
installer -pkg "$pkg_path" -target / >> "$log_file" 2>&1
if [ $? -ne 0 ]; then
    log "Warning: Installation encountered issues. Check the log for details."
fi

# Verify installation
if [ -d "$host_app_path" ]; then
    log "TeamViewer Host installed successfully at $host_app_path."
else
    log "Warning: TeamViewer Host installation failed. Manual intervention may be needed."
fi

# Apply Configuration ID
log "Applying Configuration ID $config_id to TeamViewer Host."
defaults write "$config_file" CustomConfigID -string "$config_id" >> "$log_file" 2>&1
if [ $? -ne 0 ]; then
    log "Warning: Failed to apply Configuration ID $config_id."
else
    log "Configuration ID $config_id successfully applied to $config_file."
fi

# Download and apply XML configuration
log "Downloading XML configuration file from $xml_url."
curl -L -o "$xml_path" "$xml_url" >> "$log_file" 2>&1
if [ $? -ne 0 ]; then
    log "Warning: Failed to download XML configuration file from $xml_url."
else
    log "XML configuration file downloaded successfully to $xml_path."
    log "Applying XML configuration file to TeamViewer."
    installer -showChoicesAfterApplyingChangesXML "$xml_path" -pkg "$pkg_path" -target / >> "$log_file" 2>&1
    if [ $? -ne 0 ]; then
        log "Warning: Failed to apply XML configuration file. Check the log for details."
    else
        log "XML configuration file applied successfully."
    fi
fi

# Disable screen recording permissions for TeamViewer
log "Disabling screen recording permissions for TeamViewer."
teamviewer_bundle_id="com.teamviewer.TeamViewerHost"
tcc_db="/Library/Application Support/com.apple.TCC/TCC.db"
sqlite3 "$tcc_db" "DELETE FROM access WHERE client='$teamviewer_bundle_id' AND service='kTCCServiceScreenCapture';" >> "$log_file" 2>&1
if [ $? -eq 0 ]; then
    log "Screen recording permissions successfully disabled for TeamViewer."
else
    log "Warning: Failed to disable screen recording permissions. Manual review may be needed."
fi

# Clean up
log "Cleaning up temporary files."
rm -f "$pkg_path"
rm -f "$xml_path"

# Final log
log "TeamViewer Host installation script completed successfully."
exit 0
