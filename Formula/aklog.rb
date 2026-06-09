# Documentation: https://docs.brew.sh/Formula-Cookbook
class Aklog < Formula
  desc "Android & HarmonyOS developer's Swiss Army Knife for Log"
  homepage "https://github.com/wswenyue/aklog"
  version "5.3.42"

  # Use system python3 when available; otherwise install via Homebrew.
  depends_on "python" if which("python3").nil? && which("python").nil?

  on_macos do
    on_arm do
      url "https://github.com/wswenyue/aklog/releases/download/v5.3.42/aklog-5.3.42-darwin-arm64.tar.gz"
      sha256 "45ebe3ebd257e7d36287cc83b84271ac0f3b4872999e1173ed0d8175d55267f6"
    end
    on_intel do
      url "https://github.com/wswenyue/aklog/archive/v5.3.42.tar.gz"
      sha256 "e6054254428961aaf554c3fbdba2933ad21d561117994651e5fcd4588cdc7133"
    end
  end

  def selected_python
    which("python3") || which("python") || Formula["python"].opt_bin/"python3"
  end

  def install
    libexec.install Dir["*"]
    inreplace libexec/"aklog", /^AKLOG_PYTHON=__AKLOG_PYTHON__$/,
                "AKLOG_PYTHON=#{selected_python}"
    bin.install_symlink libexec/"aklog"
    system selected_python, "-m", "pip", "install", "rich", "tomli", "argcomplete"
    install_bash_completion
    install_zsh_completion
  end

  def install_bash_completion
    if (libexec/"contrib/bash/aklog").exist?
      bash_completion.install libexec/"contrib/bash/aklog"
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
    if (libexec/"contrib/zsh/_aklog").exist?
      zsh_completion.install libexec/"contrib/zsh/_aklog"
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
