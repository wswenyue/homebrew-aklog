# Documentation: https://docs.brew.sh/Formula-Cookbook
class Aklog < Formula
  desc "Android & HarmonyOS developer's Swiss Army Knife for Log"
  homepage "https://github.com/wswenyue/aklog"
  version "5.3.28"

  depends_on "python@3.12"

  on_macos do
    on_arm do
      url "https://github.com/wswenyue/aklog/releases/download/v5.3.28/aklog-5.3.28-darwin-arm64.tar.gz"
      sha256 "10b680b52514a2ffbc2373998e3549275f49a2463ee34978651f55f81fefa0ab"
    end
    on_intel do
      url "https://github.com/wswenyue/aklog/archive/v5.3.28.tar.gz"
      sha256 "860136d6ca9a80f659174f6b6e7116adb338ea686c27d7845b7b5944c10c012a"
    end
  end

  def install
    libexec.install Dir["*"]
    bin.install libexec/"aklog" => "aklog"
    inreplace bin/"aklog", "exe_path", libexec.to_s
    python = Formula["python@3.12"].opt_bin/"python3.12"
    inreplace bin/"aklog", "python3 -m aklog", "#{python} -m aklog"
    inreplace bin/"aklog", "python -m aklog", "#{python} -m aklog"
  end

  def post_install
    Dir.glob("#{libexec}/lib/**/*.dylib").each do |dylib|
      chmod 0664, dylib
      MachO::Tools.change_dylib_id(dylib, "@rpath/#{File.basename(dylib)}")
      MachO.codesign!(dylib) if Hardware::CPU.arm?
      chmod 0444, dylib
    end
  end

  test do
    system bin/"aklog", "--version"
  end

end
