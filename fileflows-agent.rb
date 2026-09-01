require "download_strategy"

class NoChecksumDownloadStrategy < CurlDownloadStrategy
  def verify_download_integrity(_fn)
    # skip checksum validation
  end
end

class FileflowsAgent < Formula
  TIMESTAMP = (Time.now.to_i / 600) * 600

  desc "FileFlows Agent - Worker agent for FileFlows Server"
  homepage "https://fileflows.com"
  url "https://fileflows.com/downloads/ff-latest.tar.xz?t=#{TIMESTAMP}", using: NoChecksumDownloadStrategy  
  version "latest"

  depends_on "dotnet@10"

  def install
    libexec.install Dir["*"]

    rm_rf libexec/"Server"
    # Remove all .bat and .sh files in the root of libexec
    Dir[libexec/"*.bat"].each { |f| rm_f f }
    Dir[libexec/"*.sh"].each { |f| rm_f f }

    bin.mkpath

    (libexec/"fileflows-agent-entrypoint.sh").write <<~EOS
      #!/bin/bash

      # Determine base data directory based on OS
      if [[ "$(uname)" == "Darwin" ]]; then
        echo "Saving MacOS Configuration"
        BASE_DIR="$HOME/Library/Application Support/FileFlowsAgent"
      else
        echo "Saving Linux Configuration"
        BASE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/FileFlowsAgent"
      fi

      CONFIG_FILE="$BASE_DIR/Data/agent.config"

      if [[ "$1" == "--configure" ]]; then
        echo "Configuring FileFlows Agent..."
        read -p "Server URL: " server_url
        read -p "Access Token (optional): " access_token
        hostname=$(hostname)

        mkdir -p "$BASE_DIR/Data"

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
      if [ -f "#{libexec}/AgentUpdate/agent-upgrade.sh" ]; then
        chmod +x "#{libexec}/AgentUpdate/agent-upgrade.sh"
        cd "#{libexec}/AgentUpdate"
        bash "agent-upgrade.sh" brew
      fi
      cd "#{libexec}/Agent"

      if [[ "$(uname)" == "Darwin" ]]; then
        DOTNET_PATH="/opt/homebrew/opt/dotnet@10/bin/dotnet"
      else
        DOTNET_PATH="/home/linuxbrew/.linuxbrew/opt/dotnet@10/bin/dotnet"
      fi

      exec "$DOTNET_PATH" FileFlows.Agent.dll --no-gui --brew --base-dir "$BASE_DIR"

    EOS
    chmod 0755, libexec/"fileflows-agent-entrypoint.sh"

    (bin/"fileflows-agent").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/fileflows-agent-entrypoint.sh" "$@"
    EOS
    chmod 0755, bin/"fileflows-agent"
  end

  service do
    run ["/bin/bash", opt_bin/"fileflows-agent"]
    keep_alive true
  end

  test do
    assert_predicate libexec/"Agent/FileFlows.Agent.dll", :exist?
  end
end
