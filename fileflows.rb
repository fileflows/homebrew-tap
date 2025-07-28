require "download_strategy"

class NoChecksumDownloadStrategy < CurlDownloadStrategy
  def verify_download_integrity(_fn)
    # skip checksum validation
  end
end

class FileFlows < Formula
  desc "FileFlows - Automated file processing"
  homepage "https://fileflows.com"
  url "https://fileflows.com/downloads/ff-latest.zip", using: NoChecksumDownloadStrategy
  version "latest"

  depends_on "dotnet@8"

  def install
    libexec.install Dir["*"]

    rm_rf libexec/"Node"
    # Remove all .bat and .sh files in the root of libexec
    Dir[libexec/"*.bat"].each { |f| rm_f f }
    Dir[libexec/"*.sh"].each { |f| rm_f f }

    bin.mkpath

    (libexec/"fileflows-server-launchd-entrypoint.sh").write <<~EOS
      #!/bin/bash

      cd "#{libexec}"
      if [ -f "#{libexec}/Update/server-upgrade.sh" ]; then
        chmod +x "#{libexec}/Update/server-upgrade.sh"
        cd "#{libexec}/Update"
        bash "server-upgrade.sh" launchd
      fi
      cd "#{libexec}/Server"
      exec dotnet FileFlows.Server.dll --no-gui --launchd-service --base-dir "$HOME/Library/Application Support/FileFlows"
    EOS
    chmod 0755, libexec/"fileflows-server-launchd-entrypoint.sh"

    (bin/"fileflows").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/fileflows-launchd-entrypoint.sh" "$@"
    EOS
    chmod 0755, bin/"fileflows"

  end

  service do
    run [opt_bin/"fileflows"]
    keep_alive true
    log_path "/usr/local/var/log/fileflows.log"
    error_log_path "/usr/local/var/log/fileflows.log"
    # No require_root here, so it runs as your user
  end

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
       "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.fileflows</string>
        <key>ProgramArguments</key>
        <array>
          <string>/bin/bash</string>
          <string>#{opt_bin}/fileflows</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/usr/local/var/log/fileflows.log</string>
        <key>StandardErrorPath</key>
        <string>/usr/local/var/log/fileflows.log</string>
      </dict>
      </plist>
    EOS
  end

  test do
    assert_predicate libexec/"Server/FileFlows.Server.dll", :exist?
  end
end
