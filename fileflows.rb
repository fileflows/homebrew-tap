require "download_strategy"

class NoChecksumDownloadStrategy < CurlDownloadStrategy
  def verify_download_integrity(_fn)
    # skip checksum validation
  end
end

class Fileflows < Formula
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
      exec /opt/homebrew/opt/dotnet@8/bin/dotnet FileFlows.Server.dll --no-gui --launchd-service --base-dir "$HOME/Library/Application Support/FileFlows"
    EOS
    chmod 0755, libexec/"fileflows-server-launchd-entrypoint.sh"

    (bin/"fileflows").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/fileflows-launchd-entrypoint.sh" "$@"
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
