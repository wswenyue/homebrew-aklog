# Documentation: https://docs.brew.sh/Formula-Cookbook
class Aklog < Formula
  desc "Android & HarmonyOS developer's Swiss Army Knife for Log"
  homepage "https://github.com/wswenyue/aklog"
  version "5.3.51"

  # Use system python3 when available; otherwise install via Homebrew.
  depends_on "python" if which("python3").nil? && which("python").nil?

  on_macos do
    on_arm do
      url "https://github.com/wswenyue/aklog/releases/download/v5.3.51/aklog-5.3.51-darwin-arm64.tar.gz"
      sha256 "f9472c0e846a1f8eb7a9a3251409921df7fe1c638f512cbf67061a63ce546c2c"
    end
    on_intel do
      url "https://github.com/wswenyue/aklog/archive/v5.3.51.tar.gz"
      sha256 "aee8e5d57e77cb0a98ea3fa85f874d703c01f7ae384c449443d1938625935baf"
    end
  end

  def selected_python
    which("python3") || which("python") || Formula["python"].opt_bin/"python3"
  end

  def install
    # Install completions from buildpath before libexec.install moves the tree.
    install_bash_completion
    install_zsh_completion
    libexec.install Dir["*"]
    inreplace libexec/"aklog", /^AKLOG_PYTHON=__AKLOG_PYTHON__$/,
                "AKLOG_PYTHON=#{selected_python}"
    bin.install_symlink libexec/"aklog"
    system selected_python, "-m", "pip", "install", "rich", "tomli", "argcomplete", "tomlkit", "questionary", "readchar"
  end

  def install_bash_completion
    if (buildpath/"contrib/bash/aklog").exist?
      bash_completion.install "contrib/bash/aklog"
    else
      (bash_completion/"aklog").write <<~EOS
        # bash completion for aklog
        if type register-python-argcomplete &>/dev/null; then
          eval "$(register-python-argcomplete aklog)"
        fi
      EOS
    end
  end

  def install_zsh_completion
    if (buildpath/"contrib/zsh/_aklog").exist?
      zsh_completion.install "contrib/zsh/_aklog"
    else
      (zsh_completion/"_aklog").write <<~EOS
        #compdef aklog
        if (( $+commands[register-python-argcomplete] )); then
          eval "$(register-python-argcomplete aklog)"
        fi
      EOS
    end
  end

  def post_install
    return unless OS.mac?

    lib_root = libexec/"lib"
    system "/usr/bin/xattr", "-dr", "com.apple.quarantine", lib_root if lib_root.exist?

    # Sign dylibs first; install_name changes invalidate upstream signatures.
    Dir.glob("#{libexec}/lib/**/*.dylib").each do |dylib|
      chmod 0664, dylib
      MachO::Tools.change_dylib_id(dylib, "@rpath/#{File.basename(dylib)}")
      MachO.codesign!(dylib)
      chmod 0444, dylib
    end

    # hdc loads libusb_shared.dylib; adb/hdc must be ad-hoc signed to run on macOS.
    %w[adb hdc].each do |name|
      Dir.glob("#{libexec}/lib/**/#{name}").each do |executable|
        next unless File.file?(executable)

        MachO.codesign!(executable)
      end
    end
  end

  test do
    system bin/"aklog", "--version"
  end

end
