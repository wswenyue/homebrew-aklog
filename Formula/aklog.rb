# Documentation: https://docs.brew.sh/Formula-Cookbook
class Aklog < Formula
  desc "Android & HarmonyOS developer's Swiss Army Knife for Log"
  homepage "https://github.com/wswenyue/aklog"
  version "5.3.36"

  # Use system python3 when available; otherwise install via Homebrew.
  depends_on "python" if which("python3").nil? && which("python").nil?

  on_macos do
    on_arm do
      url "https://github.com/wswenyue/aklog/releases/download/v5.3.36/aklog-5.3.36-darwin-arm64.tar.gz"
      sha256 "4fa0b819ffd56147c43d414c144978117f2e8fb8e6ebc09da8fe69142e916b3f"
    end
    on_intel do
      url "https://github.com/wswenyue/aklog/archive/v5.3.36.tar.gz"
      sha256 "f9c6710576a64ba22eeada009df66b48b33338591ab3c0c531d528b5110f0dbf"
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
