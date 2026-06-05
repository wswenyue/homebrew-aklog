# Documentation: https://docs.brew.sh/Formula-Cookbook
class Aklog < Formula
  desc "Android & HarmonyOS developer's Swiss Army Knife for Log"
  homepage "https://github.com/wswenyue/aklog"
  version "5.3.29"

  depends_on "python"

  on_macos do
    on_arm do
      url "https://github.com/wswenyue/aklog/releases/download/v5.3.29/aklog-5.3.29-darwin-arm64.tar.gz"
      sha256 "a49d9636a9bb19d837d371520410e3956239f37a26200549699764ab6376e61c"
    end
    on_intel do
      url "https://github.com/wswenyue/aklog/archive/v5.3.29.tar.gz"
      sha256 "72449ba9c4e018d6520c2c50acf34cf821b1c9d9d57ef26223d2e690aabe63d0"
    end
  end

  def install
    libexec.install Dir["*"]
    bin.install libexec/"aklog" => "aklog"
    inreplace bin/"aklog", "exe_path", libexec.to_s
    python = Formula["python"].opt_bin/"python3"
    inreplace bin/"aklog", "python3 -m aklog", "#{python} -m aklog"
    inreplace bin/"aklog", "python -m aklog", "#{python} -m aklog"
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
