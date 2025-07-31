require "download_strategy"

class NoChecksumDownloadStrategy < CurlDownloadStrategy
  def verify_download_integrity(_fn)
    # skip checksum validation
  end
end

class Fileflows < Formula
  desc "FileFlows - Automated file processing"
  homepage "https://fileflows.com"
  url "https://fileflows.com/downloads/ff-latest.zip?t=#{Time.now.to_i}", using: NoChecksumDownloadStrategy
  version "latest"

  depends_on "dotnet@8"

  def install
    libexec.install Dir["*"]

    rm_rf libexec/"Node"
    # Remove all .bat and .sh files in the root of libexec
    Dir[libexec/"*.bat"].each { |f| rm_f f }
    Dir[libexec/"*.sh"].each { |f| rm_f f }

    bin.mkpath

    (libexec/"fileflows-entrypoint.sh").write <<~EOS
      #!/bin/bash

      # Determine base data directory based on OS
      if [[ "$(uname)" == "Darwin" ]]; then
        echo "Saving MacOS Configuration"
        BASE_DIR="$HOME/Library/Application Support/FileFlows"
      else
        echo "Saving Linux Configuration"
        BASE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/FileFlows"
      fi

      cd "#{libexec}"
      if [ -f "#{libexec}/Update/server-upgrade.sh" ]; then
        chmod +x "#{libexec}/Update/server-upgrade.sh"
        cd "#{libexec}/Update"
        bash "server-upgrade.sh" brew
      fi
      cd "#{libexec}/Server"

      if [[ "$(uname)" == "Darwin" ]]; then
        DOTNET_PATH="/opt/homebrew/opt/dotnet@8/bin/dotnet"
      else
        DOTNET_PATH="/home/linuxbrew/.linuxbrew/opt/dotnet@8/bin/dotnet"
      fi

      exec "$DOTNET_PATH" FileFlows.Server.dll --no-gui --brew --base-dir "$BASE_DIR"
    EOS
    chmod 0755, libexec/"fileflows-entrypoint.sh"

    (bin/"fileflows").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/fileflows-entrypoint.sh" "$@"
    EOS
    chmod 0755, bin/"fileflows"

  end

  service do
    run ["/bin/bash", opt_bin/"fileflows"]
    keep_alive true
  end

  test do
    assert_predicate libexec/"Server/FileFlows.Server.dll", :exist?
  end
end
