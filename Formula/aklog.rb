# Documentation: https://docs.brew.sh/Formula-Cookbook
class Aklog < Formula
  desc "Android & HarmonyOS developer's Swiss Army Knife for Log"
  homepage "https://github.com/wswenyue/aklog"
  version "5.3.40"

  # Use system python3 when available; otherwise install via Homebrew.
  depends_on "python" if which("python3").nil? && which("python").nil?

  on_macos do
    on_arm do
      url "https://github.com/wswenyue/aklog/releases/download/v5.3.40/aklog-5.3.40-darwin-arm64.tar.gz"
      sha256 "79d2c933f43db440d466c11cc9c10615afbefa21d8cce58fd81d07bc0aa2ee01"
    end
    on_intel do
      url "https://github.com/wswenyue/aklog/archive/v5.3.40.tar.gz"
      sha256 "3a21438b030da60b38aa6f81c4a232f828b114dda278dd071ae0ef3a477f4524"
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
    system selected_python, "-m", "pip", "install", "rich", "tomli"
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
