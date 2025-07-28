require "download_strategy"

class NoChecksumDownloadStrategy < CurlDownloadStrategy
  def verify_download_integrity(_fn)
    # skip checksum validation
  end
end

class FileflowsNode < Formula
  desc "FileFlows Node - Worker agent for FileFlows Server"
  homepage "https://fileflows.com"
  url "https://fileflows.com/downloads/ff-latest.zip", using: NoChecksumDownloadStrategy
  version "latest"

  depends_on "dotnet@8"

  def install
    libexec.install Dir["*"]

    rm_rf libexec/"Server"
    # Remove all .bat and .sh files in the root of libexec
    Dir[libexec/"*.bat"].each { |f| rm_f f }
    Dir[libexec/"*.sh"].each { |f| rm_f f }

    bin.mkpath

    (libexec/"fileflows-node-launchd-entrypoint.sh").write <<~EOS
      #!/bin/bash

      CONFIG_FILE="$HOME/Library/Application Support/FileFlowsNode/Data/node.config"

      if [[ "$1" == "--configure" ]]; then
        echo "Configuring FileFlows Node..."
        read -p "Server URL: " server_url
        read -p "Access Token (optional): " access_token
        hostname=$(hostname)

        mkdir -p "#{libexec}/Data"

        cat > "$CONFIG_FILE" <<EOF
{
  "ServerUrl": "$server_url",
  "AccessToken": "$access_token",
  "HostName": "$hostname"
}
EOF

        echo "Configuration saved to $CONFIG_FILE"
        exit 0
      fi

      cd "#{libexec}"
      if [ -f "#{libexec}/NodeUpdate/node-upgrade.sh" ]; then
        chmod +x "#{libexec}/NodeUpdate/node-upgrade.sh"
        cd "#{libexec}/NodeUpdate"
        bash "node-upgrade.sh" launchd
      fi
      cd "#{libexec}/Node"
      exec dotnet FileFlows.Node.dll --no-gui --launchd-service --base-dir "$HOME/Library/Application Support/FileFlowsNode"

    EOS
    chmod 0755, libexec/"fileflows-node-launchd-entrypoint.sh"

    (bin/"fileflows-node").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/fileflows-node-launchd-entrypoint.sh" "$@"
    EOS
    chmod 0755, bin/"fileflows-node"

  end

  service do
    run ["/bin/bash", opt_bin/"fileflows-node"]
    keep_alive true
  end

  test do
    assert_predicate libexec/"Node/FileFlows.Node.dll", :exist?
  end
end
